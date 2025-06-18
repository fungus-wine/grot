# frozen_string_literal: true

module Grot
  module Keyboard
    # Base class for all keyboard handler modules
    class ModuleBase
      attr_reader :priority, :enabled
      
      def initialize(options = {})
        @priority = options[:priority] || 0
        @enabled = options.key?(:enabled) ? options[:enabled] : true
        @manager = nil
        @options = options
        
        # Module-specific initialization
        init(options)
      end
      
      # Set the keyboard manager reference
      # @param manager [KeyboardManager] The keyboard manager
      def set_manager(manager)
        @manager = manager
        nil
      end
      
      # Enable the module
      def enable
        return if @enabled
        @enabled = true
        on_enable
      end
      
      # Disable the module
      def disable
        return unless @enabled
        @enabled = false
        on_disable
      end
      
      # Process a key event
      # @param event [KeyEvent] The event to process
      # @return [KeyEvent, nil] The processed event or nil if consumed
      def process_event(event)
        return event unless @enabled
        handle_event(event)
      end
      
      # Update the module state
      # @param delta_time [Float] Time since last update in seconds
      def update(delta_time)
        return unless @enabled
        on_update(delta_time)
      end
      
      # Shutdown the module
      def shutdown
        on_shutdown
      end
      
      # Reset the module state
      def reset
        on_reset
      end
      
      #---------------------------------------------------------
      # The following methods should be overridden by subclasses
      #---------------------------------------------------------
      
      # Initialize module-specific state
      # @param options [Hash] Module options
      def init(options)
        # Override in subclasses
      end
      
      # Handle a key event
      # @param event [KeyEvent] The event to process
      # @return [KeyEvent, nil] The processed event or nil if consumed
      def handle_event(event)
        # Override in subclasses
        event
      end
      
      # Update module state
      # @param delta_time [Float] Time since last update in seconds
      def on_update(delta_time)
        # Override in subclasses
      end
      
      # Called when module is enabled
      def on_enable
        # Override in subclasses
      end
      
      # Called when module is disabled
      def on_disable
        # Override in subclasses
      end
      
      # Called when module is shutdown
      def on_shutdown
        # Override in subclasses
      end
      
      # Called when module is reset
      def on_reset
        # Override in subclasses
      end
    end
  end
end