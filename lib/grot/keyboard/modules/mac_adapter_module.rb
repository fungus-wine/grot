# frozen_string_literal: true

require 'grot/keyboard/module_base'
require 'grot/keyboard/key_event'
require 'grot/keyboard/key_constants'
require 'grot/keyboard/mac_utils'

module Grot
  module Keyboard
    module Modules
      # Mac-specific adapter to fix macOS keyboard issues in Gosu
      class MacAdapter < ModuleBase
        def initialize(options = {})
          super
          # Track modifier keys state
          @modifier_state = {
            command: { left: false, right: false, time: nil },
            option: { left: false, right: false, time: nil },
            control: { left: false, right: false, time: nil },
            shift: { left: false, right: false, time: nil }
          }
          
          # Track keys pressed while command is held
          @command_combos = {}
          
          # Configuration
          @command_fix_enabled = options[:command_fix] != false  # Default to true
        end
        
        def handle_event(event)
          # Always track modifier key states
          track_modifier_keys(event)
          
          return event unless @command_fix_enabled
          
          # Apply macOS-specific Command key fixes
          fix_command_key_issues(event)
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
          @command_combos.clear
        end
        
        private
        
        def track_modifier_keys(event)
          # Track command keys (meta keys in Gosu)
          track_specific_modifier(event, :command, Gosu::KB_LEFT_META, Gosu::KB_RIGHT_META)
          
          # Track option keys (alt keys in Gosu)
          track_specific_modifier(event, :option, Gosu::KB_LEFT_ALT, Gosu::KB_RIGHT_ALT)
          
          # Track control keys
          track_specific_modifier(event, :control, Gosu::KB_LEFT_CONTROL, Gosu::KB_RIGHT_CONTROL)
          
          # Track shift keys
          track_specific_modifier(event, :shift, Gosu::KB_LEFT_SHIFT, Gosu::KB_RIGHT_SHIFT)
          
          # Track keys pressed while command is down
          if event.key_down? && command_key_down?
            unless [Gosu::KB_LEFT_META, Gosu::KB_RIGHT_META].include?(event.key_code)
              @command_combos[event.key_code] = event.timestamp
            end
          elsif event.key_up? && @command_combos[event.key_code]
            @command_combos.delete(event.key_code)
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
              @command_combos.clear if modifier_name == :command
            elsif event.key_code == right_key
              modifier[:right] = false
              @command_combos.clear if modifier_name == :command
            end
          end
        end
        
        def command_key_down?
          @modifier_state[:command][:left] || @modifier_state[:command][:right]
        end
        
        def fix_command_key_issues(event)
          # Monitor Command+key combos that macOS might intercept (e.g., Cmd+Q, Cmd+W)
          if event.key_down? && command_key_down?
            @command_combos[event.key_code] = event.timestamp
          elsif event.key_up? && @command_combos.key?(event.key_code)
            @command_combos.delete(event.key_code)
          end
          event  # Always pass through
        end
      end
    end
  end
end