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

  def self.file_regex(user_id)
    %r{\A#{user_id}_([^\/\\\?%\*:|"<>]+).json\z}
  end

  command(
    :combat,
    description: "Allows access to combat functions (Try `#{@prefix}combat help` for more details).",
    permission_level: 0
  ) do |msg, action, *args|
    HyenaLogger.log_user(msg.author, 'issued combat command.')
    user_id = msg.author.id
    name = args.join(' ')
    if action == 'help'
      msg.respond(
        <<~HELP_TEXT
          The `combat` commands allows you to create and save combat scenarios for easy initiative handling. Valid names consist of letters, numbers, spaces, and underscores. It can be used as follows:
            `new <name>` - Start a new combat scenario with the specified name, saving and leaving your old one.
            `rename <new name>` or `mv <new name>` - Rename the current combat scenario
            `open <name>` or `op <name>` - Open the combat scenario with the specified name
            `delete` or `del` - Permanently delete your active scenario
            `scenarios` or `ls` - View a list of all your saved scenarios
            `close` - Closes and saves the current combat scenario
            `add <initiative> <name> [\# of duplicates (default 1)]` - Adds characters to your scenario
            `edit <id> <new initiative> <new name>` - Assigns the specified name and initiative to an existing combatant
            `remove <id>` or `rm <id>` - Removes the specified combatant from combat
            `run` or `r` - Proceed your combat scenario to the next round and display turn order
            `status` or `stat` - Print the name and current status of your combat scenario
        HELP_TEXT
      )
      HyenaLogger.log_user(msg.author, 'listed combat command options.')
    elsif action == 'new'
      if JSONManager.valid_filename?(name)
        old_manager = @scenario_hash[user_id]
        JSONManager.write_json('scenarios', old_manager.json_filename, old_manager.to_json) if old_manager
        new_manager = CombatManager.new name, [], user_id
        @scenario_hash[user_id] = new_manager
        msg.respond("Successfully created new scenario called: #{name}")
        HyenaLogger.log_user(msg.author, "created new combat scenario called: #{name}")
        JSONManager.write_json('scenarios', new_manager.json_filename, new_manager.to_json)
      else
        msg.respond("#{msg.author.username}, \"#{name}\" is not a valid name.")
        HyenaLogger.log_user(msg.author, "attempted and failed to created an improperly named new combat scenario called: #{name}")
      end
    elsif %w[rename mv].include?(action)
      manager = @scenario_hash[user_id]
      if !manager
        msg.respond("#{msg.author.username}, you do not have a combat scenario open.")
        HyenaLogger.log_user(msg.author, 'attempted to rename their nonexistant combat scenario.')
      elsif JSONManager.valid_filename?(name)
        JSONManager.delete_json('scenarios', manager.json_filename)
        manager.name = name
        msg.respond("Successfully renamed scenario to: #{name}")
        HyenaLogger.log_user(msg.author, "renamed their combat scenario called: #{name}")
        JSONManager.write_json('scenarios', manager.json_filename, manager.to_json)
      else
        msg.respond("#{msg.author.username}, \"#{name}\" is not a valid name.")
        HyenaLogger.log_user(msg.author, "attempted and failed to rename their active combat scenario to the invalid name: #{name}")
      end
    elsif %w[open op].include?(action)
      if JSONManager.valid_filename?(name) && JSONManager.exist?('scenarios', "#{user_id}_#{name}.json")
        old_manager = @scenario_hash[user_id]
        JSONManager.write_json('scenarios', old_manager.json_filename, old_manager.to_json) if old_manager
        @scenario_hash[user_id] = CombatManager.from_json(JSONManager.read_json('scenarios', "#{user_id}_#{name}.json"))
        msg.respond("#{msg.author.username}, you have opened #{name}.")
        HyenaLogger.log_user(msg.author, "opened the scenario #{name}.")
      else
        msg.respond("#{msg.author.username}, \"#{name}\" is not a scenario.")
        HyenaLogger.log_user(msg.author, 'attempted to open a nonexistant scenario.')
      end
    elsif %w[delete del].include?(action)
      manager = @scenario_hash[user_id]
      if manager
        JSONManager.delete_json('scenarios', manager.json_filename)
        JSONManager.write_json('scenarios', 'deleted_' + manager.json_filename, manager.to_json)
        msg.respond("#{msg.author.username}, you deleted your scenario #{manager.name}")
        HyenaLogger.log_user(msg.author, "deleted their scenario #{manager.name}")
        @scenario_hash[user_id] = nil
      else
        msg.respond("#{msg.author.username}, you did not have a scenario open.")
        HyenaLogger.log_user(msg.author, 'attempted to close their scenario but had none open.')
      end
    elsif %w[scenarios ls].include?(action)
      names = JSONManager.search('scenarios', file_regex(user_id))
      msg.respond("#{msg.author.username} has the following scenarios:```\n#{names.join("\n")}```")
      HyenaLogger.log_user(msg.author, 'listed their scenarios.')
    elsif action == 'close'
      manager = @scenario_hash[user_id]
      if manager
        JSONManager.write_json('scenarios', manager.json_filename, manager.to_json)
        msg.respond("#{msg.author.username}, you have saved and closed your scenario #{manager.name}")
        HyenaLogger.log_user(msg.author, "closed their scenario #{manager.name}")
        @scenario_hash[user_id] = nil
      else
        msg.respond("#{msg.author.username}, you did not have a scenario open.")
        HyenaLogger.log_user(msg.author, 'attempted to close their scenario but had none open.')
      end
    elsif action == 'add'
      manager = @scenario_hash[user_id]
      if manager
        if args.length < 2
          msg.respond('Please input the initiative and name.')
          HyenaLogger.log_user(msg.author, 'attempted to add a combatant to their scenario but gave invalid arguments.')
          return
        end
        initiative = args.shift
        last_arg = args.pop
        amount = 1
        if last_arg =~ /\d+/
          amount = last_arg.to_i unless last_arg.to_i > 10
        else
          args.push(last_arg)
        end
        name = args.join(' ')
        if JSONManager.valid_filename?(name) && initiative =~ /\A-?\d+\z/
          amount.times do
            manager.combatants.push(Combatant.new(name, initiative.to_i))
          end
          msg.respond("#{msg.author.username}, your combatants have been added.")
          HyenaLogger.log_user(msg.author, 'added combatants to their scenario.')
        else
          msg.respond("#{msg.author.username}, those are not valid names.")
          HyenaLogger.log_user(msg.author, 'attempted to add a combatant to their scenario but gave invalid arguments.')
        end
      else
        msg.respond("#{msg.author.username}, you do not have a scenario open.")
        HyenaLogger.log_user(msg.author, 'attempted to add a combatant to their scenario but had none open.')
      end
    elsif action == 'edit'
      manager = @scenario_hash[user_id]
      id_s = args.shift
      initiative_s = args.shift
      name = args.join(' ')
      if manager
        if id_s =~ /\A\d+\z/ && initiative_s =~ /\A-?\d+\z/ && JSONManager.valid_filename?(name)
          id = id_s.to_i
          popped = manager.pop_combatant(id)
          if popped
            popped.name = name
            popped.initiative = initiative_s.to_i
            manager.combatants.push(popped)
            msg.respond("#{msg.author.username}, your modifications have been made.")
            HyenaLogger.log_user(msg.author, 'modified combatants in their scenario.')
          else
            msg.respond("#{msg.author.username}, your modifications have not been made; there are no combatants in the scenario with that id.")
            HyenaLogger.log_user(msg.author, "gave an id: #{id} not possessed by combatants in their scenario.")
          end
        else
          msg.respond("#{msg.author.username}, those are not valid input.")
          HyenaLogger.log_user(msg.author, 'attempted to modify a combatant in their scenario but gave invalid arguments.')
        end
      else
        msg.respond("#{msg.author.username}, you do not have a scenario open.")
        HyenaLogger.log_user(msg.author, 'attempted to modify a combatant in their scenario but had no scenario open.')
      end
    elsif %w[remove rm].include?(action)
      manager = @scenario_hash[user_id]
      if manager
        if args[0] =~ /\A\d+\z/
          id = args[0].to_i
          if manager.pop_combatant(id)
            msg.respond("#{msg.author.username}, your deletion has been made.")
            HyenaLogger.log_user(msg.author, 'deleted a combatant in their scenario.')
          else
            msg.respond("#{msg.author.username}, your modifications have not been made; there are no combatants in the scenario with that id.")
            HyenaLogger.log_user(msg.author, "gave an id #{id} not possessed by combatants in their scenario.")
          end
        else
          msg.respond("#{msg.author.username}, those are not valid input.")
          HyenaLogger.log_user(msg.author, 'attempted to delete a combatant in their scenario but gave an invalid id.')
        end
      else
        msg.respond("#{msg.author.username}, you do not have a scenario open.")
        HyenaLogger.log_user(msg.author, 'attempted to delete a combatant in their scenario but had none open.')
      end
    elsif %w[run r].include?(action)
      manager = @scenario_hash[user_id]
      if manager
        manager.next_round
        msg.respond(manager.state_s)
        HyenaLogger.log_user(msg.author, "ran their scenario #{manager.name}")
      else
        msg.respond("#{msg.author.username}, you do not have a scenario open.")
        HyenaLogger.log_user(msg.author, 'attempted to run their scenario but had none open.')
      end
    elsif %w[status stat].include?(action)
      manager = @scenario_hash[user_id]
      if manager
        msg.respond(manager.state_s)
        HyenaLogger.log_user(msg.author, "displayed the current state of their combat scenario: #{manager.name}")
      else
        msg.respond("You do not have an active combat scenario, #{msg.author.username}.")
        HyenaLogger.log_user(msg.author, 'tried to view the state of their combat scenario, but had none.')
      end
    else
      msg.respond("#{msg.author.username}, that is not a valid action.")
      HyenaLogger.log_user(msg.author, "attempted to call the undefined combat action: combat #{action}")
    end
    nil
  end
end
