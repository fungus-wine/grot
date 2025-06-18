# frozen_string_literal: true

require_relative '../config_registry'
require 'grot/keyboard/key_constants'

module Grot
  module Config
    module Defaults
      module KeyboardDefaults
        def self.load_defaults(registry = ConfigRegistry.instance)
          # Define keyboard-related categories
          registry.define_category(:keyboard, "Keyboard system configuration")
          registry.define_category(:keyboard_key_state, "Key state tracking configuration")
          registry.define_category(:keyboard_debouncer, "Key repeat and debouncing configuration")
          registry.define_category(:keyboard_mac_adapter, "macOS-specific keyboard adaptations")
          registry.define_category(:keyboard_linux_adapter, "Linux-specific keyboard adaptations")
          registry.define_category(:keyboard_stuck_key_fixer, "Stuck key detection and fixing")
          registry.define_category(:keyboard_buffer, "Keyboard event buffering")
          
          # Main keyboard configuration
          load_main_keyboard_config(registry)
          
          # Module-specific configurations
          load_key_state_config(registry)
          load_debouncer_config(registry)
          load_platform_adapter_config(registry)
          load_stuck_key_config(registry)
          load_buffer_config(registry)
        end
        
        def self.load_main_keyboard_config(registry)
          registry.add_option(
            :keyboard,
            :auto_load_modules,
            :boolean,
            true,
            "Automatically load keyboard modules on startup"
          )
        end
        
        def self.load_key_state_config(registry)
          registry.add_option(
            :keyboard_key_state,
            :enabled, 
            :boolean,
            true,
            "Enable the key state tracking module"
          )
          
          registry.add_option(
            :keyboard_key_state,
            :priority,
            :integer,
            90,
            "Processing priority for the key state module (higher numbers = higher priority)"
          )
        end
        
        def self.load_debouncer_config(registry)
          registry.add_option(
            :keyboard_debouncer,
            :enabled,
            :boolean, 
            true,
            "Enable key repeat and debouncing module"
          )
          
          registry.add_option(
            :keyboard_debouncer,
            :priority, 
            :integer,
            60,
            "Processing priority for the debouncer module"
          )
          
          registry.add_option(
            :keyboard_debouncer,
            :repeat_delay,
            :float,
            0.5,
            "Initial delay in seconds before key repeating begins"
          )
          
          registry.add_option(
            :keyboard_debouncer,
            :repeat_rate,
            :float,
            0.05,
            "Time in seconds between repeat events (20Hz = 0.05)"
          )
          
          registry.add_option(
            :keyboard_debouncer,
            :arrow_keys_repeat_delay,
            :float,
            0.3,
            "Initial delay in seconds before arrow keys start repeating"
          )
          
          registry.add_option(
            :keyboard_debouncer,
            :arrow_keys_repeat_rate,
            :float,
            0.12,
            "Time in seconds between arrow key repeat events"
          )
          
          registry.add_option(
            :keyboard_debouncer,
            :navigation_keys_repeat_delay,
            :float,
            0.4,
            "Initial delay in seconds before navigation keys (page up/down, home, end) start repeating"
          )
          
          registry.add_option(
            :keyboard_debouncer,
            :navigation_keys_repeat_rate,
            :float,
            0.15,
            "Time in seconds between navigation key repeat events"
          )
        end
        
        def self.load_platform_adapter_config(registry)
          registry.add_option(
            :keyboard_mac_adapter,
            :enabled,
            :boolean,
            Grot::Keyboard::KeyConstants.platform == :macos,
            "Enable macOS-specific keyboard adaptations"
          )
          
          registry.add_option(
            :keyboard_mac_adapter,
            :priority,
            :integer,
            70,
            "Processing priority for the macOS adapter module"
          )
          
          registry.add_option(
            :keyboard_mac_adapter,
            :command_fix,
            :boolean,
            true,
            "Enable fixes for Command key behavior"
          )
          
          registry.add_option(
            :keyboard_linux_adapter,
            :enabled,
            :boolean,
            Grot::Keyboard::KeyConstants.platform == :linux,
            "Enable Linux-specific keyboard adaptations"
          )
          
          registry.add_option(
            :keyboard_linux_adapter,
            :priority,
            :integer,
            71,
            "Processing priority for the Linux adapter module"
          )
          
          registry.add_option(
            :keyboard_linux_adapter,
            :fix_window_manager_conflicts,
            :boolean,
            true,
            "Enable fixes for window manager key conflicts"
          )
        end
        
        def self.load_stuck_key_config(registry)
          registry.add_option(
            :keyboard_stuck_key_fixer,
            :enabled,
            :boolean,
            true,
            "Enable detection and fixing of stuck keys"
          )
          
          registry.add_option(
            :keyboard_stuck_key_fixer,
            :priority,
            :integer,
            50,
            "Processing priority for the stuck key fixer module"
          )
          
          registry.add_option(
            :keyboard_stuck_key_fixer,
            :auto_release_delay,
            :float,
            1.0,
            "Time in seconds after which a key is considered 'stuck' and automatically released"
          )
        end
        
        def self.load_buffer_config(registry)
          registry.add_option(
            :keyboard_buffer,
            :enabled,
            :boolean,
            true,
            "Enable keyboard event buffering"
          )
          
          registry.add_option(
            :keyboard_buffer,
            :priority,
            :integer,
            80,
            "Processing priority for the buffer module"
          )
          
          registry.add_option(
            :keyboard_buffer,
            :buffer_time,
            :float,
            0.01,
            "Minimum time in seconds between key events (for debouncing)"
          )
        end
      end
    end
  end
end

# Load the defaults when this file is required
Grot::Config::Defaults::KeyboardDefaults.load_defaults