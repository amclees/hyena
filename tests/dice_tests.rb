# frozen_string_literal: false

require 'simplecov'
SimpleCov.start

require 'test/unit'
require 'set'
require_relative '../dice.rb'

# Tests full coverage and boundaries on Dice
class TestDice < Test::Unit::TestCase
  def test_dx
    d20_set = Set.new
    3000.times do
      roll = Dice.dx(1, 20)
      assert((1..20).cover?(roll))
      d20_set.add(roll)
    end
    assert(((1..20).to_set - d20_set).empty?)

    d20_5_set = Set.new
    20_000.times do
      roll = Dice.dx(5, 20)
      assert((5..100).cover?(roll))
      d20_5_set.add(roll)
    end
    assert(((5..100).to_set - d20_5_set).empty?)

    100.times do
      assert((1..6).cover?(Dice.dx(1, 6)))
    end

    100.times do
      assert((1..8).cover?(Dice.dx(1, 8)))
    end

    100.times do
      assert((1..2).cover?(Dice.dx(1, 2)))
    end

    10_000.times do
      assert((1..100).cover?(Dice.dx(1, 100)))
    end
  end

  def test_dx_array
    d2 = Dice.dx_array(30, 2)
    d6 = Dice.dx_array(75, 6)
    d10 = Dice.dx_array(200, 10)
    d20 = Dice.dx_array(3000, 20)
    d100 = Dice.dx_array(10_000, 100)

    # Coverage testing
    assert(((1..2).to_set - d2.to_set).empty?)
    assert(((1..6).to_set - d6.to_set).empty?)
    assert(((1..10).to_set - d10.to_set).empty?)
    assert(((1..20).to_set - d20.to_set).empty?)
    assert(((1..100).to_set - d100.to_set).empty?)

    # Bounds testing
    d2.each do |roll|
      assert((1..2).cover?(roll))
    end

    d6.each do |roll|
      assert((1..6).cover?(roll))
    end

    d10.each do |roll|
      assert((1..10).cover?(roll))
    end

    d20.each do |roll|
      assert((1..20).cover?(roll))
    end

    d100.each do |roll|
      assert((1..100).cover?(roll))
    end
  end

  def test_digits_needed
    10_000.times do
      num = rand(1_000_000_000)
      str_digits = num.to_s.length
      dice_digits = Dice.digits(num)
      assert_equal(str_digits, dice_digits)
    end
  end

  def test_emoji_generator
    test_num = 1_234_567_890
    assert_equal(Dice.get_emoji_str(test_num), ':one::two::three::four::five::six::seven::eight::nine::zero:')
  end

  def test_roll_table
    modulus = 11
    congruent_rolls = rand(modulus)
    congruent_sides = rand(modulus)
    (2..200).each do |rolls|
      next unless rolls % modulus == congruent_rolls
      (1..1000).each do |sides|
        next unless sides % modulus == congruent_sides
        roll_table = Dice.generate_roll_table(Dice.dx_array(rolls, sides), sides)
        assert(roll_table.length <= 2000)
      end
    end
  end

  def test_meta_methods_auto
    10_000.times do
      sides = rand((2..100))
      rolls = rand((1..200))
      expected_range = (rolls..(rolls * sides))
      value = eval("Dice.d#{sides}x(#{rolls})", nil, __FILE__, __LINE__)
      assert(expected_range.cover?(value))
    end
  end

  def test_meta_methods_manual
    25.times do
      assert((1..2).cover?(Dice.d2))
    end

    50.times do
      assert((1..4).cover?(Dice.d4))
    end

    100.times do
      assert((1..6).cover?(Dice.d6))
    end

    1000.times do
      assert((1..8).cover?(Dice.d8))
    end

    1000.times do
      assert((1..10).cover?(Dice.d10))
    end

    1000.times do
      assert((1..12).cover?(Dice.d12))
    end

    1000.times do
      assert((1..20).cover?(Dice.d20))
    end

    10_000.times do
      assert((1..100).cover?(Dice.d100))
    end

    10_000.times do
      assert((3..60).cover?(Dice.d20x(3)))
    end
  end

  def test_modifiers
    d20_mod_set = Set.new
    3000.times do
      roll = Dice.dx(1, 20, 20)
      assert((21..40).cover?(roll))
      d20_mod_set.add(roll)
    end
    assert(((21..40).to_set - d20_mod_set).empty?)

    rolls = Dice.dx_array(5000, 20, 21, '-')
    rolls.each do |num|
      assert((-20..-1).cover?(num))
    end
    assert(((-20..-1).to_set - rolls.to_set).empty?)

    rolls = Dice.dx_array(5000, 5, 20, '*')
    rolls.each do |num|
      assert((20..100).cover?(num))
    end
    assert(([20, 40, 60, 80, 100].to_set - rolls.to_set).empty?)
  end

  def test_inversion
    rolls = [2, 4, 6, 8, 10, 12, 20, 100]
    modifiers = (1..100)
    operators = ['+', '-', '*']
    5000.times do
      modifier = rand(modifiers)
      operator = operators.sample
      roll = Dice.dx(1, rolls.sample)
      assert_equal(roll, Dice.inverted_roll(Dice.modified_roll(roll, modifier, operator), modifier, operator))
    end
  end

  def test_drop
    array = []
    total = 0
    minimum = 10_000
    1000.times do
      current = rand(1000)
      total += current
      minimum = current if current < minimum
      array.push(current)
      assert_equal(total - minimum, Dice.total_with_drop(array, 1))
    end
  end

  def test_commas
    assert_equal('12,984,234', Dice.get_comma_seperated(12_984_234))
  end

  def test_avg
    assert_equal(15, Dice.avg([0, 30, 15, 10, 20]))
    assert_equal(4.5, Dice.avg([2, 7]))
    assert_equal(3.333, Dice.avg([2.22222222, 4.44444444]))
  end
end
