# frozen_string_literal: true

require 'grot/keyboard/module_base'

module Grot
  module Keyboard
    # Registry for keyboard handler modules
    class ModuleRegistry
      # Initialize a new module registry
      def initialize
        @modules = {}
        @module_order = []
        @sorted = true
      end
      
      def register(name, module_instance, override = false)
        raise "Module must be a ModuleBase" unless module_instance.is_a?(ModuleBase)
        raise "Module named #{name} already exists" if @modules.key?(name) && !override
        
        @modules[name] = module_instance
        @module_order << name unless @module_order.include?(name)
        @sorted = false
        
        true
      end
      
      def unregister(name)
        return nil unless @modules.key?(name)
        
        module_instance = @modules.delete(name)
        @module_order.delete(name)
        
        module_instance
      end
      
      def [](name)
        @modules[name]
      end
      
      def modules_in_order
        sort_modules if !@sorted
        @module_order.map { |name| @modules[name] }
      end
      
      def has_module?(name)
        @modules.key?(name)
      end
      
      def count
        @modules.size
      end
      
      private
      
      def sort_modules
        @module_order.sort! do |a, b|
          # Higher priority modules come first
          @modules[b].priority <=> @modules[a].priority
        end
        @sorted = true
      end
    end
  end
end