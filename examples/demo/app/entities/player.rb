class Player < Draco::Entity
  include Draco::FSM

  component Tag(:playable)

  fsm initial: :standing do
    state :standing do |event, payload|
      puts "STAND"
    end

    state :walking, :running do |event, payload|
      puts "on event #{event}"
      puts event.inspect
      puts payload.inspect
    end

    state :any do |event|
      puts "ANY EVENT"
    end

    state :jumping

    event :walk do
      transitions from: [:standing, :running], to: :walking
    end

    event :run do
      transitions from: :standing, to: :running
      transitions from: :walking, to: :running
    end

    event :stand do
      transitions from: :walking, to: :standing
      transitions from: :running, to: :standing
    end

    event :jump do
      transitions from: :standing, to: :jumping
    end

  end
end
