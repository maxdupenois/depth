module Depth
  class Traverser

    attr_reader :object

    def initialize(object,
                   key_transformer:,
                   next_proc:, creation_proc:)
      @object = object
      @next_proc = next_proc
      @creation_proc = creation_proc
      @key_transformer = key_transformer
    end

    def array?
      object.is_a?(Array)
    end

    def hash?
      object.is_a?(Hash)
    end

    def next(key_or_index)
      return Traverser.new(
        nil,
        key_transformer: key_transformer,
        next_proc: next_proc,
        creation_proc: creation_proc
      ) if object.nil?

      original_key = key_or_index
      key_or_index = key_transformer.call(object, key_or_index)
      next_object = next_proc.call(object, key_or_index, original_key)

      Traverser.new(
        next_object,
        key_transformer: key_transformer,
        next_proc: next_proc,
        creation_proc: creation_proc
      )
    end

    def next_or_create(key_or_index, &block)
      return Traverser.new(
        nil,
        key_transformer: key_transformer,
        next_proc: next_proc,
        creation_proc: creation_proc
      ) if object.nil?

      original_key = key_or_index
      key_or_index = key_transformer.call(object, key_or_index)
      next_object = next_proc.call(object, key_or_index, original_key)
      creation_proc.call(object, key_or_index, block.call, original_key) if next_object.nil?
      Traverser.new(
        # Refetch it to allow for creation
        next_proc.call(object, key_or_index, original_key),
        key_transformer: key_transformer,
        next_proc: next_proc,
        creation_proc: creation_proc
      )
    end

  private
    attr_reader :next_proc, :creation_proc, :key_transformer
  end
end
