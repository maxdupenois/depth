module Depth
  module Enumeration
    class Node < Struct.new(:parent, :parent_index, :fragment)
      def current_index
        @current_index ||= 0
      end

      def route
        route = []
        current = self
        while(!current.root?)
          route << RouteElement.new(current.parent_key, type: current.fragment_type)
          current = current.parent
        end
        route.reverse
      end

      def next
        if array?
          val = fragment[current_index]
        else
          val = fragment[fragment.keys[current_index]]
        end
        Node.new(self, current_index, val).tap { @current_index += 1 }
      end

      def parent_key
        return nil unless parent.enumerable? # root
        return parent_index if parent.array?
        parent.fragment.keys[parent_index]
      end

      def next?
        return false if leaf?
        current_index < fragment.count
      end

      def array?
        fragment.is_a?(Array)
      end

      def hash?
        fragment.is_a?(Hash)
      end

      def fragment_type
        { 
          Array => :array,
          Hash => :hash
        }.fetch(fragment.class, :leaf)
      end

      def enumerable?
        # ignore other types for the moment
        array? || hash?
      end

      def leaf?
        !enumerable?
      end

      def root?
        parent.nil?
      end
    end
  end
end
