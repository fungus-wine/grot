# frozen_string_literal: true

require 'grot/keyboard/module_base'

module Grot
  module Keyboard
    module Modules
      class KeyState < ModuleBase
        VALID_KEY_STATES = [:pressed, :down, :released, :up].freeze

        def initialize(options = {})
          super
          @key_states = {}  # Main hash to track active key states
        end

        def handle_event(event)
          key = event.key_code
          if event.key_down?
            @key_states[key] = { key_status: :pressed, timestamp: event.timestamp }
          elsif event.key_up?
            @key_states[key] = { key_status: :released }
          end
          
          return event  # Always pass event to the next module
        end

        def on_update(delta_time)
          @key_states.each do |key, state|
            case state[:key_status]
            when :pressed
              state[:key_status] = :down    # Fresh press becomes down
            when :released
              state[:key_status] = :up       # Released becomes up
            end
          end
        end

        def pressed?(key)
          @key_states[key]&.[](:key_status) == :pressed
        end

        def down?(key)
          @key_states[key]&.[](:key_status) == :down
        end

        def released?(key)
          @key_states[key]&.[](:key_status) == :released
        end

        def up?(key)
          @key_states[key]&.[](:key_status) == :up || !@key_states.key?(key) 
        end

        def press_duration(key)
          if @key_states[key] && [:pressed, :down].include?(@key_states[key][:key_status])
            Time.now.to_f - @key_states[key][:timestamp]
          else
            0.0
          end
        end

        def on_reset
          @key_states.clear
        end

        def keys_in_state(state)
          @key_states.select { |_, s| s[:key_status] == state }.keys
        end

        def active_keys
          @key_states.keys
        end

      end
    end
  end
end