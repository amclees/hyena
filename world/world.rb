# frozen_string_literal: false

# Container that integrates the map, economy, and calendar
class World
  attr_accessor :calendar, :economy, :map

  def initialize(options)
    @calendar = options[:calendar]
    @economy = options[:economy]
    @map = options[:map]
  end
end
