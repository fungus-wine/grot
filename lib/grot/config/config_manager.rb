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
        global_config_path = File.expand_path("~/.config/grot/config.toml")
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
        # Keep the useful FQBN validation
        if config.dig(:basic, :fqbn)
          validate_fqbn(config[:basic][:fqbn])
        end
        
        # Simple type coercion for key fields
        coerce_integer(config, :interface, :baud_rate)
        coerce_integer(config, :plotter, :buffer_size)
        coerce_integer(config, :monitor, :buffer_size)
        coerce_integer(config, :esp32_options, :frequency)
        coerce_float(config, :giga_options, :flash_split)
      end
      
      def self.coerce_integer(config, section, key)
        value = config.dig(section, key)
        return unless value
        
        config[section][key] = Integer(value)
      rescue ArgumentError, TypeError
        raise "#{section}.#{key} must be an integer, got: #{value}"
      end
      
      def self.coerce_float(config, section, key)
        value = config.dig(section, key)
        return unless value
        
        config[section][key] = Float(value)
      rescue ArgumentError, TypeError
        raise "#{section}.#{key} must be a number, got: #{value}"
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
        return [] unless fqbn
        
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
          sketch_path = "."         # Path to your Arduino sketch directory
          
          [interface]
          baud_rate = #{DEFAULTS[:interface][:baud_rate]}
          logs_directory = "#{DEFAULTS[:interface][:logs_directory]}"
          
          [plotter]
          buffer_size = #{DEFAULTS[:plotter][:buffer_size]}  # Number of data points to keep in memory
          
          [monitor]
          buffer_size = #{DEFAULTS[:monitor][:buffer_size]}  # Serial monitor buffer size
          
          # Board-specific configuration options
          # These sections are only needed for specific boards and are otherwise ignored
          
          [giga_options]
          # Options for Arduino GIGA R1 WiFi boards
          # target_core = "#{DEFAULTS[:giga_options][:target_core]}"     # Target processor core: "CM4" or "CM7"
          # flash_split = #{DEFAULTS[:giga_options][:flash_split]}       # Memory split ratio (0.0 to 1.0)
          
          [esp32_options]
          # Options for ESP32-S3 boards
          # core_config = "#{DEFAULTS[:esp32_options][:core_config]}"    # Core usage: "dual", "single-0", "single-1"
          # frequency = #{DEFAULTS[:esp32_options][:frequency]}          # CPU frequency in MHz: 80, 160, or 240
          
          # Keyboard handling configuration
          # Advanced options for keyboard input in GUI interfaces
          
          [keyboard_key_state]
          enabled = #{DEFAULTS[:keyboard_key_state][:enabled]}
          priority = #{DEFAULTS[:keyboard_key_state][:priority]}
          
          [keyboard_stuck_key_fixer]
          enabled = #{DEFAULTS[:keyboard_stuck_key_fixer][:enabled]}
          priority = #{DEFAULTS[:keyboard_stuck_key_fixer][:priority]}
          auto_release_delay = #{DEFAULTS[:keyboard_stuck_key_fixer][:auto_release_delay]}
          
          [keyboard_mac_adapter]
          enabled = #{DEFAULTS[:keyboard_mac_adapter][:enabled]}       # Auto-enabled on macOS
          priority = #{DEFAULTS[:keyboard_mac_adapter][:priority]}
          command_fix = #{DEFAULTS[:keyboard_mac_adapter][:command_fix]}
          auto_fix_stuck_modifiers = #{DEFAULTS[:keyboard_mac_adapter][:auto_fix_stuck_modifiers]}
          
          [keyboard_linux_adapter]
          enabled = #{DEFAULTS[:keyboard_linux_adapter][:enabled]}     # Auto-enabled on Linux
          priority = #{DEFAULTS[:keyboard_linux_adapter][:priority]}
          fix_window_manager_conflicts = #{DEFAULTS[:keyboard_linux_adapter][:fix_window_manager_conflicts]}
          
          [keyboard_debouncer]
          enabled = #{DEFAULTS[:keyboard_debouncer][:enabled]}
          priority = #{DEFAULTS[:keyboard_debouncer][:priority]}
          repeat_delay = #{DEFAULTS[:keyboard_debouncer][:repeat_delay]}
          repeat_rate = #{DEFAULTS[:keyboard_debouncer][:repeat_rate]}
          
          [keyboard_buffer]
          enabled = #{DEFAULTS[:keyboard_buffer][:enabled]}
          priority = #{DEFAULTS[:keyboard_buffer][:priority]}
          buffer_time = #{DEFAULTS[:keyboard_buffer][:buffer_time]}
        TOML
      end
    end
  end
end