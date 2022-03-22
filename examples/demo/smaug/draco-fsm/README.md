# Draco FSM

> Enhances Draco::Entity using a finite state machine

## Overview

A simple entity state machine.

```ruby
class Player < Draco::Entity
  include Draco::FSM

  # Use the `fsm` block to describe your state machine, and pass the `initial`
  # option to set the state that each new instance should start in.
  fsm initial: :standing do

    # Declare each valid state of your entity
    state :standing

    # You can also declare several states on one line
    state :walking, :running

    state :jumping do |event, payload|
      # If you provide a block, it will be run as a callback
      # whenever the entity enters this state.
    end

    # You can also add the same callback to several states
    state :sitting, :sleeping do |event, payload|
      # ...
    end

    # Or use the reserved state name `:any`
    state :any do |event, payload|
      # ...
    end

    # Next you need to declare your events and transitions
    event :jump do
      #transitions from: :standing, to: :jumping
      #transitions from: :running, to: :jumping

      # You can also group these transitions, like this...
      transitions from: [:standing, :running], to: :jumping
    end

    event :run do
      transitions from: :standing, to: :running
    end
  end
end
```

This adds several features to each instance of this entity.

```ruby
  player = Player.new

  # Current state
  player.state # => :standing
  player.standing? # => true

  # All possible states
  player.states # => [:standing, :walking, :running, :jumping, :sitting, :sleeping]

  # All possible events
  player.events # => [:jump, :run]

  # All events that can be triggered from the current state
  player.triggerable_events # => [:jump, :run]

  # Add an additional callback to run when entering a state
  player.on(:walking) do
    puts "Walking..."
  end

  # Or add an additional callback for any transition
  player.on(:any) { |status, payload| # ... }

  # Check if an event is triggerable from the current state
  player.trigger? :run # => true
  player.run? # => true

  # Trigger an event, resulting in a state transition
  player.trigger :jump
  player.jump

  # You can also provide a data payload, which is passed to every callback
  player.trigger :run, speed: 5
  player.run speed: 5

  # Use a bang! method if you prefer to force an Exception when trying to trigger an event
  # from an unsupported state
  player.trigger! :run
  player.run!

```

When an entity completes a transition, a `Draco::FSM::StateChanged` component is added. You can use this
to manage complex transitions using systems.

```ruby
class StartWalking < Draco::System
  filter Draco::FSM::StateChanged

  def tick args
    entities.each do |player|
      if player.standing?
        player.state_changed.after(3, :seconds) do
          player.walk
        end
      end
    end
  end
end
```

Check the `examples/` directory for a complete demo containing several more examples you can learn from.

---

## Installation

If you don't already have a game project, run `smaug new` to create one.

```bash
$ smaug add draco
$ smaug add draco-fsm
```

```ruby
# app/main.rb
require 'smaug.rb'

def tick args
  args.state.world ||= HelloWorld.new
  args.state.world.tick(args)
end
```

Next, create a World and add an entity.

```ruby
# app/worlds/hello_world.rb
class HelloWorld < Draco::World
  entity Player, as :player
end
```

Finally, define the entity class.

```ruby
# app/entities/player.rb
class Player < Draco::Entity
  include Draco::FSM

  fsm initial: :standing do
    state :standing
    # ...
  end
end
```

Start the game with `smaug run` to see the result.

## Credit

This package contains code originally derived from the following projects under the MIT license:

* https://github.com/ms-ati/docile
* https://github.com/soveran/micromachine
