module Draco
  module FSM
    class NotAnEntityError < StandardError; end

    def self.included(mod)
      raise NotAnEntityError, "Draco::FSM can only be included on Draco::Entity subclasses." unless mod.ancestors.include?(Draco::Entity)

      mod.extend(ClassMethods)
      mod.prepend(EntityPlugin)
    end

    module ClassMethods

      class EventBuilder
        def initialize(event)
          @event = event
          @transitions = {}
        end

        def transitions(options = {})
          from = options[:from]
          from = [from] unless from.is_a? Array
          from.each { |f| @transitions[f] = options[:to] }
        end

        def build(fsm)
          fsm.when(@event, @transitions)
          fsm
        end
      end

      class FsmBuilder
        attr_reader :initial_state

        def initialize(options)
          @initial_state = options[:initial]
          @states = {}
          @events = []
        end

        def build(machine)
          @states.keys.each do |name|
            callback = @states[name]
            machine.on(name, &callback) if callback
          end
          @events.each do |event|
            event.build(machine)
          end
          machine
        end

        def state(*target, &block)
          names = target.is_a?(Array) ? target : [target]
          names.each { |name| @states[name] = block }
        end

        def event(name, &block)
          @events << Docile.dsl_eval(EventBuilder.new(name), &block)
        end
      end

      def fsm(options={}, &block)
        @fsm = Docile.dsl_eval(FsmBuilder.new(options), &block)
      end
    end

    module EntityPlugin
      def after_initialize
        super

        builder = self.class.instance_variable_get(:@fsm)
        
        @fsm = StateMachine.new(builder.initial_state)
        @fsm = builder.build(@fsm)

        on :any do |event, payload|
          tick_count = $gtk.args.state.tick_count
          previous_state = components[:state_changed].to
          state_changed = StateChanged.new from: previous_state, to: state, at: tick_count
          components.add(state_changed)
        end

        state_changed = StateChanged.new to: state, at: $gtk.args.state.tick_count
        components.add(state_changed)
      end

      def state
        @fsm.state
      end

      def events
        @fsm.events
      end

      def states
        @fsm.states
      end

      def on(key, &block)
        @fsm.on(key, &block)
      end

      def trigger(event, payload = nil)
        @fsm.trigger(event, payload)
      end

      def trigger!(event, payload = nil)
        @fsm.trigger!(event, payload)
      end

      def trigger?(event)
        @fsm.trigger?(event)
      end

      def triggerable_events
        @fsm.triggerable_events
      end

      def method_missing(method, *args, &block)
        if method.to_s[-1] == '!'
          method = method.to_s.split('!').first.to_sym
          if events.include?(method)
            return trigger!(method, *args, &block)
          end
        elsif method.to_s[-1] == '?'
          method = method.to_s.split('?').first.to_sym
          if events.include?(method)
            return trigger?(method, *args, &block)
          elsif states.include?(method)
            return state == method
          end
        else
          method = method.to_sym
          if events.include?(method)
            return trigger(method, *args, &block)
          end
        end

        super(method, *args, &block)
      end
    end

    class StateChanged < Draco::Component
      attribute :from
      attribute :to
      attribute :at

      def after(i, unit = nil)
        time = (unit == :seconds) ? i*60 : i
        yield if at.elapsed? time
      end
    end

  end
end
