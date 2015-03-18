module Depth
  module Enumerable

    def each_with_object(object, &block)
      each do |key, fragment|
        block.call(key, fragment, object)
      end
      object
    end

    def reduce(memo, &block)
      each do |key, fragment|
        memo = block.call(memo, key, fragment)
      end
      memo
    end

    def map_keys!(&block)
      @base = map_keys(&block).base
    end

    def map!(&block)
      @base = map(&block).base
    end

    def map_keys_and_values!(&block)
      @base = map_keys_and_values(&block).base
    end

    def map_keys(&block)
      map_keys_and_values do |key, fragment|
        [block.call(key), fragment]
      end
    end

    # Convention is that only values are mapped
    def map(&block)
      map_keys_and_values do |key, fragment|
        [key, block.call(fragment)]
      end
    end

    def map_keys_and_values(&block)
      node_map do |node, new_q|
        orig_key = node.parent_key
        existing = new_q.find(node.route)
        orig_fragment = existing.nil? ? node.fragment : existing
        next [orig_key, orig_fragment] unless node.parent.hash?
        block.call(orig_key, orig_fragment)
      end
    end

    def each(&block)
      enumerate { |node| block.call(node.parent_key, node.fragment) }
    end

    private

    def node_map(&block)
      new_q = ComplexHash.new(base.class.new)
      enumerate do |node|
        key, val = block.call(node, new_q)
        new_q.alter(node.route, key: key, value: val)
      end
      new_q
    end

    def enumerate
      root = Node.new(nil, nil, query)
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
