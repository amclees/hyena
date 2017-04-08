require 'json'
require_relative '../dice.rb'

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
    @last_roll = Dice.d20.to_f + @initiative.to_f + (Dice.dx(1, 100).to_f / 100.0).round(2)
  end

  def self.from_json(json)
    hash = JSON.parse(json)
    Combatant.new hash["name"], hash["initiative"]
  end

  def to_json
    JSON.generate(to_hash)
  end

  def to_hash
    {
      :name => @name,
      :initiative => @initiative
    }
  end

  def self.from_hash(hash)
    if hash[:name] and hash[:initiative]
      Combatant.new hash[:name], hash[:initiative]
    elsif hash["name"] and hash["initiative"]
      Combatant.new hash["name"], hash["initiative"]
    else
      nil
    end
  end

  def to_s
    "#{name} #{initiative < 0 ? "-" : "+"}#{initiative.abs} (\##{id}) - Initiative: #{last_roll}"
  end
end
