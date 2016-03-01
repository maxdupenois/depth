module Depth
  module Enumeration
    module Enumerable
      #:nocov:
      def base
        raise NoMethodError.new('should be overridden')
      end
      #:nocov:

      def each_with_object(object, &block)
        object.tap do |obj|
          each do |key, fragment, route|
            block.call(key, fragment, obj, route)
          end
        end
      end

      def select(&block)
        new_q = self.class.new(base.class.new)
        routes_to_delete = []
        enumerate do |node, route|
          key = node.parent_key
          existing = new_q.find(node.route)
          fragment = existing.nil? ? node.fragment : existing
          keep = block.call(key, fragment, route)
          if keep
            new_q.alter(node.route, key: key, value: fragment)
          else
            routes_to_delete << node.route
          end
        end
        routes_to_delete.each { |r| new_q.delete(r) }
        new_q
      end

      def reject(&block)
        select{ |key, fragment, route| !block.call(key, fragment, route) }
      end

      def reduce(memo, &block)
        each do |key, fragment, route|
          memo = block.call(memo, key, fragment, route)
        end
        memo
      end

      def map_keys!(&block)
        @base = map_keys(&block).base
        self
      end

      def map_values!(&block)
        @base = map_values(&block).base
        self
      end

      def map!(&block)
        @base = map(&block).base
        self
      end

      def map_keys(&block)
        map do |key, fragment, route|
          [block.call(key, route), fragment]
        end
      end

      def map_values(&block)
        map do |key, fragment, route|
          [key, block.call(fragment, route)]
        end
      end

      def map(&block)
        node_map do |node, new_q, route|
          orig_key = node.parent_key
          existing = new_q.find(node.route)
          orig_fragment = existing.nil? ? node.fragment : existing
          block.call(orig_key, orig_fragment, route)
        end
      end

      def each(&block)
        enumerate { |node, route| block.call(node.parent_key, node.fragment, route) }
      end

      private

      def node_map(&block)
        new_q = self.class.new(base.class.new)
        enumerate do |node, route|
          key, val = block.call(node, new_q, route)
          new_q.alter(node.route, key: key, value: val)
        end
        new_q
      end

      def enumerate
        root = Node.new(nil, nil, base)
        current = root
        begin
          if current.next?
            current = current.next
          elsif !current.root?
            yield(current, current.humanized_route)
            current = current.parent
          end
        end while !current.root? || current.next?
        self
      end

    end
  end
end
