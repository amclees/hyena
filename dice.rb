# frozen_string_literal: false

# Serves as a container for dice rolling methods.
module Dice
  def self.dx(amount, sides)
    return 0 if amount.zero? || sides.zero?
    rand(amount * sides - amount) + amount
  end

  def self.dx_array(amount, sides)
    return 0 if amount.zero? || sides.zero? || sides > 10_000
    array = []
    (0...amount).each do
      array.push(rand(sides) + 1)
    end
    array
  end
end

(2..100).each do |num|
  # TODO: Rewrite this using define_method
  eval(%(
    module Dice
      def self.d#{num}x(amount)
        self.dx(amount, #{num})
      end
      def self.d#{num}
        self.dx(1, #{num})
      end
    end
  ))
end
