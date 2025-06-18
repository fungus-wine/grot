# frozen_string_literal: true

require 'grot/keyboard/module_base'
require 'grot/keyboard/key_event'
require 'grot/keyboard/key_constants'

module Grot
  module Keyboard
    module Modules
      # Linux-specific adapter to fix Linux keyboard issues in Gosu
      class LinuxAdapter < ModuleBase
        # Keys that commonly have issues on Linux
        PROBLEM_KEYS = [
          Gosu::KB_LEFT_ALT,      # Left Alt key
          Gosu::KB_RIGHT_ALT,     # Right Alt key
          Gosu::KB_TAB,           # Tab key
          Gosu::KB_RETURN         # Return key
        ].freeze
        
        def initialize(options = {})
          super
          # Track modifier keys state
          @modifier_state = {
            shift: { left: false, right: false, time: nil },
            control: { left: false, right: false, time: nil },
            alt: { left: false, right: false, time: nil }
          }
          
          # Track keys pressed with alt (for window manager conflicts)
          @alt_combos = {}
          
          # Configuration
          @fix_window_manager_conflicts = options[:fix_window_manager_conflicts] != false  # Default to true
        end
        
        def handle_event(event)
          # Always track modifier key states
          track_modifier_keys(event)
          
          return event unless @fix_window_manager_conflicts
          
          # Apply Linux-specific Alt key fixes
          fix_alt_key_issues(event)
        end
        
        def on_update(delta_time)
          # No stuck key fixing here; defer to StuckKeyFixer
        end
        
        def on_reset
          # Clear all tracking state
          @modifier_state.each do |_, states|
            states[:left] = false
            states[:right] = false
            states[:time] = nil
          end
          @alt_combos.clear
        end
        
        private
        
        def track_modifier_keys(event)
          # Track shift keys
          track_specific_modifier(event, :shift, Gosu::KB_LEFT_SHIFT, Gosu::KB_RIGHT_SHIFT)
          
          # Track control keys
          track_specific_modifier(event, :control, Gosu::KB_LEFT_CONTROL, Gosu::KB_RIGHT_CONTROL)
          
          # Track alt keys
          track_specific_modifier(event, :alt, Gosu::KB_LEFT_ALT, Gosu::KB_RIGHT_ALT)
          
          # Track keys pressed while alt is down
          if event.key_down? && alt_key_down?
            unless [Gosu::KB_LEFT_ALT, Gosu::KB_RIGHT_ALT].include?(event.key_code)
              @alt_combos[event.key_code] = event.timestamp
            end
          elsif event.key_up? && @alt_combos[event.key_code]
            @alt_combos.delete(event.key_code)
          end
        end
        
        def track_specific_modifier(event, modifier_name, left_key, right_key)
          modifier = @modifier_state[modifier_name]
          
          if event.key_down?
            if event.key_code == left_key
              modifier[:left] = true
              modifier[:time] = event.timestamp
            elsif event.key_code == right_key
              modifier[:right] = true
              modifier[:time] = event.timestamp
            end
          elsif event.key_up?
            if event.key_code == left_key
              modifier[:left] = false
              @alt_combos.clear if modifier_name == :alt
            elsif event.key_code == right_key
              modifier[:right] = false
              @alt_combos.clear if modifier_name == :alt
            end
          end
        end
        
        def alt_key_down?
          @modifier_state[:alt][:left] || @modifier_state[:alt][:right]
        end
        
        def fix_alt_key_issues(event)
          # Monitor Alt+key combos that might conflict with window manager
          if event.key_down? && alt_key_down?
            @alt_combos[event.key_code] = event.timestamp
          elsif event.key_up? && @alt_combos.key?(event.key_code)
            @alt_combos.delete(event.key_code)
          end
          event  # Always pass through
        end
      end
    end
  end
end