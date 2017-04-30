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
end
