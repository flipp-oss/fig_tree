# frozen_string_literal: true

require 'fig_tree/version'

# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/callbacks'

# Configuration module.
module FigTree
  extend ActiveSupport::Concern

  ConfigValue = Struct.new(:value, :default_value, :default_proc, :deprecation) do

    # Reset value back to default.
    def reset!
      if self.value.is_a?(ConfigStruct)
        self.value.reset!
      else
        self.value = self.default_value
      end
    end

    # :nodoc:
    def clone_and_reset
      setting = ConfigValue.new(self.value, self.default_value,
                                self.default_proc, self.deprecation)
      setting.reset!
      setting
    end

  end

  # Class that defines and keeps the configuration values.
  class ConfigStruct
    include ActiveSupport::Callbacks

    define_callbacks :configure

    # @param name [String]
    def initialize(name)
      @name = name
      @settings = {}
      @setting_objects = {}
      @setting_templates = {}
    end

    # Reset config back to default values.
    def reset!
      @setting_objects = @setting_templates.map { |k, _| [k, []] }.to_h
      @settings.values.each(&:reset!)
    end

    # Mark a configuration as deprecated and replaced with the new config.
    # @param old_config [String]
    # @param new_config [String]
    def deprecate(old_config, new_config)
      @settings[old_config.to_sym] ||= ConfigValue.new
      @settings[old_config.to_sym].deprecation = new_config
    end

    # :nodoc:
    def inspect
      "#{@name}: #{@settings.inspect} #{@setting_objects.inspect}"
    end

    # @return [Hash]
    def to_h
      @settings.map { |k, v| [k, v.value] }.to_h
    end

    # :nodoc:
    def clone_and_reset
      new_config = self.clone
      new_config.setting_objects = new_config.setting_objects.clone
      new_config.settings = new_config.settings.map { |k, v| [k, v.clone_and_reset] }.to_h
      new_config
    end

    # Define a setting template for an array of objects via a block:
    #   setting_object :producer do
    #     setting :topic
    #     setting :class_name
    #   end
    # This will create the `producer` method to define these values as well
    # as the `producer_objects` method to retrieve them.
    # @param name [Symbol]
    def setting_object(name, &block)
      new_config = ConfigStruct.new("#{@name}.#{name}")
      @setting_objects[name] = []
      @setting_templates[name] = new_config
      new_config.instance_eval(&block)
    end

    # Define a setting with the given name.
    # @param name [Symbol]
    # @param default_value [Object]
    # @param default_proc [Proc]
    def setting(name, default_value=nil, default_proc: nil, &block)
      if block_given?
        # Create a nested setting
        setting_config = @settings[name]&.value || ConfigStruct.new("#{@name}.#{name}")
        setting = ConfigValue.new
        setting.value = setting_config
        @settings[name] = setting
        setting_config.instance_eval(&block)
      else
        setting = ConfigValue.new
        setting.default_proc = default_proc
        setting.default_value = default_value
        setting.reset!
        @settings[name] = setting
      end
    end

    # :nodoc:
    def respond_to_missing?(method, include_all=true)
      method = method.to_s.sub(/=$/, '')
      method.ends_with?('objects') ||
        @setting_templates.key?(method.to_sym) ||
        @settings.key?(method.to_sym) ||
        super
    end

    # :nodoc:
    def method_missing(method, *args, &block)
      config_key = method.to_s.sub(/=$/, '').to_sym

      # Return the list of setting objects with the given name
      if config_key.to_s.end_with?('objects')
        return _setting_object_method(config_key)
      end

      # Define a new setting object with the given name
      if @setting_templates.key?(config_key) && block_given?
        return _new_setting_object_method(config_key, &block)
      end

      setting = @settings[config_key]

      if setting&.deprecation
        return _deprecated_config_method(method, *args)
      end

      return super unless setting

      if block_given?
        return _block_config_method(config_key, &block)
      end

      _default_config_method(config_key, *args)
    end

  protected

    # Only for the clone method
    attr_accessor :settings, :setting_objects

  private

    def _deprecated_config_method(method, *args)
      config_key = method.to_s.sub(/=$/, '').to_sym
      new_config = @settings[config_key].deprecation
      equals = method.to_s.end_with?('=') ? '=' : ''
      warning = "config.#{config_key}#{equals} is deprecated - use config.#{new_config}#{equals}"
      ActiveSupport::Deprecation.warn(warning)
      obj = self
      messages = new_config.split('.')
      messages[0..-2].each do |message|
        obj = obj.send(message)
      end
      if args.length.positive?
        obj.send(messages[-1], args[0])
      else
        obj.send(messages[-1])
      end
    end

    # Get or set a value.
    def _default_config_method(config_key, *args)
      if args.length.positive?
        # Set the value
        @settings[config_key].value = args[0]
      else
        # Get the value
        setting = @settings[config_key]
        if setting.default_proc && setting.value.nil?
          setting.value = setting.default_proc.call
        end
        setting.value
      end
    end

    # Define a new setting object and use the passed block to define values.
    def _new_setting_object_method(config_key, &block)
      new_config = @setting_templates[config_key].clone_and_reset
      new_config.instance_eval(&block)
      @setting_objects[config_key] << new_config
    end

    # Return a setting object.
    def _setting_object_method(config_key)
      key = config_key.to_s.sub(/_objects$/, '').to_sym
      @setting_objects[key]
    end

    # Define new values inside a block.
    def _block_config_method(config_key, &block)
      unless @settings[config_key].value.is_a?(ConfigStruct)
        raise "Block called for #{config_key} but it is not a nested config!"
      end

      @settings[config_key].value.instance_eval(&block)
    end
  end

  # :nodoc:
  module ClassMethods
    # Define and redefine settings.
    def define_settings(&block)
      config.instance_eval(&block)
    end

    # Configure the settings with values.
    def configure(&block)
      config.run_callbacks(:configure) do
        config.instance_eval(&block)
      end
    end

    # @return [ConfigStruct]
    def config
      @config ||= ConfigStruct.new('config')
    end

    # Evaluate a block with the given configuration values. Reset back to the original values
    # when done.
    # @param values [Hash]
    def with_config(values={}, &block) # rubocop:disable Metrics/AbcSize
      set_value = lambda do |k, v|
        obj = self.config
        tokens = k.split('.')
        tokens[0..-2].each do |token|
          obj = obj.send(token)
        end
        obj.send(:"#{tokens.last}=", v)
      end

      get_value = lambda do |k|
        obj = self.config
        tokens = k.split('.')
        tokens.each do |token|
          obj = obj.send(token)
        end
        obj
      end

      old_values = values.keys.map { |k| [k, get_value.call(k)] }.to_h
      values.each { |k, v| set_value.call(k, v) }
      block.call
      old_values.each { |k, v| set_value.call(k, v) }
    end

    # Pass a block to run after configuration is done.
    def after_configure(&block)
      mod = self
      config.class.set_callback(:configure, :after,
                                proc { mod.instance_eval(&block) })
    end
  end
end
