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
    '9' => ':nine:',
    '-' => '—',
    '.' => ':large_blue_circle:'
  }

  def self.modified_roll(roll, modifier, operator)
    operator = operator[1] ? operator[1] : operator[0]
    case operator
    when '+'
      roll + modifier
    when '-'
      roll - modifier
    when '*'
      roll * modifier
    end
  end

  def self.inverted_roll(modified, modifier, operator)
    operator = operator[1] ? operator[1] : operator[0]
    case operator
    when '+'
      modified - modifier
    when '-'
      modified + modifier
    when '*'
      modifier.zero? ? 0 : modified / modifier
    end
  end

  def self.dx(amount, sides, modifier = 0, operator = '+')
    return 0 if amount.zero? || sides.zero? || (operator != '+' && operator != '-')
    rand(amount * sides + 1 - amount) + amount + (modifier * (operator == '+' ? 1 : -1))
  end

  def self.dx_array(amount, sides, modifier = 0, operator = '+')
    return [] if amount.zero? || sides.zero? || amount > 10_000
    array = []
    amount.times do
      array.push(modified_roll(rand(sides) + 1, modifier, operator))
    end
    array
  end

  def self.total_with_drop(roll_array, drop = 1, highest = false)
    return 0 if !roll_array || drop >= roll_array.length
    sorted = roll_array.sort.pop(roll_array.length - drop)
    sorted.reverse! if highest
    sorted.inject(:+)
  end

  def self.avg(roll_array)
    (roll_array.inject(:+).to_f / roll_array.length).round(3)
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
    return 1 if !number || number.zero?
    1 + Math.log(number.abs, 10).floor + (number.negative? ? 1 : 0)
  end

  def self.generate_roll_table(roll_array, sides, factor = 1)
    max_digits = digits(sides * factor) + 1
    line_size = 40 / max_digits
    roll_table = '```'
    roll_array.each_with_index do |num, index|
      roll_table += num.to_s + (' ' * (max_digits - digits(num))) + ((index + 1 % line_size).zero? && !index.zero? ? "\n" : (' ' * (1 + max_digits)))
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

  def self.get_comma_seperated(number)
    number.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, '\\1,')
  end
end
