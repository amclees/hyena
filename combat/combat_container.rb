# frozen_string_literal: false

require_relative '../json_manager.rb'
require_relative '../logger.rb'
require_relative './combat_manager.rb'
require_relative './combatant.rb'

# Command container for the `combat` commands that handle initiative scenarios
module Combat
  extend Discordrb::Commands::CommandContainer

  @prefix = ''
  def self.init(prefix, scenario_hash = {})
    @prefix = prefix
    @scenario_hash = scenario_hash
  end

  def self.scenario_hash
    @scenario_hash
  end

  command(
    :combat,
    description: "Allows access to combat functions (Try `#{@prefix}combat help` for more details).",
    permission_level: 0
  ) do |msg, action, arg1, arg2, arg3|
    HyenaLogger.log("#{msg.author.display_name} (id: #{msg.author.id}) issued combat command.")
    user_id = msg.author.id
    if action == 'help'
      msg.respond(
        <<~HELP_TEXT
          The `combat` commands allows you to create and save combat scenarios for easy initiative handling. Valid names consist of letters, numbers, and underscores. It can be used as follows:
            `new <name>` - Start a new combat scenario with the specified name, saving and leaving your old one.
            `rename <new name>` - Rename the current combat scenario
            `open <name>` - Open the combat scenario with the specified name
            `delete` - Permanently delete your active scenario
            `scenarios` - View a list of all your saved scenarios
            `close` - Closes and saves the current combat scenario
            `add <name> <initiative> [\# of duplicates (default 1)]` - Adds characters to your scenario
            `edit <id> <new name> <new initiative>` - Assigns the specified name and initiative to an existing combatant
            `remove <id>` - Removes the specified combatant from combat
            `run` - Proceed your combat scenario to the next round and display turn order
            `status` - Print the name and current status of your combat scenario
        HELP_TEXT
      )
      HyenaLogger.log("#{msg.author.display_name} (id: #{msg.author.id}) listed combat command options.")
    elsif action == 'new'
      if arg1 =~ /\A\w+\z/
        old_manager = @scenario_hash[user_id]
        JSONManager.write_json('scenarios', old_manager.json_filename, old_manager.to_json) if old_manager
        new_manager = CombatManager.new arg1, [], user_id
        @scenario_hash[user_id] = new_manager
        msg.respond("Successfully created new scenario called: #{arg1}")
        HyenaLogger.log("#{msg.author.display_name} (id: #{msg.author.id}) created new combat scenario called: #{arg1}")
        JSONManager.write_json('scenarios', new_manager.json_filename, new_manager.to_json)
      else
        msg.respond("#{msg.author.display_name}, \"#{arg1}\" is not a valid name.")
        HyenaLogger.log("#{msg.author.display_name} (id: #{msg.author.id}) attempted and failed to created an improperly named new combat scenario called: #{arg1}")
      end
    elsif action == 'rename'
      manager = @scenario_hash[user_id]
      if !manager
        msg.respond("#{msg.author.display_name}, you do not have a combat scenario open.")
        HyenaLogger.log("#{msg.author.display_name} (id: #{msg.author.id}) attempted to rename their nonexistant combat scenario.")
      elsif arg1 =~ /\A\w+\z/
        JSONManager.delete_json('scenarios', manager.json_filename)
        manager.name = arg1
        msg.respond("Successfully renamed scenario to: #{arg1}")
        HyenaLogger.log("#{msg.author.display_name} (id: #{msg.author.id}) renamed their combat scenario called: #{arg1}")
        JSONManager.write_json('scenarios', manager.json_filename, manager.to_json)
      else
        msg.respond("#{msg.author.display_name}, \"#{arg1}\" is not a valid name.")
        HyenaLogger.log("#{msg.author.display_name} (id: #{msg.author.id}) attempted and failed to rename their active combat scenario to the invalid name: #{arg1}")
      end
    elsif action == 'open'
      if arg1 =~ /\A\w+\z/ && JSONManager.exist?('scenarios', "#{user_id}_#{arg1}.json")
        old_manager = @scenario_hash[user_id]
        JSONManager.write_json('scenarios', old_manager.json_filename, old_manager.to_json) if old_manager
        @scenario_hash[user_id] = CombatManager.from_json(JSONManager.read_json('scenarios', "#{user_id}_#{arg1}.json"))
        msg.respond("#{msg.author.display_name}, you have opened #{arg1}.")
        HyenaLogger.log("#{msg.author.display_name} (id: #{msg.author.id}) opened the scenario #{arg1}.")
      else
        msg.respond("#{msg.author.display_name}, \"#{arg1}\" is not a valid scenario.")
        HyenaLogger.log("#{msg.author.display_name} (id: #{msg.author.id}) attempted to open a nonexistant scenario.")
      end
    elsif action == 'delete'
      manager = @scenario_hash[user_id]
      if manager
        JSONManager.delete_json('scenarios', manager.json_filename)
        JSONManager.write_json('scenarios', 'deleted_' + manager.json_filename, manager.to_json)
        msg.respond("#{msg.author.display_name}, you deleted your scenario #{manager.name}")
        HyenaLogger.log("#{msg.author.display_name} deleted their scenario #{manager.name}")
        @scenario_hash[user_id] = nil
      else
        msg.respond("#{msg.author.display_name}, you did not have a scenario open.")
        HyenaLogger.log("#{msg.author.display_name} attempted to close their scenario but had none open.")
      end
    elsif action == 'scenarios'
      file_regex = /\A#{user_id}_(\w+).json\z/
      names = JSONManager.search('scenarios', file_regex)
      msg.respond("#{msg.author.display_name} has the following scenarios:```\n#{names.join("\n")}```")
      HyenaLogger.log("#{msg.author.display_name} (id: #{msg.author.id}) listed their scenarios.")
    elsif action == 'close'
      manager = @scenario_hash[user_id]
      if manager
        JSONManager.write_json('scenarios', manager.json_filename, manager.to_json)
        msg.respond("#{msg.author.display_name}, you have saved and closed your scenario #{manager.name}")
        HyenaLogger.log("#{msg.author.display_name} closed their scenario #{manager.name}")
        @scenario_hash[user_id] = nil
      else
        msg.respond("#{msg.author.display_name}, you did not have a scenario open.")
        HyenaLogger.log("#{msg.author.display_name} attempted to close their scenario but had none open.")
      end
    elsif action == 'add'
      manager = @scenario_hash[user_id]
      if manager
        if arg1 =~ /\A\w+\z/ && arg2 =~ /\A-?\d+\z/
          amount = arg3 =~ /\A\d+\z/ ? arg3.to_i : 1
          amount = 1 if amount > 10
          amount.times do
            manager.combatants.push(Combatant.new(arg1, arg2.to_i))
          end
          msg.respond("#{msg.author.display_name}, your combatants have been added.")
          HyenaLogger.log("#{msg.author.display_name} added combatants to their scenario.")
        else
          msg.respond("#{msg.author.display_name}, those are not valid names.")
          HyenaLogger.log("#{msg.author.display_name} attempted to add a combatant to their scenario but gave invalid arguments.")
        end
      else
        msg.respond("#{msg.author.display_name}, you do not have a scenario open.")
        HyenaLogger.log("#{msg.author.display_name} attempted to add a combatant to their scenario but had none open.")
      end
    elsif action == 'edit'
      manager = @scenario_hash[user_id]
      if manager
        if arg1 =~ /\A\d+\z/ && arg2 =~ /\A\w+\z/ && arg3 =~ /\A-?\d+\z/
          id = arg1.to_i
          popped = manager.pop_combatant(id)
          if popped
            popped.name = arg2
            popped.initiative = arg3.to_i
            manager.combatants.push(popped)
            msg.respond("#{msg.author.display_name}, your modifications have been made.")
            HyenaLogger.log("#{msg.author.display_name} modified combatants in their scenario.")
          else
            msg.respond("#{msg.author.display_name}, your modifications have not been made; there are no combatants in the scenario with that id.")
            HyenaLogger.log("#{msg.author.display_name} gave an id not possessed by combatants in their scenario.")
          end
        else
          msg.respond("#{msg.author.display_name}, those are not valid input.")
          HyenaLogger.log("#{msg.author.display_name} attempted to modify a combatant in their scenario but gave invalid arguments.")
        end
      else
        msg.respond("#{msg.author.display_name}, you do not have a scenario open.")
        HyenaLogger.log("#{msg.author.display_name} attempted to modify a combatant in their scenario but had none open.")
      end
    elsif action == 'remove'
      manager = @scenario_hash[user_id]
      if manager
        if arg1 =~ /\A\d+\z/
          id = arg1.to_i
          if manager.pop_combatant(id)
            msg.respond("#{msg.author.display_name}, your deletion has been made.")
            HyenaLogger.log("#{msg.author.display_name} deleted a combatant in their scenario.")
          else
            msg.respond("#{msg.author.display_name}, your modifications have not been made; there are no combatants in the scenario with that id.")
            HyenaLogger.log("#{msg.author.display_name} gave an id not possessed by combatants in their scenario.")
          end
        else
          msg.respond("#{msg.author.display_name}, those are not valid input.")
          HyenaLogger.log("#{msg.author.display_name} attempted to delete a combatant in their scenario but gave an invalid id.")
        end
      else
        msg.respond("#{msg.author.display_name}, you do not have a scenario open.")
        HyenaLogger.log("#{msg.author.display_name} attempted to delete a combatant in their scenario but had none open.")
      end
    elsif action == 'run'
      manager = @scenario_hash[user_id]
      if manager
        manager.next_round
        msg.respond(manager.state_s)
        HyenaLogger.log("#{msg.author.display_name} ran their scenario #{manager.name}")
      else
        msg.respond("#{msg.author.display_name}, you do not have a scenario open.")
        HyenaLogger.log("#{msg.author.display_name} attempted to run their scenario but had none open.")
      end
    elsif action == 'status'
      manager = @scenario_hash[user_id]
      if manager
        msg.respond(manager.state_s)
        HyenaLogger.log("#{msg.author.display_name} (id: #{msg.author.id}) displayed the current state of their combat scenario: #{manager.name}")
      else
        msg.respond("You do not have an active combat scenario, #{msg.author.display_name}.")
        HyenaLogger.log("#{msg.author.display_name} (id: #{msg.author.id}) tried to view the state of their combat scenario, but had none.")
      end
    else
      msg.respond("#{msg.author.display_name}, that is not a valid action.")
      HyenaLogger.log("#{msg.author.display_name} (id: #{msg.author.id}) attempted to call the undefined combat action: combat #{action}")
    end
    nil
  end
end
