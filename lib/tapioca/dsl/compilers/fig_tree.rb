# typed: true

module Tapioca
  module Compilers
    class FigTree < Tapioca::Dsl::Compiler
      extend T::Sig

      ConstantType = type_member {{ fixed: T.all(T::Class[::FigTree], ::FigTree::ClassMethods) }}

      sig { override.returns(T::Enumerable[Module]) }
      def self.gather_constants
        all_modules.select { |m| m < ::FigTree}
      end

      sig { params(path: String, struct: ::FigTree::ConfigStruct).void }
      def decorate_struct(path, struct)
        class_name = struct.instance_variable_get(:@name)
        constant_name = "Private#{path}#{class_name.tr('.', '_').classify}"
        config_class = Class.new
        Object.const_set(constant_name, config_class)
        root.create_path(config_class) do |klass|
          settings = struct.instance_variable_get(:@settings)
          if settings
            settings.each do |name, value|
              if value.value.is_a?(::FigTree::ConfigStruct)
                decorate_struct(path, value.value)
                klass.create_method(name, return_type: "#{constant_name}#{name.to_s.classify}")
              else
                type = value.default_value
                type = if type.nil?
                         'T.untyped'
                       elsif type == true || type == false
                         'T::Boolean'
                       else
                         type.class.to_s
                       end
                klass.create_method(name, return_type: type)
                klass.create_method("#{name}=",
                                    return_type: "void",
                                    parameters: [create_param("value", type: type)])
              end
            end
          end
          templates = struct.instance_variable_get(:@setting_templates)
          if templates
            templates.each do |name, value|
              klass.create_method(name,
                                  return_type: "void",
                                  parameters: [create_block_param("blk", type: "T.proc.bind(#{constant_name}#{name.to_s.classify}).void")])
              decorate_struct(path, value)
            end
          end

        end
      end

      sig { override.void }
      def decorate
        root.create_path(constant) do |klass|
          constant_name = T.must(constant.name).gsub('::', '')
          class_name = "Private#{constant_name}Config"
          klass.create_include('::FigTree')
          klass.create_method("config", return_type: class_name, class_method: true)
          proc_type = "T.proc.bind(#{class_name}).params(config: #{class_name}).void"
          klass.create_method("configure",
                              class_method: true,
                              return_type: "void",
                              parameters: [create_block_param("blk", type: proc_type)])
          decorate_struct(constant_name, constant.config)
        end
      end

    end
  end
end
