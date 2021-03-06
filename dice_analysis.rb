# frozen_string_literal: false

require 'json'
require_relative './dice.rb'
require_relative './json_manager.rb'

JSONManager.init('data')

puts 'Number of dice:'
dice = gets.chomp.to_i
puts 'Sides on dice:'
sides = gets.chomp.to_i
puts 'Rolls per test:'
rolls = gets.chomp.to_i
highest = true
keep = 1
if rolls.to_i > 1
  puts 'Keep the highest ("h") or lowest ("l"):'
  highest = gets.chomp.strip == 'h'
  puts 'How many of the dice should be dropped:'
  keep = gets.chomp.to_i
end
puts 'Number of tests per result set:'
set_size = gets.chomp.to_i
puts 'Number of tests:'
tests = gets.chomp.to_i

total = 0
distribution = Hash.new(0)
tests.times do
  current_set = []
  set_size.times do
    results = []
    rolls.times do
      results.push(Dice.dx(dice, sides))
    end
    results.sort!
    if highest
      results.slice!(0, keep)
    else
      results.slice!(results.length - keep, keep)
    end
    current_set.push(results.inject(:+))
  end
  result = current_set.inject(:+)
  total += result
  distribution[result] += 1
end
average = total.to_f / tests.to_f
puts "Average was #{average}"
distribution_table = ''
distribution.keys.sort.each do |key|
  distribution_table += "#{key} - #{distribution[key]} - #{(100.0 * (distribution[key].to_f / tests.to_f)).round(4)}\n"
end
puts distribution_table
puts 'Enter a distribution name for the JSON to be stored under:'
JSONManager.write_json('dice_distributions', "#{gets.chomp.strip}.json", distribution.to_json)
