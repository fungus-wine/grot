# frozen_string_literal: true

require_relative 'config_category'

module Grot
  module Config
    # Main registry for all configuration options
    class ConfigRegistry
      attr_reader :categories
      
      def initialize
        @categories = {}
      end
      
      # Define a new configuration category
      def define_category(name, description = "")
        @categories[name] = ConfigCategory.new(name, description)
      end
      
      # Get a category by name
      def [](category_name)
        @categories[category_name]
      end
      
      # Add an option to a category (creating the category if needed)
      def add_option(category, key, type, default, description = "", validation = nil, dependencies = [])
        # Create category if it doesn't exist
        @categories[category] ||= ConfigCategory.new(category)
        
        # Add option to category
        @categories[category].add_option(key, type, default, description, validation, dependencies)
      end
      
      # Validate a complete configuration
      def validate(config)
        config ||= {}
        results = {}
        errors = {}
        
        # Validate each category
        @categories.each do |name, category|
          category_results, category_errors = category.validate(config)
          
          # Add category results to overall results
          results[name] = category_results unless category_results.empty?
          
          # Add category errors to overall errors
          errors.merge!(category_errors)
        end
        
        [results, errors]
      end
      
      # Get default values for the entire configuration
      def defaults
        @categories.transform_values(&:defaults)
      end
      
      # Get flattened defaults (for backward compatibility)
      def flattened_defaults
        flattened = {}
        
        @categories.each do |category_name, category|
          if [:basic, :core].include?(category_name)
            # Top-level options
            flattened.merge!(category.defaults)
          else
            # Nested options
            flattened[category_name] = category.defaults
          end
        end
        
        flattened
      end
      
      # Utility methods for configuration access with fallbacks
      
      def get_category_defaults(category_name)
        if @categories[category_name]
          @categories[category_name].defaults
        else
          {}
        end
      end
      

      def get_value(config, category_name, key, default_value = nil)
        # Try config first
        return config[key] if config.key?(key)
        
        # Try registry category defaults
        category_defaults = get_category_defaults(category_name)
        return category_defaults[key] if category_defaults.key?(key)
        
        # Fall back to provided default
        default_value
      end
      
      def get_nested_value(config, path, category_name, registry_key, default_value = nil)
        # Helper for safe digging into nested hashes
        dig_value = lambda do |hash, keys|
          keys.inject(hash) do |h, key|
            return nil unless h.is_a?(Hash)
            return nil unless h.key?(key)
            h[key]
          end
        end
        
        # Try config first
        value = dig_value.call(config, path)
        return value unless value.nil?
        
        # Try registry defaults
        category_defaults = get_category_defaults(category_name)
        return category_defaults[registry_key] if category_defaults.key?(registry_key)
        
        # Fall back to provided default
        default_value
      end
      
      # Singleton instance
      def self.instance
        @instance ||= new
      end
      
      # Reset the singleton (mainly for testing)
      def self.reset!
        @instance = new
      end
      
      # Initialize the registry with basic structure
      def self.init_defaults
        registry = instance
        
        # Define basic categories
        registry.define_category(:basic, "Basic configuration options")
        registry.define_category(:board, "Board-specific options")
        registry.define_category(:interface, "Interface options")
        registry.define_category(:keyboard, "Keyboard handling options")
        
        # Basic configuration options
        registry.add_option(:basic, :sketch_path, :string, nil, "Path to the sketch file")
        registry.add_option(:basic, :cli_path, :string, "arduino-cli", "Path to arduino-cli executable")
        registry.add_option(:basic, :port, :string, nil, "Serial port for uploading/monitoring")
        registry.add_option(:basic, :fqbn, :string, nil, "Fully Qualified Board Name")
        registry.add_option(:basic, :baud_rate, :integer, 9600, "Serial baud rate")
        
        # Interface options
        registry.add_option(:interface, :font, :string, "monospace", "Font for interface windows")
        registry.add_option(:interface, :window_width, :integer, 800, "Initial window width")
        registry.add_option(:interface, :window_height, :integer, 600, "Initial window height")
        
        # We'll add more options in subsequent steps
        
        registry
      end
    end
    
    # Initialize the registry when this file is loaded
    ConfigRegistry.init_defaults
  end
end
