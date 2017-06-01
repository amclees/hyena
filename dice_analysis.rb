# frozen_string_literal: false

require_relative './dice.rb'

puts 'Number of dice:'
dice = gets.chomp.to_i
puts 'Sides on dice:'
sides = gets.chomp.to_i
puts 'Rolls per test:'
rolls = gets.chomp.to_i
highest = true
if rolls.to_i > 1
  puts 'Highest ("h") or lowest ("l"):'
  highest = gets.chomp.strip == 'h'
end
puts 'Number of tests:'
tests = gets.chomp.to_i

total = 0
distribution = Hash.new(0)
initial_value = highest ? 0 : (dice * sides) + 1
tests.times do
  result = initial_value
  rolls.times do
    roll = Dice.dx(dice, sides)
    result = roll if (roll > result) == highest
  end
  total += result
  distribution[result] += 1
end
average = total / tests
puts "Average was #{average}"
distribution_table = ''
distribution.keys.sort.each do |key|
  distribution_table += "#{key} - #{distribution[key]} - #{(100.0 * (distribution[key].to_f / tests.to_f)).round(4)}\n"
end
puts distribution_table
