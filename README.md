# Hyena
[![Build Status](https://travis-ci.org/amclees/Hyena.svg?branch=master)](https://travis-ci.org/amclees/Hyena) [![Code Climate](https://codeclimate.com/github/amclees/Hyena/badges/gpa.svg)](https://codeclimate.com/github/amclees/Hyena) [![Test Coverage](https://codeclimate.com/github/amclees/Hyena/badges/coverage.svg)](https://codeclimate.com/github/amclees/Hyena/coverage) [![security](https://hakiri.io/github/amclees/Hyena/master.svg)](https://hakiri.io/github/amclees/Hyena/master)

Hyena is a Discord bot written in Ruby with [discordrb](https://github.com/meew0/discordrb) that provides tools for roleplaying games.

## Installation

1. Install [discordrb](https://github.com/meew0/discordrb). As of now, Hyena does
provide voice features and thus does not require libsodium, libopus, and FFMPEG.

2. Clone this repository

3. Run `$ bundle install` in the location where you cloned this repository (If
  you do not have bundler install, run `$ gem install bundler` first)

4. Create a `config.yml` file based off `config_sample.yml` and put in your bot
token and id (If you don't have them, request them at
[Discord's website](https://discordapp.com/developers/applications/me)).

5. Run Hyena using the following command:
```
$ ruby main.rb
```

If you would like to run Hyena 24/7, look into a VPS ([Digital Ocean](https://www.digitalocean.com/) offers a $5/month plan).

## Features
### Dice
Hyena provides full-featured dice-rolling with standard notation used in tabletop
games.

##### Examples
* Rolling ability scores
  > amclees: 4d6

  > Hyena:
  `3    3    6    2`   

  > amclees, you rolled a :one::four: on a 4d6

  >You rolled a natural :six: :heart_eyes:
* Rolling initiatives for a crowd of 16 goblins (With +1 initiative)
  > amclees: 16d20 *+ 1

  > Hyena:  
  ```21     3      20     20     20     9      3      11     8      4      11     5      12     14     18     21```     

  > amclees, you rolled a :two::zero::zero: on a 16d20*+1

  > You rolled a natural :two::zero: :heart_eyes:

### Turn Order Management
Hyena handles turn order including initiative ties and allows for easy management
of multiple combat scenarios.

#### Example - Making a Scenario
> amclees: .combat new dwarven_embassy

> Hyena: Successfully created new scenario called: dwarven_embassy

> amclees: .combat add Dwarf 1 7

> Hyena: amclees, your combatants have been added.

> amclees: .combat run

> Hyena:
```
Round 1 of dwarven_embassy
Dwarf +1 (#2) - Initiative: 20.77
Dwarf +1 (#3) - Initiative: 12.65
Dwarf +1 (#1) - Initiative: 11.03
Dwarf +1 (#4) - Initiative: 10.8
Dwarf +1 (#7) - Initiative: 10.12
Dwarf +1 (#5) - Initiative: 4.47
Dwarf +1 (#6) - Initiative: 4.1
```

### Session Announcements
Starting a session when all players use Discord can be made much simpler with Hyena.
Hyena will automatically mention everyone, including members playing games specifically.

#### Example - Starting a Session
> amclees: .playing on

> Hyena: @everyone Session starting, get in voice!

> @darksouls_fan Stop playing Dark Souls and join the session.

> @developer_1 Stop playing Atom and join the session.

## Planned Features
#### Long-term
* Player monthly budget and expense planning
* Locational variation handler for prices
* Encounter generation
* Player data and skill checks
* XP calculation
* Treasure splitting calculator
* Treasure generator
* Support for playing audio files in voice

#### Short-term
* Support for names with spaces in combat scenarios
* Direct messaging and multiserver support
* Discord-based viewing of logs
* Commands for setting bot status


More features will come after these planned features, Hyena is still early in development.
