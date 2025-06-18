# frozen_string_literal: true

module Grot
  module Keyboard
    class EventBus
      def initialize(module_registry)
        @module_registry = module_registry
      end
      
      def process_event(event)
        result = event
        
        @module_registry.modules_in_order.each do |mod|
          break if result.nil?  # Event was consumed.
          
          # Only process if module is enabled
          result = mod.process_event(result) if mod.enabled
        end
        
        result  # Return final result after processing
      end
      
      def update_all(delta_time)
        @module_registry.modules_in_order.each do |mod|
          mod.update(delta_time) if mod.enabled
        end
      end
      
      def shutdown_all
        @module_registry.modules_in_order.each do |mod|
          mod.shutdown
        end
      end
      
      def reset_all
        @module_registry.modules_in_order.each do |mod|
          mod.reset
        end
      end
    end
  end
end