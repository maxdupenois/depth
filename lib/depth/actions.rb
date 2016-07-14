module Depth
  module Actions
    #:nocov:
    def base
      raise NoMethodError.new('should be overridden')
    end

    def next_proc
      raise NoMethodError.new('should be overridden')
    end

    def creation_proc
      raise NoMethodError.new('should be overridden')
    end

    def key_transformer
      raise NoMethodError.new('should be overridden')
    end
    #:nocov:

    def set(route, value)
      route = RouteElement.convert_route(route)
      base_traverser = Traverser.new(
        base, next_proc: next_proc,
        creation_proc: creation_proc,
        key_transformer: key_transformer
      )
      object = route[0 ... -1].reduce(base_traverser) { |t, route_el|
        t.next_or_create(route_el.key) { route_el.create }
      }.object
      original_key = route.last.key
      transformed_key = key_transformer.call(object, route.last.key)
      creation_proc.call(object, transformed_key, value, original_key)
    end

    def find(route, create: false, default: nil)
      return self if route.empty?
      route = RouteElement.convert_route(route)
      base_traverser = Traverser.new(
        base, next_proc: next_proc,
        creation_proc: creation_proc,
        key_transformer: key_transformer
      )
      parent = route[0 ... -1].reduce(base_traverser) { |t, route_el|
        if create
          t.next_or_create(route_el.key) { route_el.create }
        else
          t.next(route_el.key)
        end
      }.object

      return default if parent.nil?

      original_key = route.last.key
      transformed_key = key_transformer.call(parent, route.last.key)
      object = next_proc.call(parent, transformed_key, original_key)
      return object unless object.nil?
      return creation_proc.call(parent, transformed_key, default, original_key) if create && default
      default
    end

    def alter(route, key: nil, value: nil)
      return set(route, value) if key.nil?
      route = RouteElement.convert_route(route)
      value = find(route) if value.nil?
      new_route = (route[0 ... -1] << RouteElement.convert(key))
      # ensure it exists
      set(new_route, value)
      old_key = route.last.key
      return unless old_key != key
      delete(route)
    end

    def delete(route)
      route = RouteElement.convert_route(route)
      base_traverser = Traverser.new(
        base, next_proc: next_proc,
        creation_proc: creation_proc,
        key_transformer: key_transformer
      )
      traverser = route[0...-1].reduce(base_traverser) do |t, route_el|
        t.next(route_el.key)
      end
      last_key = key_transformer.call(traverser.object, route.last.key)
      if traverser.array?
        traverser.object.delete_at(last_key)
      elsif traverser.hash?
        traverser.object.delete(last_key)
      end
    end
  end
end
