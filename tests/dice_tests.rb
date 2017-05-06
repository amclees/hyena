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
      assert_true((1..20).cover?(roll))
      d20_set.add(roll)
    end
    assert_true(((1..20).to_set - d20_set).empty?)

    d20_5_set = Set.new
    20_000.times do
      roll = Dice.dx(5, 20)
      assert_true((5..100).cover?(roll))
      d20_5_set.add(roll)
    end
    assert_true(((5..100).to_set - d20_5_set).empty?)

    100.times do
      assert_true((1..6).cover?(Dice.dx(1, 6)))
    end

    100.times do
      assert_true((1..8).cover?(Dice.dx(1, 8)))
    end

    100.times do
      assert_true((1..2).cover?(Dice.dx(1, 2)))
    end

    10_000.times do
      assert_true((1..100).cover?(Dice.dx(1, 100)))
    end
  end

  def test_dx_array
    d2 = Dice.dx_array(30, 2)
    d6 = Dice.dx_array(75, 6)
    d10 = Dice.dx_array(200, 10)
    d20 = Dice.dx_array(3000, 20)
    d100 = Dice.dx_array(10_000, 100)

    # Coverage testing
    assert_true(((1..2).to_set - d2.to_set).empty?)
    assert_true(((1..6).to_set - d6.to_set).empty?)
    assert_true(((1..10).to_set - d10.to_set).empty?)
    assert_true(((1..20).to_set - d20.to_set).empty?)
    assert_true(((1..100).to_set - d100.to_set).empty?)

    # Bounds testing
    d2.each do |roll|
      assert_true((1..2).cover?(roll))
    end

    d6.each do |roll|
      assert_true((1..6).cover?(roll))
    end

    d10.each do |roll|
      assert_true((1..10).cover?(roll))
    end

    d20.each do |roll|
      assert_true((1..20).cover?(roll))
    end

    d100.each do |roll|
      assert_true((1..100).cover?(roll))
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
        assert_true(roll_table.length <= 2000)
      end
    end
  end

  def test_meta_methods_auto
    10_000.times do
      sides = rand(99) + 2
      rolls = rand(200) + 1
      expected_range = (rolls..(rolls * sides))
      value = eval("Dice.d#{sides}x(#{rolls})")
      assert_true(expected_range.cover?(value))
    end
  end

  def test_meta_methods_manual
    25.times do
      assert_true((1..2).cover?(Dice.d2))
    end

    50.times do
      assert_true((1..4).cover?(Dice.d4))
    end

    100.times do
      assert_true((1..6).cover?(Dice.d6))
    end

    1000.times do
      assert_true((1..8).cover?(Dice.d8))
    end

    1000.times do
      assert_true((1..10).cover?(Dice.d10))
    end

    1000.times do
      assert_true((1..12).cover?(Dice.d12))
    end

    1000.times do
      assert_true((1..20).cover?(Dice.d20))
    end

    10_000.times do
      assert_true((1..100).cover?(Dice.d100))
    end

    10_000.times do
      assert_true((3..60).cover?(Dice.d20x(3)))
    end
  end

  def test_regex
    regex = Dice.dice_regex
    captured1 = "2048    \n       d    204   *-  \n\n\n  2".scan(regex)[0]
    captured2 = '2d20+5'.scan(regex)[0]
    captured3 = 'd20'.scan(regex)[0]
    assert_equal(['2048', '204', '*-', '2'], captured1)
    assert_equal(['2', '20', '+', '5'], captured2)
    assert_equal([nil, '20', nil, nil], captured3)
  end

  def test_modifiers
    d20_mod_set = Set.new
    3000.times do
      roll = Dice.dx(1, 20, 20)
      assert_true((21..40).cover?(roll))
      d20_mod_set.add(roll)
    end
    assert_true(((21..40).to_set - d20_mod_set).empty?)

    rolls = Dice.dx_array(5000, 20, 21, '-')
    rolls.each do |num|
      assert_true((-20..-1).cover?(num))
    end
    assert_true(((-20..-1).to_set - rolls.to_set).empty?)

    rolls = Dice.dx_array(5000, 5, 20, '*')
    rolls.each do |num|
      assert_true((20..100).cover?(num))
    end
    assert_true(([20, 40, 60, 80, 100].to_set - rolls.to_set).empty?)
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
end
