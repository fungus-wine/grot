# frozen_string_literal: true

require_relative 'config_option'

module Grot
  module Config
    # Represents a category of related configuration options
    class ConfigCategory
      attr_reader :name, :options, :description
      
      def initialize(name, description = "")
        @name = name
        @description = description
        @options = {}
      end
      
      # Add a configuration option to this category
      def add_option(key, type, default, description = "", validation = nil, dependencies = [])
        option = ConfigOption.new(key, type, default, description, validation, dependencies)
        @options[key] = option
        option
      end
      
      # Get an option by key
      def [](key)
        @options[key]
      end
      
      def validate(config)
        results = {}
        errors = {}
        
        # Create a copy of the config for this category
        # Note the symbol key access
        category_config = config[@name] || {}
        
        # Validate each option
        @options.each do |key, option|
          # Use symbol keys for lookup
          value = category_config[key]
          result, error = option.validate(value)
          
          if error
            errors[:"#{@name}.#{key}"] = error
          else
            results[key] = result.nil? ? option.default : result
          end
        end
        
        [results, errors]
      end
      
      # Get default values for all options in this category
      def defaults
        @options.transform_values(&:default)
      end
    end
  end
end