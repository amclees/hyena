# frozen_string_literal: false

# ActionContainer is a container where actions can be registered and accessed.
module ActionContainer
  @@actions = {}

  def this.register_action(action, &handler)
    actions[action] = handler
  end

  def this.handle(action, args)
    actions[action].call(args)
  end
end
