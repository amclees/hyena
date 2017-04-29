# frozen_string_literal: false

require 'test/unit'
require_relative '../json_manager.rb'
require_relative '../combat/combat_manager.rb'
require_relative '../combat/combatant.rb'

# Tests the JSONManager with combat objects
class TestPersistance < Test::Unit::TestCase
  def setup
    JSONManager.init('data')
  end

  def test_combat_storage
    c1 = Combatant.new 'Elf', 2
    c2 = Combatant.new 'Best Tester', 25
    combat_manager = CombatManager.new 'Test', [c1, c2], 0

    JSONManager.write_json('combatants', c1.json_filename, c1.to_json)
    JSONManager.write_json('combatants', c2.json_filename, c2.to_json)
    JSONManager.write_json('scenarios', combat_manager.json_filename, combat_manager.to_json)

    c1_from_json = Combatant.from_json(JSONManager.read_json('combatants', c1.json_filename))
    assert_equal(c1.name, c1_from_json.name)
    assert_equal(c1.initiative, c1_from_json.initiative)
    c2_from_json = Combatant.from_json(JSONManager.read_json('combatants', c2.json_filename))
    assert_equal(c2.name, c2_from_json.name)
    assert_equal(c2.initiative, c2_from_json.initiative)

    combat_manager_from_json = CombatManager.from_json(JSONManager.read_json('scenarios', combat_manager.json_filename))
    combat_manager_from_json.next_round
    assert_equal(1, combat_manager_from_json.round)
    puts combat_manager_from_json.state_s
  end
end
