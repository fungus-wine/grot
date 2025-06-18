# frozen_string_literal: true

require 'grot/keyboard/module_base'
require 'grot/keyboard/key_event'
require 'grot/keyboard/key_constants'

module Grot

  module Keyboard
    module Modules
      class Debouncer < ModuleBase
        attr_reader :repeat_delay, :repeat_rate
        
        def initialize(options = {})
          super
          
          # Key repeat settings
          @repeat_delay = options[:repeat_delay] || 0.5  # 500ms
          @repeat_rate = options[:repeat_rate] || 0.05   # 50ms (20 repeats/sec)
          @key_configs = options[:key_configs] || {}
          @arrow_keys_config = options[:arrow_keys] || {}
          @navigation_keys_config = options[:navigation_keys] || {}
          
          # Tracking data for key repeats
          @key_press_times = {}
          @key_repeat_times = {}
          @repeating_keys = {}
          
          # Event callback
          @event_callback = options[:event_callback]
        end
        
        # Set callback for key repeat events
        def set_repeat_callback(&callback)
          @event_callback = callback
        end
        
        def handle_event(event)
          key = event.key_code
          if event.key_down?
            @key_press_times[key] = event.timestamp unless @key_press_times.key?(key)
            return event  # Always pass KEY_DOWN
          elsif event.key_up?
            @key_press_times.delete(key)
            @key_repeat_times.delete(key)
            @repeating_keys.delete(key)
            return event
          end
          event
        end
        
        def on_update(delta_time)
          now = Time.now.to_f
          
          # Check keys that should start repeating
          @key_press_times.each do |key, press_time|
            # Skip keys already repeating
            next if @repeating_keys[key]
            
            # Get delay for this key
            delay = get_repeat_delay(key)
            
            # Check if it's time to start repeating
            if now >= press_time + delay
              # Start repeating
              @repeating_keys[key] = true
              @key_repeat_times[key] = now
              
              # Generate repeat event
              generate_key_repeat(key, now)
              
            end
          end
          
          # Check keys that are already repeating
          @repeating_keys.each do |key, _|
            # Get last repeat time
            last_repeat = @key_repeat_times[key] || 0
            
            # Get rate for this key
            rate = get_repeat_rate(key)
            
            # Check if it's time for another repeat
            if now >= last_repeat + rate
              # Update repeat time
              @key_repeat_times[key] = now
              
              # Generate repeat event
              generate_key_repeat(key, now)
            end
          end
        end
        
        def on_reset
          @key_press_times.clear
          @key_repeat_times.clear
          @repeating_keys.clear
        end
        
        # Configure repeat behavior for a specific key
        def configure_key(key, delay = nil, rate = nil)
          @key_configs[key] = {
            repeat_delay: delay,
            repeat_rate: rate
          }.compact
        end
        
        # Configure repeat behavior for a group of keys
        def configure_keys(keys, delay = nil, rate = nil)
          keys.each do |key|
            configure_key(key, delay, rate)
          end
        end
        
        private
        
        # Get the repeat delay for a specific key
        def get_repeat_delay(key)
          if KeyConstants.arrow_key?(key) && @arrow_keys_config[:repeat_delay]
            return @arrow_keys_config[:repeat_delay]
          elsif KeyConstants.navigation_key?(key) && @navigation_keys_config[:repeat_delay]
            return @navigation_keys_config[:repeat_delay]
          elsif @key_configs[key] && @key_configs[key][:repeat_delay]
            return @key_configs[key][:repeat_delay]
          end
          
          @repeat_delay
        end
        
        # Get the repeat rate for a specific key
        def get_repeat_rate(key)
          if KeyConstants.arrow_key?(key) && @arrow_keys_config[:repeat_rate]
            return @arrow_keys_config[:repeat_rate]
          elsif KeyConstants.navigation_key?(key) && @navigation_keys_config[:repeat_rate]
            return @navigation_keys_config[:repeat_rate]
          elsif @key_configs[key] && @key_configs[key][:repeat_rate]
            return @key_configs[key][:repeat_rate]
          end
          
          @repeat_rate
        end

        def generate_key_repeat(key, timestamp)
          # Get current modifiers
          modifiers = get_current_modifiers
          
          # Create a synthetic key event
          event = KeyEvent.new(
            KeyEvent::KEY_HELD,  # Use KEY_HELD for repeats
            key,
            modifiers,
            timestamp
          )
          
          # Call the callback if registered
          @event_callback.call(event) if @event_callback
          
          # Process the event
          if @manager
            @manager.process_event(event)
          end
        end

        # Get current modifier states
        def get_current_modifiers
          return {} unless @manager && @manager.respond_to?(:key_state)
          
          key_state = @manager.key_state
          return {} unless key_state
          
          {
            shift: key_state.down?(Gosu::KB_LEFT_SHIFT) || key_state.down?(Gosu::KB_RIGHT_SHIFT),
            control: key_state.down?(Gosu::KB_LEFT_CONTROL) || key_state.down?(Gosu::KB_RIGHT_CONTROL),
            alt: key_state.down?(Gosu::KB_LEFT_ALT) || key_state.down?(Gosu::KB_RIGHT_ALT),
            meta: key_state.down?(Gosu::KB_LEFT_META) || key_state.down?(Gosu::KB_RIGHT_META)
          }
        end

      end
    end
  end
end