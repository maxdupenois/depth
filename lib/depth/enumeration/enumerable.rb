module Depth
  module Enumeration
    module Enumerable
      #:nocov:
      def base
        raise NoMethodError.new('should be overridden')
      end
      #:nocov:

      def each_with_object(object, &block)
        object.tap do |o|
          each do |key, fragment|
            block.call(key, fragment, o)
          end
        end
      end

      def reduce(memo, &block)
        each do |key, fragment|
          memo = block.call(memo, key, fragment)
        end
        memo
      end

      def map_keys!(&block)
        @base = map_keys(&block).base
        self
      end

      def map!(&block)
        @base = map(&block).base
        self
      end

      def map_keys_and_values!(&block)
        @base = map_keys_and_values(&block).base
        self
      end

      def map_keys(&block)
        map_keys_and_values do |key, fragment, parent_type|
          # ignore if parent is array
          next [key, fragment] if parent_type == :array
          [block.call(key), fragment]
        end
      end

      # Convention is that only values are mapped
      def map(&block)
        map_keys_and_values do |key, fragment, parent_type|
          [key, block.call(fragment)]
        end
      end

      def map_keys_and_values(&block)
        node_map do |node, new_q|
          orig_key = node.parent_key
          existing = new_q.find(node.route)
          orig_fragment = existing.nil? ? node.fragment : existing
          parent_type = node.parent.fragment_type
          block.call(orig_key, orig_fragment, parent_type)
        end
      end

      def each(&block)
        enumerate { |node| block.call(node.parent_key, node.fragment) }
      end

      private

      def node_map(&block)
        new_q = self.class.new(base.class.new)
        enumerate do |node|
          key, val = block.call(node, new_q)
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
            yield(current)
            current = current.parent
          end
        end while !current.root? || current.next?
        root.fragment
      end

    end
  end
end
