# frozen_string_literal: false

require 'json'
require_relative '../dice.rb'

# Holds combatants and handles combat round progression
class CombatManager
  attr_accessor :combatants, :round, :name, :id
  attr_reader :user_id
  @pool = 0

  def self.new_id
    @pool += 1
  end

  def initialize(name, combatants, user_id)
    @name = name
    @combatants = combatants
    @round = 0
    @id = self.class.new_id
    @user_id = user_id
  end

  def next_round
    @combatants = CombatManager.get_turn_ordered(@combatants)
    @round += 1
  end

  def pop_combatant(id)
    dropped = nil
    unless @combatants.empty?
      (0...@combatants.length).each do |i|
        if id == @combatants[i].id
          dropped = @combatants.delete_at(i)
          break
        end
      end
    end
    dropped
  end

  # Returns a string representing the current state
  def state_s
    combatants_strings = @combatants.map(&:to_s)
    "Round #{@round} of #{@name}\n#{combatants_strings.join("\n")}"
  end

  def self.get_turn_ordered(combatants)
    initiatives = {}
    combatants.each do |combatant|
      initiatives[combatant] = combatant.roll_initiative
    end
    combatants.sort do |a, b|
      initiatives[b] <=> initiatives[a]
    end
  end

  def to_hash
    {
      name: @name,
      combatants: @combatants.map(&:to_hash),
      user_id: @user_id
    }
  end

  def to_json
    JSON.generate(to_hash)
  end

  def self.from_json(json)
    hash = JSON.parse(json)
    combatants = hash['combatants'].map do |combatant_hash|
      Combatant.from_hash(combatant_hash)
    end
    CombatManager.new hash['name'], combatants, hash['user_id']
  end

  def json_filename
    "#{@user_id}_#{@name}.json"
  end
end
