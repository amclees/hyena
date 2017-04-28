# frozen_string_literal: false

require 'json'
require_relative '../dice.rb'

# Handles data and serialization of combatants in a scenario.
class Combatant
  attr_accessor :name, :initiative, :id, :last_roll
  @@pool = 0

  def initialize(name, initiative)
    @name = name
    @initiative = initiative
    @id = @@pool
    @@pool += 1
    @last_roll = 0.0
  end

  def roll_initiative
    tiebreaker = Dice.dx(1, 100).to_f / 100.0
    @last_roll = (Dice.d20.to_f + @initiative.to_f + tiebreaker).round(2)
  end

  def json_filename
    "#{name}.json"
  end

  def self.from_json(json)
    hash = JSON.parse(json)
    Combatant.new hash['name'], hash['initiative']
  end

  def to_json
    JSON.generate(to_hash)
  end

  def to_hash
    {
      name: @name,
      initiative: @initiative
    }
  end

  def self.from_hash(hash)
    return Combatant.new hash[:name], hash[:initiative] if hash[:name] && hash[:initiative]
    return Combatant.new hash['name'], hash['initiative'] if hash['name'] && hash['initiative']
    nil
  end

  def to_s
    "#{name} #{initiative.negative? ? '-' : '+'}#{initiative.abs} (\##{id}) "\
    "- Initiative: #{last_roll}"
  end
end
