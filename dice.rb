module Dice
  def self.dx(amount, sides)
    unless amount == 0 or sides == 0
      sum = 0
      (0...amount).each do
        sum += rand(sides) + 1
      end
      sum
    else
      0
    end
  end
end

(2..100).each do |num|
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
