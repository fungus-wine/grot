# frozen_string_literal: true

require 'toml-rb'
require 'grot/version'
require 'grot/errors'
require 'grot/config/config_registry'

module Grot
  module Config
    class ConfigManager
      def initialize(registry = ConfigRegistry.instance)
        @registry = registry
      end
      
      def load_config(config_file)
        # Check if project config exists
        unless File.exist?(config_file)
          raise Grot::Errors::ConfigurationError, "Config file not found: #{config_file}"
        end
        
        begin
          # Load project-specific config
          project_config = TomlRB.load_file(config_file)
          # Symbolize keys immediately after loading
          project_config = symbolize_keys_deeply(project_config)
          
          # Check for global config in ~/.config/grot/config.toml
          global_path = File.expand_path('~/.config/grot/config.toml')
          if File.exist?(global_path)
            begin
              global_config = TomlRB.load_file(global_path)
              # Symbolize keys for global config too
              global_config = symbolize_keys_deeply(global_config)
              # Merge with project config (project overrides global)
              project_config = deep_merge(global_config, project_config)
            rescue => e
              # Just log warning if global config has issues
              warn "Warning: Error loading global config: #{e.message}"
            end
          end
          
          # Validate the merged configuration using registry
          validated_config, errors = @registry.validate(project_config)
          
          # If there are validation errors, log them as warnings
          # (we'll only fail on critical errors later during specific command validation)
          if errors && !errors.empty?
            warn "Warning: Config validation issues detected:"
            errors.each do |key, msg|
              warn "  #{key}: #{msg}"
            end
          end
          
          return validated_config
        rescue TomlRB::ParseError => e
          raise Grot::Errors::ConfigurationError, "TOML parsing error in #{config_file}: #{e.message}"
        rescue => e
          raise Grot::Errors::ConfigurationError, "Failed to load config: #{e.message}"
        end
      end
      
      def create_default_config(filename)
        current_dir = File.basename(Dir.pwd)
        port_handler = Grot::Ports::PortHandler.new
        
        # Try to detect connected board
        detected_port = port_handler.detect_best_port
        board_info = port_handler.detect_board_info(detected_port)
        
        # Create appropriate default config based on detected board
        config = if board_info && board_info[:fqbn]
          puts "Detected board: #{board_info[:fqbn]} on port #{board_info[:port]}"
          create_config_for_detected_board(current_dir, board_info)
        else
          puts "No board detected or unable to determine board type. Creating generic config."
          create_generic_config(current_dir)
        end
        
        # Write the TOML configuration file
        write_toml_config(filename, config)
      end
      
      def validate_config(config, command_def)
        # Only validate when command requires config
        return unless command_def && command_def[:requires_config]
        
        # Check for required fields based on command requirements
        validate_required_fields(config, command_def)
        
        # Board-specific validation
        if command_def[:board_specific] && config[:fqbn]
          board_strategy = Boards::BoardStrategyFactory.create_strategy(config)
          board_strategy.validate_config
        end
      end
      
      def print_config(config)
        puts TomlRB.dump(config)
      end
      
      private

      def create_config_for_detected_board(current_dir, board_info)
        # Start with basic config
        config = {
          
            :sketch_path => "#{current_dir}.ino",
            :cli_path => 'arduino-cli',
            :port => board_info[:port],
            :fqbn => board_info[:fqbn],
            :baud_rate => 9600
          
        }
        
        # Add board-specific options based on detected board type
        case board_info[:board_type]
        when 'esp32_s3'
          # Get ESP32-S3 defaults from registry
          config[:esp32_options] = @registry[:esp32_options].defaults
        when 'giga'
          # Get GIGA defaults from registry
          config[:giga_options] = @registry[:giga_options].defaults
        end
        
        config
      end
      
      def create_generic_config(current_dir)
        # Get defaults from registry
        config = {}
        
        # Get basic defaults
        basic_defaults = @registry[:basic].defaults
        config.merge!(basic_defaults)
        
        # Set project-specific values
        config[:sketch_path] = "#{current_dir}.ino"
        config[:port] = '/dev/cu.whateveryourportis'
        config[:fqbn] = 'arduino:avr:uno'
        
        config
      end
      
      def write_toml_config(filename, config)
        begin
          File.open(filename, 'w') do |file|
            # Write header with metadata
            write_header(file)
            
            # Write basic configuration section
            write_section(file, 'Basic Configuration', :basic, extract_basic_config(config))
            
            # Write board-specific sections based on board type
            if config[:fqbn] && config[:fqbn].include?('esp32:esp32')
              write_section(file, 'ESP32-S3 Configuration', :esp32_options, config[:esp32_options])
            elsif config[:fqbn] && config[:fqbn].include?('giga')
              write_section(file, 'GIGA Configuration', :giga_options, config[:giga_options])
            end
            
            # Write interface options if available
            if config.key?(:interface)
              write_section(file, 'Interface Configuration', :interface, config[:interface])
            end
            
            # Write monitor options if available
            if config.key?(:monitor)
              write_section(file, 'Monitor Configuration', :monitor, config[:monitor])
            end
            
            # Write plotter options if available
            if config.key?(:plotter)
              write_section(file, 'Plotter Configuration', :plotter, config[:plotter])
            end
            
            # Write theme options if available
            if config.key?(:theme)
              write_section(file, 'Theme Configuration', :theme, config[:theme])
            end
            
            # Write keyboard options if available
            if config.key?(:keyboard)
              write_section(file, 'Keyboard Configuration', :keyboard, config[:keyboard])
            end
          end
        rescue Errno::EACCES
          raise Grot::Errors::ConfigurationError, "Permission denied when writing to #{filename}"
        rescue Errno::ENOENT
          raise Grot::Errors::ConfigurationError, "Directory not found for config file: #{filename}"
        rescue => e
          raise Grot::Errors::ConfigurationError, "Error writing config file: #{e.message}"
        end
      end
      
      def write_header(file)
        file.puts "# Grot Configuration File (version #{Grot::VERSION})"
        file.puts "# ================================================"
        file.puts "#"
        file.puts "# Run 'grot boards' for a list of supported boards"
        file.puts "# Run 'grot ports' for a list of available ports"
        file.puts ""
      end
      
      def write_section(file, title, section_name, options)
        return if options.nil? || options.empty?
        
        file.puts "# #{title}"
        file.puts "# #{'=' * title.length}"
        
        # Write section marker if this is a subsection
        file.puts "[#{section_name}]" if section_name
        
        # Write each option with documentation if available
        options.each do |key, value|
          # Get option documentation if available
          option = section_name ? 
                  @registry[section_name.to_sym]&.[](key) : 
                  @registry[:basic]&.[](key)
          
          description = option&.description || ""
          file.puts "# #{description}" unless description.empty?
          
          # Format the value properly for TOML
          file.puts "#{key} = #{format_toml_value(value)}"
          file.puts "" # Add blank line for readability
        end
        
        file.puts "" # Extra blank line between sections
      end
      
      def extract_basic_config(config)
        basic_keys = [:sketch_path, :cli_path, :port, :fqbn, :baud_rate]
        basic_config = {}
        
        basic_keys.each do |key|
          basic_config[key] = config[key] if config.key?(key)
        end
        
        basic_config
      end
      
      # Format a value properly for TOML
      def format_toml_value(value)
        case value
        when String
          "\"#{value.gsub('"', '\"')}\""
        when Numeric, TrueClass, FalseClass
          value.to_s
        when Array
          array_str = value.map { |v| format_toml_value(v) }.join(", ")
          "[#{array_str}]"
        when Hash
          # For simple hashes, use inline tables
          hash_str = value.map { |k, v| "#{k} = #{format_toml_value(v)}" }.join(", ")
          "{ #{hash_str} }"
        when nil
          '""'
        else
          "\"#{value}\""
        end
      end
      
      def validate_required_fields(config, command_def)
        # Determine required fields based on command
        required_fields = [:cli_path]
        required_fields << :sketch_path if command_def[:requires_sketch_path]
        required_fields << :fqbn if command_def[:requires_fqbn]
        required_fields << :port if command_def[:requires_port]
        
        # Make sure we have a basic section
        unless config[:basic]
          raise Grot::Errors::ConfigurationError, "Missing [basic] section in config"
        end
        
        # Check for missing fields in the basic section
        missing_fields = required_fields.select do |field| 
          config[:basic][field].nil? || config[:basic][field].to_s.strip.empty?
        end
        
        unless missing_fields.empty?
          raise Grot::Errors::ConfigurationError, "Missing required field(s) in [basic] section: #{missing_fields.join(', ')}"
        end
      end

      # Helper method for deep merging configs
      def deep_merge(base, override)
        result = base.dup
        override.each do |key, value|
          if value.is_a?(Hash) && result[key].is_a?(Hash)
            result[key] = deep_merge(result[key], value)
          else
            result[key] = value
          end
        end
        result
      end

      # Add this method to ConfigManager
      def symbolize_keys_deeply(hash)
        return hash unless hash.is_a?(Hash)
        
        hash.each_with_object({}) do |(key, value), result|
          # Convert key to symbol
          symbol_key = key.respond_to?(:to_sym) ? key.to_sym : key
          
          # Process value recursively if it's a hash
          processed_value = case value
                            when Hash then symbolize_keys_deeply(value)
                            when Array then value.map { |v| v.is_a?(Hash) ? symbolize_keys_deeply(v) : v }
                            else value
                            end
          
          result[symbol_key] = processed_value
        end
      end

    end
  end
end
