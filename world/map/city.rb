# frozen_string_literal: false

# A City is a single economic node in the map.
class City
  def initialize(currency_system = CurrencySystem.new, options = {})
    default_options = {
      population: 1000,
      midpoint_population: 12_000,
      economy_per_population_multiplier: 0.1
    }
    options.merge!(default_options)
    @currency_system = currency_system
    @population = default_options[:population]
    @midpoint_population = options[:midpoint_population]
    @economy_per_population_multiplier = options[:economy_per_population_multiplier]
  end

  def economic_impact
    (@population / @midpoint_population) * @population * @economy_per_population_multiplier
  end
end
