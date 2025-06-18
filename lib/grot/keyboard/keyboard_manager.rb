# frozen_string_literal: true

require 'grot/keyboard/key_event'
require 'grot/keyboard/module_registry'
require 'grot/keyboard/event_bus'
require 'grot/keyboard/key_constants'
require 'grot/keyboard/modules/key_state_module'
require 'grot/keyboard/modules/stuck_key_fixer_module'

module Grot

  module Keyboard
    class KeyboardManager
      attr_reader :registry
      
      def initialize(options = {})
        @keyboard_config = options[:config]&.dig(:keyboard) || {}

        @config = {
          auto_load_modules: options.fetch(:auto_load_modules, @keyboard_config.fetch(:auto_load_modules, true))
        }
        
        @registry = ModuleRegistry.new
        @event_bus = EventBus.new(@registry)
        
        @last_update_time = Time.now.to_f
        
         load_default_modules if @config[:auto_load_modules]
      end
      
      def update(delta_time = nil)
        # Calculate delta time if not provided
        current_time = Time.now.to_f
        delta = delta_time || (current_time - @last_update_time)
        @last_update_time = current_time
        
        # Update all modules
        @event_bus.update_all(delta)
      end
      
      def handle_button_down(key_code, modifiers = {})
        event = KeyEvent.new(KeyEvent::KEY_DOWN, key_code, modifiers)
        process_event(event)
      end
      
      def handle_button_up(key_code, modifiers = {})
        event = KeyEvent.new(KeyEvent::KEY_UP, key_code, modifiers)
        process_event(event)
      end
      
      def process_event(event)
        @event_bus.process_event(event)
      end
      
      def add_module(name, module_instance, options = {})
        # Set priority if specified
        priority = options[:priority] || 0
        module_instance.instance_variable_set(:@priority, priority) if priority
        
        # Connect module to manager
        module_instance.set_manager(self)
        
        # Register with registry
        override = options.fetch(:override, false)
        @registry.register(name, module_instance, override)
        
        module_instance  # Return for method chaining
      end
      
      def remove_module(name)
        @registry.unregister(name)
      end
      
      def get_module(name)
        @registry[name]
      end
      
      # Shutdown and reset
      def shutdown
        @event_bus.shutdown_all
      end
      
      def reset
        @event_bus.reset_all
      end
      
      # Convenience method to access key state module
      # @return [KeyState, nil] The key state module
      def key_state
        get_module(:key_state)
      end
      
      def key_pressed?(key_code)
        key_state&.pressed?(key_code) || false
      end
      
      def key_down?(key_code)
        key_state&.down?(key_code) || false
      end
      
      def key_released?(key_code)
        key_state&.released?(key_code) || false
      end
      
      def key_up?(key_code)
        key_state&.up?(key_code) || true
      end
      
      def key_press_duration(key_code)
        key_state&.press_duration(key_code) || 0.0
      end
      
      private
      
      # Load default modules based on platform
      def load_default_modules

        # ModuleProvider.all is populated when the individual modual provider files are loaded
        ModuleProvider.all.each do |name, provider|
          # Get module-specific config from keyboard_config
          module_config = @keyboard_config[name] || {}
          
          # Skip if explicitly disabled in the keyboard config
          next if module_config[:enabled] == false
          
          # Merge the keyboard config defaults using the provider's config block
          # Function is in :config_block and defined in the individual providers
          options = provider[:config_block].call({
            keyboard: @keyboard_config,  # Full keyboard config
            module_config: module_config # Module-specific config
          })
          
          # Skip if the provider decided to disable this module
          next if options[:enabled] == false
          
          # Create the module instance
          module_instance = provider[:class].new(options)
          
          # Get priority from config or use default
          priority = module_config[:priority] || provider[:priority]
          
          # Register with the manager
          add_module(name, module_instance, priority: priority)
        end
      end

    end
  end

end