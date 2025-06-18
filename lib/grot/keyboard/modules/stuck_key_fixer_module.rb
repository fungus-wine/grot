# frozen_string_literal: true

require 'grot/keyboard/module_base'
require 'grot/keyboard/key_event'
require 'grot/keyboard/key_constants'

module Grot
  module Keyboard
    module Modules
      class StuckKeyFixer < ModuleBase
        DEFAULT_TIMEOUT = 2.0  # 2s timeout

        def initialize(options = {})
          super
          @timeout = options[:timeout] || DEFAULT_TIMEOUT
          @scheduled_releases = {}
        end

        def handle_event(event)
          return event  # Pass through, rely on on_update
        end

        def on_update(delta_time)
          return unless @manager&.key_state
          now = Time.now.to_f
          key_state = @manager.key_state

          key_state.active_keys.each do |key|
            duration = key_state.press_duration(key)
            if duration > 0 && duration >= @timeout
              synthetic_event = KeyEvent.new(KeyEvent::KEY_UP, key, {}, now)
              @manager.process_event(synthetic_event)
            end
          end
        end
      end
    end
  end
end