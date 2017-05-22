# frozen_string_literal: false

# Handles numerical values of different parts of a currency system (default is the standard D&D system).
class CurrencySystem
  attr_reader :currency_value

  def initialize(currency_hash = {
    cp: 1,
    sp: 10,
    gp: 100,
    pp: 1000
  })
    @currency_value = currency_hash
    rebuild_data_from_hash
  end

  def rebuild_data_from_hash
    @currency_values_ordered = @currency_value.values.sort
    @currency_labels_ordered = @currency_value.keys.sort do |key1, key2|
      @currency_value[key1] <=> @currency_value[key2]
    end
    # Sample produced regex for standard D&D system: /\A\s*(?:(\d+)\s*cp)?\s*(?:(\d+)\s*sp)?\s*(?:(\d+)\s*gp)?\s*(?:(\d+)\s*pp)?\s*\z/i
    regex_str = '\A\s*'
    @currency_labels_ordered.each do |label|
      regex_str += '(?:(\d+)\s*' + Regexp.quote(label) + ')?\s*'
    end
    regex_str += '\z'
    @currency_regex = Regexp.new(regex_str, true)
  end

  def parse_total_value(string)
    values = string.scan(@currency_regex)[0]
    values.each_with_index.inject(0) do |totaled, (amount, index)|
      totaled + amount.to_i * @currency_values_ordered[index]
    end
  end

  def parse_values(string)
    string.scan(@currency_regex)[0].map(&:to_i)
  end

  def stringify_values(values)
    string = ''
    values.each_with_index do |value, index|
      string += "#{value}#{@currency_labels_ordered[index]} " unless value.zero?
    end
    string.strip
  end

  def split_total(value)
    used_currency = []
    @currency_values_ordered.length.times do
      used_currency.push(0)
    end
    @currency_labels_ordered.reverse.each_with_index do |label, index|
      index = (@currency_labels_ordered.length - 1) - index
      used_currency[index] = value / @currency_value[label]
      value = value % @currency_value[label]
    end
    used_currency
  end

  def change_value(label, value)
    @currency_value[label] = value
    rebuild_data_from_hash
  end

  def value(label)
    @currency_value[label]
  end
end
