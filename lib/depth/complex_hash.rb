module Depth
  class ComplexHash
    include Depth::Actions
    include Depth::Enumeration::Enumerable
    attr_reader :base
    alias_method :to_h, :base
    def initialize(base = {})
      @base = base
    end
  end
end
