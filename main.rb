require 'discordrb'
require_relative './json_manager.rb'
require_relative './hyena_secret.rb'
require_relative './dice.rb'
require_relative './logger.rb'
require_relative './combat/combat_manager.rb'
require_relative './combat/combatant.rb'

Logger.log("Starting up")
bot = Discordrb::Commands::CommandBot.new token: HyenaSecret.bot_token, client_id: HyenaSecret.client_id, prefix: "."
Logger.log("Created bot")

JSONManager.init("data")
scenario_hash = {}

puts "Invite URL is #{bot.invite_url}."

channel_general = 275074190498070530

bot.bucket :file_cmd, limit: 3, time_span: 120, delay: 5

bot.message(content: /(\d*)d(\d*)/i) do |msg|
  pair = msg.content.scan(/(\d*)d(\d*)/i)[0]
  rolls = pair[0].to_i
  sides = pair[1].to_i
  if rolls > 1000
    msg.respond("#{msg.author.display_name}, you can't roll that many dice!")
    Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) attempted to roll a #{rolls}d#{sides} but failed due to too many dice.")
  elsif sides > 10_0000_0000
    msg.respond("#{msg.author.display_name}, you can't roll dice with that many sides!")
    Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) attempted to roll a #{rolls}d#{sides} but failed due to too many sided dice.")
  else
    roll = Dice.dx(rolls, sides)
    msg.respond("#{msg.author.display_name}, you rolled a #{ roll } on a #{rolls}d#{sides}")
    Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) rolled a #{roll} on a #{rolls}d#{sides}")
  end
end

bot.message do |msg|
  Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) said #{msg.content}")
end

bot.command(:exit, help_available: false, permission_level: 100) do |msg|
  Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) issued command to exit.")
  msg.respond("Saving and exiting...")
  Logger.log("Sent exit message")
  scenario_hash.keys.each do |key|
    combat_manager = scenario_hash[key]
    JSONManager.write_json("scenarios", combat_manager.json_filename, combat_manager.to_json)
    Logger.log("Saved scenario #{combat_manager.name} owned by UID #{combat_manager.user_id}")
  end
  sleep(0.1) until not Logger.logging
  Logger.save
  msg.respond("Done saving, exiting now.")
  exit
end

bot.command(:combat, description: "Allows access to combat functions (Try `#{bot.prefix}combat help` for more details).", permission_level: 0) do |msg, action, arg1, arg2, arg3|
  Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) issued combat command.")
  user_id = msg.author.id
  if action == "help"
    msg.respond(
%(The `combat` commands allows you to create and save combat scenarios for easy initiative handling. Valid names consist of letters, numbers, and underscores. It can be used as follows:
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
`status` - Print the name and current status of your combat scenario)
    )
    Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) listed combat command options.")
  elsif action == "new"
    if arg1 =~ /\A\w+\z/
      old_manager = scenario_hash[user_id]
      JSONManager.write_json("scenarios", old_manager.json_filename, old_manager.to_json) if old_manager
      new_manager = CombatManager.new arg1, [], user_id
      scenario_hash[user_id] = new_manager
      msg.respond("Successfully created new scenario called: #{arg1}")
      Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) created new combat scenario called: #{arg1}")
      JSONManager.write_json("scenarios", new_manager.json_filename, new_manager.to_json)
    else
      msg.respond("#{msg.author.display_name}, \"#{arg1}\" is not a valid name.")
      Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) attempted and failed to created an improperly named new combat scenario called: #{arg1}")
    end
  elsif action == "rename" # Deletion broken, TODO fix
    manager = scenario_hash[user_id]
    if !manager
      msg.respond("#{msg.author.display_name}, you do not have a combat scenario open.")
      Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) attempted to rename their nonexistant combat scenario.")
    elsif arg1 =~ /\A\w+\z/
      JSONManager.delete_json("scenarios", manager.json_filename)
      manager.name = arg1
      msg.respond("Successfully renamed scenario to: #{arg1}")
      Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) renamed their combat scenario called: #{arg1}")
      JSONManager.write_json("scenarios", manager.json_filename, manager.to_json)
    else
      msg.respond("#{msg.author.display_name}, \"#{arg1}\" is not a valid name.")
      Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) attempted and failed to rename their active combat scenario to the invalid name: #{arg1}")
    end
  elsif action == "open"
    if arg1 =~ /\A\w+\z/ and JSONManager.exist?("scenarios", "#{user_id}_#{arg1}.json")
      old_manager = scenario_hash[user_id]
      JSONManager.write_json("scenarios", old_manager.json_filename, old_manager.to_json) if old_manager
      scenario_hash[user_id] = CombatManager.from_json(JSONManager.read_json("scenarios", "#{user_id}_#{arg1}.json"))
      msg.respond("#{msg.author.display_name}, you have opened #{arg1}.")
      Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) opened the scenario #{arg1}.")
    else
      msg.respond("#{msg.author.display_name}, \"#{arg1}\" is not a valid scenario.")
      Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) attempted to open a nonexistant scenario.")
    end
  elsif action == "delete"
    manager = scenario_hash[user_id]
    if manager
      JSONManager.delete_json("scenarios", manager.json_filename)
      JSONManager.write_json("scenarios", "deleted_" + manager.json_filename, manager.to_json)
      msg.respond("#{msg.author.display_name}, you deleted your scenario #{manager.name}")
      Logger.log("#{msg.author.display_name} deleted their scenario #{manager.name}")
      scenario_hash[user_id] = nil
    else
      msg.respond("#{msg.author.display_name}, you did not have a scenario open.")
      Logger.log("#{msg.author.display_name} attempted to close their scenario but had none open.")
    end
  elsif action == "scenarios"
    file_regex = /\A#{user_id}_(\w+).json\z/
    names = JSONManager.search("scenarios", file_regex)
    msg.respond("#{msg.author.display_name} has the following scenarios:```diff\n#{names.join("\n")}```")
    Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) listed their scenarios.")
  elsif action == "close"
    manager = scenario_hash[user_id]
    if manager
      JSONManager.write_json("scenarios", manager.json_filename, manager.to_json)
      msg.respond("#{msg.author.display_name}, you have saved and closed your scenario #{manager.name}")
      Logger.log("#{msg.author.display_name} closed their scenario #{manager.name}")
      scenario_hash[user_id] = nil
    else
      msg.respond("#{msg.author.display_name}, you did not have a scenario open.")
      Logger.log("#{msg.author.display_name} attempted to close their scenario but had none open.")
    end
  elsif action == "add"
    manager = scenario_hash[user_id]
    if manager
      if arg1 =~ /\A\w+\z/ && arg2 =~ /\A-?\d+\z/
        amount = 1
        if arg3 =~ /\A\d+\z/
          amount = arg3.to_i unless amount > 25
        end
        for i in (0...amount)
          manager.combatants.push(Combatant.new arg1, arg2.to_i)
        end
        msg.respond("#{msg.author.display_name}, your combatants have been added.")
        Logger.log("#{msg.author.display_name} added combatants to their scenario.")
      else
        msg.respond("#{msg.author.display_name}, those are not valid names.")
        Logger.log("#{msg.author.display_name} attempted to add a combatant to their scenario but gave invalid arguments.")
      end
    else
      msg.respond("#{msg.author.display_name}, you do not have a scenario open.")
      Logger.log("#{msg.author.display_name} attempted to add a combatant to their scenario but had none open.")
    end
  elsif action == "edit"
    manager = scenario_hash[user_id]
    if manager
      if arg1 =~ /\A\d+\z/ && arg2 =~ /\A\w+\z/ && arg3 =~ /\A-?\d+\z/
        id = arg1.to_i
        popped = manager.pop_combatant(id)
        if popped
          popped.name = arg2
          popped.initiative = arg3.to_i
          manager.combatants.push(popped)
          msg.respond("#{msg.author.display_name}, your modifications have been made.")
          Logger.log("#{msg.author.display_name} modified combatants in their scenario.")
        else
          msg.respond("#{msg.author.display_name}, your modifications have not been made; there are no combatants in the scenario with that id.")
          Logger.log("#{msg.author.display_name} gave an id not possessed by combatants in their scenario.")
        end
      else
        msg.respond("#{msg.author.display_name}, those are not valid input.")
        Logger.log("#{msg.author.display_name} attempted to modify a combatant in their scenario but gave invalid arguments.")
      end
    else
      msg.respond("#{msg.author.display_name}, you do not have a scenario open.")
      Logger.log("#{msg.author.display_name} attempted to modify a combatant in their scenario but had none open.")
    end
  elsif action == "remove"
    manager = scenario_hash[user_id]
    if manager
      if arg1 =~ /\A\d+\z/
        id = arg1.to_i
        if manager.pop_combatant(id)
          msg.respond("#{msg.author.display_name}, your deletion has been made.")
          Logger.log("#{msg.author.display_name} deleted a combatant in their scenario.")
        else
          msg.respond("#{msg.author.display_name}, your modifications have not been made; there are no combatants in the scenario with that id.")
          Logger.log("#{msg.author.display_name} gave an id not possessed by combatants in their scenario.")
        end
      else
        msg.respond("#{msg.author.display_name}, those are not valid input.")
        Logger.log("#{msg.author.display_name} attempted to delete a combatant in their scenario but gave an invalid id.")
      end
    else
      msg.respond("#{msg.author.display_name}, you do not have a scenario open.")
      Logger.log("#{msg.author.display_name} attempted to delete a combatant in their scenario but had none open.")
    end
  elsif action == "run"
    manager = scenario_hash[user_id]
    if manager
      manager.next_round
      msg.respond(manager.state_s)
      Logger.log("#{msg.author.display_name} ran their scenario #{manager.name}")
    else
      msg.respond("#{msg.author.display_name}, you do not have a scenario open.")
      Logger.log("#{msg.author.display_name} attempted to run their scenario but had none open.")
    end
  elsif action == "status"
    manager = scenario_hash[user_id]
    if manager
      msg.respond(manager.state_s)
      Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) displayed the current state of their combat scenario: #{manager.name}")
    else
      msg.respond("You do not have an active combat scenario, #{msg.author.display_name}.")
      Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) tried to view the state of their combat scenario, but had none.")
    end
  else
    msg.respond("#{msg.author.display_name}, that is not a valid action.")
    Logger.log("#{msg.author.display_name} (id: #{msg.author.id}) attempted to call the undefined combat action: combat #{action}")
  end
  nil
end

bot.run :async
Logger.log("Bot started")

bot.set_user_permission(125750053309513728, 100)
bot.send_message(channel_general, "**Hello!** I, the *hyena*, have come to roll dice and do other things. Type `#{bot.prefix}help` to see what I can do for you (other than roll dice).\nType `<number of dice>d<sides>` to roll dice. For example, `1d20`, `4d6`, or `1d100`.")
bot.sync
Logger.log("Initialization complete")
