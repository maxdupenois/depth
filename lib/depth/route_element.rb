module Depth
  class RouteElement
    attr_reader :key_or_index, :type
    alias_method :key, :key_or_index
    alias_method :index, :key_or_index
    def initialize(key_or_index, type: :hash)
      @key_or_index = key_or_index
      @type = type.to_sym
    end

    def create
      { hash: {}, array: [], leaf: nil }.fetch(type, nil)
    end

    class << self
      def convert_route(route_array)
        Array(route_array).map { |el| convert(el) }
      end

      def convert(el)
        return el if el.is_a?(RouteElement)
        case el
        when Array
          type = el.count > 1 ? el[1] : :hash
          RouteElement.new(el[0], type: type)
        when Hash
          key_or_index = el.fetch(:key) { el.fetch(:index) }
          RouteElement.new(key_or_index, type: el.fetch(:type, :hash))
        else
          RouteElement.new(el)
        end
      end
    end
  end
end
