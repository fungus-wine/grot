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

      def self.monitor_command(app, config)
        begin
          require 'grot/interfaces/monitor_interface'
          
          # Validate required config
          unless config.dig(:basic, :port)
            raise Grot::Errors::ConfigurationError, "Serial port not specified in config"
          end
          
          # Launch monitor window
          window = Grot::Interfaces::MonitorInterface.new(config)
          window.show
          
          return 0

        rescue Grot::Errors::ConfigurationError => e
          error "Configuration error: #{e.message}"
          info "Specify a serial port in your config file."
          return 1
        rescue => e
          error "Error starting monitor: #{e.message}"
          return 1
        end
      end

      def self.plotter_command(app, config)
        begin
          require 'grot/interfaces/plotter_interface'
          
          # Validate required config
          unless config.dig(:basic, :port)
            raise Grot::Errors::ConfigurationError, "Serial port not specified in config"
          end
          
          # Launch plotter window
          window = Grot::Interfaces::PlotterInterface.new(config)
          window.show
          
          return 0

        rescue Grot::Errors::ConfigurationError => e
          error "Configuration error: #{e.message}"
          info "Specify a serial port in your config file."
          return 1
        rescue LoadError => e
          error "Missing dependency: #{e.message}"
          info "Make sure you have the gosu gem installed: gem install gosu"
          return 1
        rescue => e
          error "Error starting plotter: #{e.message}"
          return 1
        end
      end

    end
  end
end