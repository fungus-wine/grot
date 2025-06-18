# frozen_string_literal: true

require 'grot/keyboard/module_base'
require 'grot/keyboard/key_event'
require 'grot/keyboard/key_constants'


module Grot
  module Keyboard
    module Modules
      class Buffer < ModuleBase

        DEFAULT_DELAY = 0.05  # 50ms debounce

        def initialize(options = {})
          super
          @key_states = {}  # { key_code => { last_time: Time, pressed: Boolean } }
          @delay = options[:delay] || DEFAULT_DELAY
        end

        def handle_event(event)
          return event if !@enabled || event.nil?
          key = event.key_code
          now = Time.now.to_f
          state = @key_states[key] || { last_time: 0, pressed: false }

          if event.key_down?
            unless state[:pressed]
              if now - state[:last_time] >= @delay
                state[:last_time] = now
                state[:pressed] = true
                @key_states[key] = state
                return event
              end
              return nil
            end
            return nil
          elsif event.key_up?
            if state[:pressed]
              state[:pressed] = false
              @key_states[key] = state
              return event
            end
            return nil
          end
          event  # Pass others
        end

        def on_update(delta_time)
          now = Time.now.to_f
          @key_states.delete_if do |key, state|
            if !state[:pressed] && now - state[:last_time] > 1.0
              true
            else
              false
            end
          end
        end

      end
    end
  end
end