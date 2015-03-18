module Depth
  class Traverser < Struct.new(:object)
    def array?
      object.is_a?(Array)
    end

    def hash?
      object.is_a?(Hash)
    end

    def next(key_or_index)
      return Traverser.new(nil) if object.nil? 
      Traverser.new(object[key_or_index])
    end

    def next_or_create(key_or_index, &block)
      return Traverser.new(nil) if object.nil? 
      object[key_or_index] = block.call if object[key_or_index].nil?
      Traverser.new(object[key_or_index])
    end
  end
end
