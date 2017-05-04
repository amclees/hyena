# frozen_string_literal: false

# Economy is a wrapper for CurrencySystem that provides functions for varying prices and currency values according to the world state.
class Economy
  def initialize(currency_system = CurrencySystem.new)
    @currency_system = currency_system
  end
end
