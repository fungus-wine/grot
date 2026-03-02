# frozen_string_literal: true

require 'toml-rb'
require 'grot/boards/board_registry'

module Grot
  module Config
    class ConfigManager
      def self.load_config(file_path = nil)
        # Start with defaults
        config = deep_dup(DEFAULTS)
        
        # Merge global config if exists
        global_config_path = File.expand_path("~/.config/grot/.grotconfig")
        if File.exist?(global_config_path)
          global_config = load_toml(global_config_path)
          config = deep_merge(config, global_config)
        end
        
        # Merge local config if specified/exists
        if file_path && File.exist?(file_path)
          local_config = load_toml(file_path)
          config = deep_merge(config, local_config)
        end
        
        # Basic validation and type coercion
        validate_and_coerce(config)
        
        config
      end
      
      def self.create_default_config(file_path)
        require 'grot/config/defaults'
        
        # Generate basic TOML content from defaults
        toml_content = generate_default_toml
        
        File.open(file_path, 'w') do |file|
          file.write(toml_content)
        end
      end
      
      private
      
      def self.load_toml(path)
        TomlRB.load_file(path, symbolize_keys: true)
      rescue => e
        raise "Failed to load config file #{path}: #{e.message}"
      end
      
      def self.validate_and_coerce(config)
        # String type validation (must run before fqbn validation to avoid cryptic crashes)
        validate_string(config, :basic, :fqbn)
        validate_string(config, :basic, :port)
        validate_string(config, :basic, :cli_path)
        validate_string(config, :basic, :sketch_path)
        validate_string(config, :giga_options, :target_core)
        validate_string(config, :giga_options, :split)
        validate_string(config, :interface, :logs_directory)

        # Keep the useful FQBN validation
        if config.dig(:basic, :fqbn)
          validate_fqbn(config[:basic][:fqbn])
        end

        # Simple type coercion for key fields
        coerce_integer(config, :interface, :baud_rate)
      end
      
      def self.validate_string(config, section, key)
        value = config.dig(section, key)
        return unless value
        unless value.is_a?(String)
          raise "#{section}.#{key} must be a string, got: #{value.inspect} (#{value.class.name})"
        end
      end

      def self.coerce_integer(config, section, key)
        value = config.dig(section, key)
        return unless value
        
        config[section][key] = Integer(value)
      rescue ArgumentError, TypeError
        raise "#{section}.#{key} must be an integer, got: #{value}"
      end
      
      def self.validate_fqbn(fqbn)
        return unless fqbn
        
        unless Grot::Boards::BoardRegistry.supported?(fqbn)
          similar = find_similar_boards(fqbn)
          suggestion = if similar.any?
                        "\n\nDid you mean one of these?\n" + similar.map { |b| "  - #{b}" }.join("\n")
                      else
                        "\n\nRun 'grot boards' for a list of all supported boards."
                      end
          raise "Invalid board (fqbn) specified: #{fqbn}#{suggestion}"
        end
      end
      
      def self.find_similar_boards(fqbn)
        return [] unless fqbn.is_a?(String)
        
        if fqbn.include?(':')
          vendor = fqbn.split(':').first
          similar = Grot::Boards::BoardRegistry.supported_boards.keys.select do |board_fqbn|
            board_fqbn.start_with?("#{vendor}:")
          end
          return similar.take(5) if similar.any?
        end
        
        []
      end
      
      def self.deep_merge(hash1, hash2)
        hash1.merge(hash2) do |key, v1, v2|
          if v1.is_a?(Hash) && v2.is_a?(Hash)
            deep_merge(v1, v2)
          else
            v2
          end
        end
      end
      
      def self.deep_dup(hash)
        hash.transform_values do |value|
          case value
          when Hash
            deep_dup(value)
          when Array
            value.map { |v| v.is_a?(Hash) ? deep_dup(v) : v }
          else
            value
          end
        end
      end
      
      def self.generate_default_toml
        require 'grot/config/defaults'
        
        <<~TOML
          # Grot Configuration File
          # This file configures your Arduino development environment
          # Uncomment and modify values as needed
          
          [basic]
          cli_path = "#{DEFAULTS[:basic][:cli_path]}"
          fqbn = "arduino:avr:uno"  # Board fully qualified name - run 'grot boards' for options
          port = "/dev/ttyUSB0"     # Serial port - run 'grot ports' for available ports  
          sketch_path = "."  # Path to your Arduino sketch directory
          
          [interface]
          baud_rate = #{DEFAULTS[:interface][:baud_rate]}
          logs_directory = "#{DEFAULTS[:interface][:logs_directory]}"
          
          # Board-specific configuration options
          # These sections are only needed for specific boards and are otherwise ignored

          [giga_options]
          # Options for Arduino GIGA R1 WiFi boards (appended to FQBN during compile/upload)
          # target_core = "#{DEFAULTS[:giga_options][:target_core]}"     # Target processor core: "cm4" or "cm7"
          # split = "#{DEFAULTS[:giga_options][:split]}"                 # Flash split: "100_0", "75_25", or "50_50"
        TOML
      end
    end
  end
end