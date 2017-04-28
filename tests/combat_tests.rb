# frozen_string_literal: false

require 'test/unit'
require_relative '../combat/combatant.rb'
require_relative '../combat/combat_manager.rb'

class CombatantTest < Test::Unit::TestCase
  def test_initiative
    puts
    tests_amount = 3000
    c1 = Combatant.new "Tester", 12
    c2 = Combatant.new "Goblin", -1

    c1_avg = 0
    c2_avg = 0
    (0...tests_amount).each do
      c1_roll = c1.roll_initiative
      c2_roll = c2.roll_initiative
      assert_true((13..33) === c1_roll)
      assert_true((0..20) === c2_roll)
      c1_avg += c1_roll
      c2_avg += c2_roll
    end
    c1_avg /= tests_amount
    c2_avg /= tests_amount
    assert_true((20..25) === c1_avg)
    assert_true((7..12) === c2_avg)
    puts "#{c1.to_s} avg #{c1_avg}"
    puts "#{c2.to_s} avg #{c2_avg}"
  end

  def test_json
    puts
    c1 = Combatant.from_json("{ \"name\": \"Tester\", \"initiative\": 12 }")
    puts c1.to_s
    assert_equal(c1.name, "Tester")
    assert_equal(c1.initiative, 12)

    c2 = Combatant.new "Goblin", -1
    json = c2.to_json
    puts json
    assert_equal(json, "{\"name\":\"Goblin\",\"initiative\":-1}")
  end

  def test_hash
    c1 = Combatant.from_hash({ :name => "Tester", :initiative => 12 })
    assert_equal(c1.name, "Tester")
    assert_equal(c1.initiative, 12)

    c2 = Combatant.new "Goblin", -1
    hash = c2.to_hash
    assert_equal(hash, { :name => "Goblin", :initiative => -1 })
  end
end

class CombatManagerTest < Test::Unit::TestCase
  class PureInitiativeCombatant < Combatant
    def roll_initiative
      @last_roll = @initiative
    end
  end

  def test_initiative_order
    puts
    c1 = PureInitiativeCombatant.new "Goblin", -1
    c2 = PureInitiativeCombatant.new "Rock", 0
    c3 = PureInitiativeCombatant.new "Elf", 2
    c4 = PureInitiativeCombatant.new "Tester", 12
    encounter = [c1, c2, c3, c4]
    ordered = CombatManager.get_turn_ordered(encounter)
    for i in (0...ordered.length) do
      combatant = ordered[i]
      puts combatant.to_s
      assert_equal(eval("c#{4 - i}"), combatant)
      assert_equal(eval("c#{4 - i}.initiative"), combatant.last_roll.floor)
    end
  end

  def test_manager_states
    puts
    c1 = Combatant.new "Elf", 2
    c2 = Combatant.new "Best Tester", 25
    combat_manager = CombatManager.new "Test", [c1, c2], 0
    combat_manager.next_round
    puts combat_manager.state_s
    assert_equal(1, combat_manager.round)

    for i in 2..100 do
      combat_manager.next_round
      assert_equal(i, combat_manager.round)
    end

    # Begin emptying combatants
    assert_equal(c2, combat_manager.combatants[0])
    assert_equal(c1, combat_manager.pop_combatant(c1.id))
    assert_equal(1, combat_manager.combatants.length)
    assert_equal(c2, combat_manager.pop_combatant(c2.id))
    assert_true(combat_manager.combatants.empty?)
  end

  def test_manager_json
    puts
    test_json = "{\"name\":\"Test\",\"combatants\":[{\"name\":\"Goblin\",\"initiative\":-1},{\"name\":\"Tester\",\"initiative\":12}]}"
    manager_from_json = CombatManager.from_json(test_json)
    assert_equal("Test", manager_from_json.name)
    manager_from_json.next_round
    puts manager_from_json.state_s
    assert_equal(1, manager_from_json.round)

    for i in 2..100 do
      manager_from_json.next_round
      assert_equal(i, manager_from_json.round)
    end
    assert_true(!manager_from_json.combatants.empty?)

    assert_equal("{\"name\":\"Test\",\"combatants\":[{\"name\":\"Tester\",\"initiative\":12},{\"name\":\"Goblin\",\"initiative\":-1}]}", manager_from_json.to_json)
  end
end
