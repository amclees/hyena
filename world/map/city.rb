# frozen_string_literal: false

# A City is a single node with an economy and population in the map.
class City
  def initialize(parent_currency_system, options = {})
    @economy = Economy.new(parent_currency_system)

    default_options = {
      population: 1000,
      midpoint_population: 12_000,
      economy_per_population_multiplier: 0.1,
      faction: :neutral
    }
    options.merge!(default_options)
    @population = default_options[:population]
    @midpoint_population = options[:midpoint_population]
    @economy_per_population_multiplier = options[:economy_per_population_multiplier]
    @faction = options[:faction]
  end

  def economic_impact
    (@population / @midpoint_population) * @population * @economy_per_population_multiplier
  end
end
