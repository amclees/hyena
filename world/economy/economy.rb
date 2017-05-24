# frozen_string_literal: false

# Economy is a wrapper for CurrencySystem that corresponds to an individual city's economy.
class Economy
  attr_reader :currency_system

  def initialize(parent_currency_system = CurrencySystem.new)
    @parent_currency_system = parent_currency_system
    pull_from_parent
  end

  def pull_from_parent
    @currency_system = CurrencySystem.new(@parent_currency_system.currency_value.clone)
  end
end
