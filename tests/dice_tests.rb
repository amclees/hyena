# frozen_string_literal: false

require 'test/unit'
require_relative '../dice.rb'

class TestDice < Test::Unit::TestCase

  def test_dx
    (0...1000).each do
      assert_true((1..20) === Dice.dx(1, 20))
    end

    (0...1000).each do
      assert_true((5..100) === Dice.dx(5, 20))
    end

    (0...100).each do
      assert_true((1..6) === Dice.dx(1, 6))
    end

    (0...100).each do
      assert_true((1..8) === Dice.dx(1, 8))
    end

    (0...100).each do
      assert_true((1..2) === Dice.dx(1, 2))
    end

    (0...10000).each do
      assert_true((1..100) === Dice.dx(1, 100))
    end
  end

  def test_meta_methods_auto
    (0...10000).each do
      sides = rand(99) + 2
      rolls = rand(200) + 1
      expectedRange = (rolls..(rolls * sides))
      value = eval("Dice.d#{sides}x(#{rolls})")
      assert_true(expectedRange === value)
    end
  end

  def test_meta_methods_manual
    (0...25).each do
      assert_true((1..2) === Dice.d2)
    end

    (0...50).each do
      assert_true((1..4) === Dice.d4)
    end

    (0...100).each do
      assert_true((1..6) === Dice.d6)
    end

    (0...1000).each do
      assert_true((1..8) === Dice.d8)
    end

    (0...1000).each do
      assert_true((1..10) === Dice.d10)
    end

    (0...1000).each do
      assert_true((1..12) === Dice.d12)
    end

    (0...1000).each do
      assert_true((1..20) === Dice.d20)
    end

    (0...10000).each do
      assert_true((1..100) === Dice.d100)
    end

    (0...10000).each do
      assert_true((3..60) === Dice.d20x(3))
    end
  end

end
