# frozen_string_literal: false

# Handles numerical values of different parts of a currency system (default is the standard D&D system).
class CurrencySystem
  @currency_value = {
    cp: 1,
    sp: 10,
    gp: 100,
    pp: 1000
  }
  @currency_value_ordered = [1, 10, 100, 1000]

  def parse_value(string)
    # TODO: Write a dynamic regex generator for other currency systems
    values = string.scan(/\A\s*(?:(\d+)\s*cp)?\s*(?:(\d+)\s*sp)?\s*(?:(\d+)\s*gp)?\s*(?:(\d+)\s*pp)?\s*\z/i)
    values.each_with_index.inject(0) do |total_value, (amount, index)|
      total_value + amount * currency_value_ordered[index]
    end
  end
end
