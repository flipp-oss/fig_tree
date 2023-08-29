# typed: true

module FigTree
  extend ::ActiveSupport::Concern

  mixes_in_class_methods ::FigTree::ClassMethods
end

module FigTree::ClassMethods
  sig { params(block: T.proc.bind(::FigTree::ConfigStruct).void).void }
  def after_configure(&block); end

  sig { returns(::FigTree::ConfigStruct) }
  def config; end

  sig { params(block: T.proc.bind(::FigTree::ConfigStruct).void).void }
  def configure(&block); end

  sig { params(block: T.proc.bind(::FigTree::ConfigStruct).void).void }
  def define_settings(&block); end

  sig { params(values: T.nilable(Hash), block: T.proc).void }
  def with_config(values = T.unsafe(nil), &block); end
end

class FigTree::ConfigStruct
  include ::ActiveSupport::Callbacks
  extend ::ActiveSupport::Callbacks::ClassMethods
  extend ::ActiveSupport::DescendantsTracker

  sig { params(name: String) }
  def initialize(name); end

  # source://fig_tree//lib/fig_tree.rb#74
  def clone_and_reset; end

  sig { params(old_config: String, new_config: String).void }
  def deprecate(old_config, new_config); end

  sig { returns(String) }
  def inspect; end

  sig { void }
  def reset!; end

  sig { params(name: Symbol, default_value: T.untyped, default_proc: T.proc, block: T.proc).void }
  def setting(name, default_value = T.unsafe(nil), default_proc: T.unsafe(nil), &block); end

  sig {params(name: Symbol, block: T.proc.bind(::FigTree::ConfigStruct).void).void }
  def setting_object(name, &block); end

  sig { returns(Hash) }
  def to_h; end
end

class FigTree::ConfigValue < ::Struct
  sig { void }
  def clone_and_reset; end

  sig { returns(T.untyped) }
  def default_proc; end

  sig { params(_: T.untyped).void }
  def default_proc=(_); end

  sig { returns(T.untyped) }
  def default_value; end

  sig { params(_: T.untyped).void }
  def default_value=(_); end

  sig { void }
  def reset!; end

  sig { returns(T.untyped) }
  def value; end

  sig { params(_: T.untyped).void }
  def value=(_); end

  class << self
    def [](*_arg0); end
    def inspect; end
    def keyword_init?; end
    def members; end
    def new(*_arg0); end
  end
end

# source://fig_tree//lib/fig_tree/version.rb#4
FigTree::VERSION = T.let(T.unsafe(nil), String)
