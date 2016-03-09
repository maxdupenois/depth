module Depth
  class ComplexHash
    include Depth::Actions
    include Depth::Enumeration::Enumerable
    DEFAULT_KEY_TRANSFORMER = proc { |obj, key| key }
    DEFAULT_NEXT_PROC = proc { |obj, key| obj[key] }
    DEFAULT_CREATION_PROC = proc { |obj, key, val| obj[key] = val }
    attr_reader :base, :next_proc, :creation_proc, :key_transformer
    alias_method :to_h, :base
    def initialize(base = {},
                   key_transformer: DEFAULT_KEY_TRANSFORMER,
                   next_proc: DEFAULT_NEXT_PROC,
                   creation_proc: DEFAULT_CREATION_PROC)
      @base = base
      @next_proc = next_proc
      @creation_proc = creation_proc
      @key_transformer = key_transformer
    end
  end
end
