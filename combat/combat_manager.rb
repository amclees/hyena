require 'json'
require_relative '../dice.rb'

class CombatManager
  attr_reader :combatants, :round, :name, :id
  @@pool = 0

  def initialize(name, combatants)
    @name = name
    @combatants = combatants
    @round = 0
    @id = @@pool
    @@pool += 1
  end

  def next_round
    @combatants = CombatManager.get_turn_ordered(@combatants)
    @round += 1
  end

  def pop_combatant(id)
    dropped = nil
    unless @combatants.empty?
      for i in (0...@combatants.length) do
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
    combatants_strings = @combatants.map { |combatant| combatant.to_s }
    "Round #{@round}\n#{combatants_strings.join("\n")}"
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
      :name => @name,
      :combatants => @combatants.map { |combatant| combatant.to_hash }
    }
  end

  def to_json
    JSON.generate(to_hash)
  end

  def self.from_json(json)
    hash = JSON.parse(json)
    combatants = hash["combatants"].map { |combatant_hash| Combatant.from_hash(combatant_hash) }
    CombatManager.new hash["name"], combatants
  end
end
