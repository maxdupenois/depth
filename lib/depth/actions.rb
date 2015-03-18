module Depth
  module Actions
    def set(route, value)
      route = RouteElement.convert_route(route)
      object = route[0 ... -1].reduce(Traverser.new(hsh)) { |t, route_el|
        t.next_or_create(route_el.key) { route_el.create }
      }.object
      object[route.last.key] = value
    end

    def find(route)
      route = RouteElement.convert_route(route)
      route.reduce(Traverser.new(hsh)) { |t, route_el|
        t.next(route_el.key)
      }.object
    end

    def alter(route, key: nil, value: nil)
      return set(route, value) if key == nil
      route = RouteElement.convert_route(route)
      value = find(route) unless value
      new_route = (route[0 ... -1] << RouteElement.convert(new_key))
      set(new_route, value) # ensure it exists
      old_key = route.last.key
      return unless old_key != new_key
      delete(route)
    end

    def delete(route)
      route = RouteElement.convert_route(route)
      traverser = route[0...-1].reduce(Traverser.new(hsh)) do |t, route_el|
        t.next(route_el.key)
      end
      if traverser.array?
        traverser.object.delete_at(route.last.key)
      elsif traverser.hash?
        traverser.object.delete(route.last.key)
      end
    end
  end
end