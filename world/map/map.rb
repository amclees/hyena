# frozen_string_literal: false

# Map handles routes between cities
class Map
  def initialize
    @city_routes = Hash.new([])
    @route_weights = Hash.new([])
    @cities = []
  end

  def add_city(city)
    @cities.push(city)
  end

  def add_route(city1, city2, weight)
    @city_routes[city1].push(city2)
    @route_weights[city1].push(weight)
  end

  def add_two_way_route(city1, city2, weight)
    add_route(city1, city2, weight)
    add_route(city2, city1, weight)
  end

  # TODO: Finish distance algorithm
  def get_distance(city1, city2)
    unchecked = @cities.delete(city1).delete(city2)
    candidates = [city1]
    until unchecked.empty?
      current = candidates.shift
      index = @city_routes[current].indexOf(city2)
      return @route_weights[current][index] if index >= 0
      candidates.unshift(@city_routes[current])
    end
  end
end
