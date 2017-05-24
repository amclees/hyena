# frozen_string_literal: false

require 'simplecov'
SimpleCov.start

require_relative '../world/economy/currency_system.rb'
require_relative '../world/economy/economy.rb'

# Tests CurrencySystem including parsing and custom system definitions
class TestCurrencySystem < Test::Unit::TestCase
  def test_value_storage
    main = CurrencySystem.new
    assert_equal(1, main.value(:cp))
    assert_equal(10, main.value(:sp))
    assert_equal(100, main.value(:gp))
    assert_equal(1000, main.value(:pp))
    main.change_value(:sp, 12)
    assert_equal(12, main.value(:sp))
  end

  def test_format
    main = CurrencySystem.new
    assert_equal('5gp', main.stringify_values([0, 0, 5, 0]))
    assert_equal('1cp 5sp 84gp', main.stringify_values([1, 5, 84, 0]))
    assert_equal('93pp', main.stringify_values([0, 0, 0, 93]))
    assert_equal('5cp 2pp', main.stringify_values([5, 0, 0, 2]))
    assert_equal('3sp 56pp', main.stringify_values([0, 3, 0, 56]))
  end

  def test_parse
    main = CurrencySystem.new
    whitespace = lambda do
      rand > 0.25 ? (' ' * rand(10)) : "\n"
    end
    10_000.times do
      values = [rand(100), rand(100), rand(100), rand(100)]
      labels = %i[cp sp gp pp]
      to_parse = values.each_with_index.reduce('') do |string, (value, index)|
        string + whitespace.call + value.to_s + whitespace.call + labels[index].to_s
      end
      assert_equal(values, main.parse_values(to_parse))
      assert_equal(values[0] + (values[1] * 10) + (values[2] * 100) + (values[3] * 1000), main.parse_total_value(to_parse))
    end
  end

  def test_split_total
    main = CurrencySystem.new
    total1 = 1215
    assert_equal([5, 1, 2, 1], main.split_total(total1))
    total2 = 7
    assert_equal([7, 0, 0, 0], main.split_total(total2))
    total3 = 142_809
    assert_equal([9, 0, 8, 142], main.split_total(total3))
  end

  def test_custom_systems
    odd_system_hash = {
      penny: 1,
      nickel: 5,
      dime: 10,
      quarter: 25,
      shellfish: 33,
      pencil: 73,
      ruby: 750
    }
    odd_system = CurrencySystem.new(odd_system_hash)
    odd_system.change_value(:ruby, 734)
    whitespace = lambda do
      rand > 0.25 ? (' ' * rand(10)) : "\n"
    end
    10_000.times do
      values = [rand(100), rand(100), rand(100), rand(100), rand(100), rand(100), rand(100)]
      labels = odd_system_hash.keys
      to_parse = values.each_with_index.reduce('') do |string, (value, index)|
        string + whitespace.call + value.to_s + whitespace.call + labels[index].to_s
      end
      assert_equal(values, odd_system.parse_values(to_parse))
    end
    total = 501_189
    assert_equal([2, 1, 1, 0, 0, 8, 682], odd_system.split_total(total))
  end
end

# Tests individual and multiple economies based on the same currency system.
class TestEconomy < Test::Unit::TestCase
  def test_individual
    parent_currency_system = CurrencySystem.new
    economy = Economy.new(parent_currency_system)
    assert_not_nil(economy.currency_system)
    economy.currency_system.change_value(:sp, 11)
    assert_equal(11, economy.currency_system.value(:sp))
    assert_equal(10, parent_currency_system.value(:sp))
    economy.pull_from_parent
    assert_equal(10, economy.currency_system.value(:sp))
  end

  def test_multiple
    parent_currency_system = CurrencySystem.new
    economy1 = Economy.new(parent_currency_system)
    economy2 = Economy.new(parent_currency_system)

    economy1.currency_system.change_value(:sp, 11)
    assert_equal(11, economy1.currency_system.value(:sp))
    assert_equal(10, economy2.currency_system.value(:sp))
    assert_equal(10, parent_currency_system.value(:sp))
    economy1.pull_from_parent
    assert_equal(10, economy1.currency_system.value(:sp))

    parent_currency_system.change_value(:gp, 111)
    economy1.pull_from_parent
    assert_equal(111, economy1.currency_system.value(:gp))
    assert_equal(100, economy2.currency_system.value(:gp))
    assert_equal(111, parent_currency_system.value(:gp))
  end
end
