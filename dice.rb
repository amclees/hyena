# frozen_string_literal: false

# Serves as a container for dice rolling methods.
module Dice
  @emoji_digits = {
    '0' => ':zero:',
    '1' => ':one:',
    '2' => ':two:',
    '3' => ':three:',
    '4' => ':four:',
    '5' => ':five:',
    '6' => ':six:',
    '7' => ':seven:',
    '8' => ':eight:',
    '9' => ':nine:'
  }

  def self.dx(amount, sides)
    return 0 if amount.zero? || sides.zero?
    rand(amount * sides + 1 - amount) + amount
  end

  def self.dx_array(amount, sides)
    return 0 if amount.zero? || sides.zero? || sides > 10_000
    array = []
    (0...amount).each do
      array.push(rand(sides) + 1)
    end
    array
  end

  (2..100).each do |num|
    define_singleton_method("d#{num}x".to_sym) do |amount|
      dx(amount, num)
    end
    define_singleton_method("d#{num}".to_sym) do
      dx(1, num)
    end
  end

  # Returns the number of decimal digits needed to represent the number
  def self.digits(number)
    1 + Math.log(number, 10).floor
  end

  def self.generate_roll_table(roll_array, sides)
    max_digits = digits(sides)
    line_size = 40 / max_digits
    roll_table = '```'
    roll_array.each_with_index do |num, index|
      roll_table += num.to_s + (' ' * (max_digits - digits(num))) + ((index + 1 % line_size).zero? && !index.zero? ? "\n" : ' ' * (1 + max_digits))
    end
    roll_table + "\n```"
  end

  def self.get_emoji_str(sides)
    emoji = sides.to_s
    @emoji_digits.each do |digit, emoji_digit|
      emoji.gsub!(digit, emoji_digit)
    end
    emoji
  end
end
