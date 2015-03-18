module Depth
  class ComplexHash
    include Depth::Actions
    include Depth::Enumerable
    attr_reader :base
    def initialize(base = {})
      @base = base
    end
  end
end
