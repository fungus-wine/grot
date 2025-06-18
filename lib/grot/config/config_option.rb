# frozen_string_literal: true

module Grot
  module Config
    # Represents a single configuration option with schema information
    class ConfigOption
      attr_reader :key, :type, :default, :description, :validation, :dependencies
      
      def initialize(key, type, default, description = "", validation = nil, dependencies = [])
        @key = key
        @type = type
        @default = default
        @description = description
        @validation = validation || default_validation_for(type)
        @dependencies = dependencies
      end
      
      # Validate a value against this option's schema
      def validate(value)
        # Skip validation if nil and there's a default
        return [@default, nil] if value.nil? && !@default.nil?
        
        # Basic type checking
        unless value_matches_type?(value)
          return [nil, "#{@key} must be a #{@type}, got #{value.class}"]
        end
        
        # Custom validation if provided
        if @validation.is_a?(Proc)
          result, error = @validation.call(value)
          return [result, error] if error
          value = result
        end
        
        [value, nil]
      end
      
      private
      
      def value_matches_type?(value)
        case @type
        when :string
          value.is_a?(String)
        when :integer
          value.is_a?(Integer)
        when :float
          value.is_a?(Numeric)
        when :boolean
          value == true || value == false
        when :array
          value.is_a?(Array)
        when :hash
          value.is_a?(Hash)
        else
          true # Unknown types are not type-checked
        end
      end
      
      def default_validation_for(type)
        case type
        when :string
          ->(value) { [value.to_s, nil] }
        when :integer
          ->(value) {
            begin
              [Integer(value), nil]
            rescue ArgumentError, TypeError
              [nil, "#{@key} must be an integer"]
            end
          }
        when :float
          ->(value) {
            begin
              [Float(value), nil]
            rescue ArgumentError, TypeError
              [nil, "#{@key} must be a number"]
            end
          }
        when :boolean
          ->(value) {
            case value
            when true, 'true', 1, '1', 'yes', 'y'
              [true, nil]
            when false, 'false', 0, '0', 'no', 'n'
              [false, nil]
            else
              [nil, "#{@key} must be a boolean"]
            end
          }
        else
          ->(value) { [value, nil] }
        end
      end
    end
  end
end