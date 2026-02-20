# frozen_string_literal: true

require "grot/version"
require "grot/boards/board_registry"
require "grot/cli/colorator"
require "grot/cli/progress_display"
require "open3"

module Grot
  module Commands
    # Handlers for various commands
    module Handlers
      extend Grot::CLI::Colorator

      # Show version information
      def self.version_command(app)
        puts "Grot version #{Grot::VERSION}"
        puts "A tool for Arduino command-line development"

        0  # Return success
      end
      
      # Initialize a new configuration file
      def self.init_command(app)
        config_file = app.options[:config_file]
        
        create_it = true
        if File.exist?(config_file)
          print "Configuration file '#{config_file}' already exists. Overwrite? (y/N): "
          answer = gets.chomp.downcase
          create_it = false unless answer == 'y'
        end
        
        if create_it
          puts "Creating new configuration file: #{config_file}"
          Grot::Config::ConfigManager.create_default_config(config_file)
          puts "Done! Edit #{config_file} to configure your board settings."
        else
          puts "No changes to the existing #{config_file} were made."
        end

        0  # Return success
      end

      # List available serial ports
      def self.ports_command(app)
        puts "Available Ports"
        separator
        app.port_handler.list_available_ports

        0  # Return success
      end
      
      # List supported boards
      def self.boards_command(app)
        puts "Supported boards"
        puts "#{'Name'.ljust(50)} FQBN"
        separator
        Grot::Boards::BoardRegistry.supported_boards.each do |fqbn, info|
          puts "#{info[:name].ljust(50)} #{fqbn}"
        end
        
        0  # Return success
      end
      
      def self.dump_command(app)
        puts "Configuration"
        separator
        
        config_file = app.options[:config_file]
        if File.exist?(config_file)
          # Load and print the config file
          config = Grot::Config::ConfigManager.load_config(config_file)
          puts config.inspect
        else
          puts "Config file not found"
        end
        
        puts "\nAvailable Ports"
        separator
        app.port_handler.list_available_ports
        
        0  # Return success
      end

      # Clean compilation artifacts using arduino-cli cache clean
      def self.clean_command(app, config)
        cli_path = config[:basic][:cli_path] || 'arduino-cli'
        
        cmd = "#{cli_path} cache clean"
        
        # Execute the command and capture output
        stdout, stderr, status = Open3.capture3(cmd)
        
        # Strip any ANSI color codes
        stdout = stdout.gsub(/\e\[[0-9;]*m/, '')
        stderr = stderr.gsub(/\e\[[0-9;]*m/, '')
        
        # Print output in grey
        puts colorize(stdout, :grey) unless stdout.empty?
        puts colorize(stderr, :grey) unless stderr.empty?
        
        if status.success?
          info "Cache cleaned successfully\n"
        else
          error "Cache cleaning failed with exit code: #{status.exitstatus}"
        end
        
        # Store the executed command in app for the post_action
        app.instance_variable_set(:@last_executed_command, cmd)
        
        status.exitstatus
      end

      def self.validate_command(app, config)
        require 'grot/config/defaults'
        require 'grot/boards/board_registry'
        require 'grot/boards/board_strategy_factory'

        errors = []
        warnings = []

        config_file = app.options[:config_file]
        puts "Validating #{config_file}..."
        separator

        # Warn on unrecognized top-level sections
        known_sections = Grot::Config::DEFAULTS.keys
        config.each_key do |section|
          unless known_sections.include?(section)
            warnings << "Unknown configuration section: [#{section}]"
          end
        end

        # Value range checks (types already coerced by ConfigManager on load)
        baud_rate = config.dig(:interface, :baud_rate)
        if baud_rate && baud_rate.is_a?(Integer) && baud_rate <= 0
          errors << "interface.baud_rate must be greater than 0 (got #{baud_rate})"
        end

        flash_split = config.dig(:giga_options, :flash_split)
        if flash_split && (flash_split < 0.0 || flash_split > 1.0)
          errors << "giga_options.flash_split must be between 0.0 and 1.0 (got #{flash_split})"
        end

        freq = config.dig(:esp32_options, :frequency)
        if freq && ![80, 160, 240].include?(freq)
          errors << "esp32_options.frequency must be one of [80, 160, 240] (got #{freq})"
        end

        target_core = config.dig(:giga_options, :target_core)
        if target_core && !["CM4", "CM7"].include?(target_core)
          errors << "giga_options.target_core must be 'CM4' or 'CM7' (got '#{target_core}')"
        end

        # Required field checks
        fqbn = config.dig(:basic, :fqbn)
        port = config.dig(:basic, :port)
        errors << "basic.fqbn is not set - run 'grot boards' to see supported boards" unless fqbn
        warnings << "basic.port is not set - required for upload" unless port

        # FQBN and board-specific validation
        if fqbn
          if Grot::Boards::BoardRegistry.supported?(fqbn)
            # Merge fqbn to top level so factory can find the right strategy
            strategy_config = config.merge(fqbn: fqbn)
            strategy = Grot::Boards::BoardStrategyFactory.create_strategy(strategy_config)
            begin
              strategy.validate_config
            rescue => e
              errors << e.message
            end
          else
            errors << "Unknown FQBN '#{fqbn}' - run 'grot boards' to see supported boards"
          end
        end

        # Report all warnings and errors
        warnings.each { |w| warning w }
        errors.each { |e| error e }

        if errors.empty?
          success warnings.empty? ? "Configuration is valid!" : "Configuration is valid (with warnings)."
          0
        else
          1
        end
      end

    end
  end
end