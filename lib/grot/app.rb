# frozen_string_literal: true

require "grot/version"
require "grot/errors"
require "grot/cli/cli_parser"
require "grot/cli/colorator"
require "grot/cli/progress_display"
require "grot/commands/command_registry"
require "grot/commands/command_builder"
require "grot/commands/command_handlers"
require "grot/config/config_manager"
require "grot/config/config_registry"
require "grot/ports/port_handler"
require "grot/boards/board_registry"
require "grot/boards/board_strategy_factory"
require "open3"
require "timeout"

module Grot
  # Main application class for Grot
  class App
    include Grot::CLI::Colorator
    attr_reader :options, :config, :port_handler
    
    # Default command timeout in seconds
    COMMAND_TIMEOUT = 300
    
    def initialize
      @options = {
        command: nil,
        config_file: default_config_filename
      }
      
      initialize_components
    end
    
    def run
      parse_options
      
      # Handle no command case
      if @options[:command].nil?
        show_no_command_error
        return 1
      end
      
      # Get command definition from registry
      command_name = @options[:command]
      command_definition = get_command_definition(command_name)
      
      if command_definition.nil?
        error "Error: Unknown command: #{command_name}"
        puts "Run with -h for help."
        return 1
      end
      
      # Process command
      begin
        handle_command(command_name, command_definition)
      rescue Grot::Errors::ConfigurationError => e
        error "Configuration error: #{e.message}"
        info "You may need to run 'grot init' to create or fix your configuration."
        return 1
      rescue Grot::Errors::BoardStrategyError => e
        error "Board configuration error: #{e.message}"
        info "Check your board settings in the configuration file."
        return 1
      rescue Grot::Errors::SerialPortError => e
        error "Serial port error: #{e.message}"
        info "Run 'grot ports' to see available ports."
        return 1
      rescue Grot::Errors::CommandExecutionError => e
        error "Command execution error: #{e.message}"
        return 1
      rescue Grot::Errors::CommandError => e
        error "Command error: #{e.message}"
        return 1
      rescue Grot::Errors::GrotError => e
        error "Error: #{e.message}"
        return 1
      rescue => e
        error "Unexpected error: #{e.message}"
        return 1
      end
    end
    
    # Display executed command (used by post_action)
    # This must be public so it can be called by command post_actions
    def display_executed_command(cmd)
      command("Executed: #{cmd}")
    end
    
    private
    
    def initialize_components
      @cli_parser = CLI::CLIParser.new(@options)
      @config_manager = Config::ConfigManager.new
      @command_builder = Commands::CommandBuilder.new
      @port_handler = Ports::PortHandler.new
      
      # Initialize default config registry if it hasn't been initialized yet
      Config::ConfigRegistry.init_defaults if Config::ConfigRegistry.instance.categories.empty?
    end
    
    def parse_options
      @cli_parser.parse
    end
    
    def default_config_filename
      # Use TOML extension by default
      File.basename(Dir.pwd) + ".toml"
    end
    
    # Command handling methods
    
    def show_no_command_error
      puts "Available commands"
      separator
      Commands::CommandRegistry.list_commands.each do |cmd, desc|
        puts "  #{cmd.ljust(14)} #{desc}"
      end
      puts "Run with -h for help."
    end
    
    def handle_command(command_name, command_definition)
      # Load config if required
      if command_definition[:requires_config]
        return 1 unless load_config_successfully?
        validate_config(command_definition)
      end
      
      # Create board strategy if needed for later use
      board_strategy = nil
      if command_definition[:board_specific] && @config && @config.dig(:basic, :fqbn)
        board_strategy = Boards::BoardStrategyFactory.create_strategy(@config)
      end
      
      # Execute the command
      result = nil
      cmd = nil
      if command_definition[:action]
        # Run pre_action if it exists
        if command_definition[:pre_action]
          command_definition[:pre_action].call(self)
        end
        
        # Check if it's a proc (custom handler) or a string (CLI command)
        if command_definition[:action].is_a?(Proc)
          # Pass config to handler only if it's required
          if command_definition[:requires_config]
            result = command_definition[:action].call(self, @config)
            # For handlers that may have set a last executed command
            cmd = @last_executed_command if instance_variable_defined?(:@last_executed_command)
          else
            result = command_definition[:action].call(self)
          end
        else
          # It's a CLI command string
          config_to_use = command_definition[:requires_config] ? @config : {}
          cmd = @command_builder.build_command(command_name, config_to_use)
          result = execute_cli_command(command_name, cmd)
        end
        
        # Run post_action if it exists
        if command_definition[:post_action] && cmd
          command_definition[:post_action].call(self, cmd)
        end
      else
        raise Grot::Errors::CommandError, "Command #{command_name} has no action defined"
      end
      
      # If we have a board strategy that executed a compilation command internally,
      # display it now at the very end
      if board_strategy && board_strategy.respond_to?(:last_executed_compile_cmd) && 
         board_strategy.last_executed_compile_cmd
        puts ""
        display_executed_command(board_strategy.last_executed_compile_cmd)
      end
      
      return result
    end
    
    # Config handling methods
    
    def load_config_successfully?
      if File.exist?(@options[:config_file])
        begin
          @config = @config_manager.load_config(@options[:config_file])
          return true
        rescue TomlRB::ParseError => e
          error "Error parsing config file: #{e.message}"
          info "Check your TOML syntax in #{@options[:config_file]}"
          return false
        rescue => e
          error "Unexpected error loading config: #{e.message}"
          return false
        end
      else
        error "No config file found. Create one with grot init."
        return false
      end
    end
    
    def validate_config(command_definition)
      @config_manager.validate_config(@config, command_definition)
    end
    
    # Command execution methods
    
    def get_command_definition(command)
      Commands::CommandRegistry.get_command(command)
    end
    
    def execute_cli_command(command, cmd)
      begin
        # Get the command definition to check for configuration
        command_definition = Commands::CommandRegistry.get_command(command)
        use_spinner = command_definition.key?(:spinner) ? command_definition[:spinner] : false
        real_time_output = command_definition.key?(:real_time_output) && command_definition[:real_time_output]
        
        # Use timeout to prevent hanging forever
        Timeout.timeout(COMMAND_TIMEOUT) do
          if real_time_output
            # For commands that need real-time output (like monitor)
            execute_with_real_time_output(cmd)
          elsif use_spinner
            execute_with_spinner(command, cmd)
          else
            execute_without_spinner(cmd)
          end
        end
      rescue Timeout::Error
        raise Grot::Errors::CommandExecutionError, "Command timed out after #{COMMAND_TIMEOUT} seconds"
      rescue => e
        raise Grot::Errors::CommandExecutionError, "Failed to execute command: #{e.message}"
      end
    end

    def execute_with_spinner(command, cmd)
      command_def = Commands::CommandRegistry.get_command(command)
      spinner_message = command_def[:spinner_message] || "Running #{command}..."
      spinner_type = command_def[:spinner_type] || :dots
      spinner_color = command_def[:spinner_color] || :cyan
      
      # Create and start spinner
      spinner = CLI::ProgressDisplay::Spinner.new(spinner_message, spinner_type, spinner_color)
      spinner.start
      
      begin
        # Execute command and capture output
        stdout, stderr, status = Open3.capture3(cmd)
        
        # Stop spinner with status
        spinner.stop(status.success?)
        
        # Strip any ANSI color codes that might be in the output
        stdout = stdout.gsub(/\e\[[0-9;]*m/, '')
        stderr = stderr.gsub(/\e\[[0-9;]*m/, '')
        
        # Print all output in grey
        puts colorize(stdout, :grey) unless stdout.empty?
        puts colorize(stderr, :grey) unless stderr.empty?
        
        # Handle non-zero exit status
        unless status.success?
          if stderr.empty?
            stderr = "Command failed with no error output"
          end
          
          error "Command failed with exit status: #{status.exitstatus}"
        end
        
        return status.exitstatus
      rescue => e
        # Ensure spinner is stopped on error
        spinner.stop(false)
        raise e
      end
    end

    def execute_without_spinner(cmd)
      # Original implementation without spinner
      stdout, stderr, status = Open3.capture3(cmd)

      # Strip any ANSI color codes
      stdout = stdout.gsub(/\e\[[0-9;]*m/, '')
      stderr = stderr.gsub(/\e\[[0-9;]*m/, '')

      # Print all output in grey
      puts colorize(stdout, :grey) unless stdout.empty?
      puts colorize(stderr, :grey) unless stderr.empty?
      
      # Handle non-zero exit status
      unless status.success?
        if stderr.empty?
          stderr = "Command failed with no error output"
        end
        
        case status.exitstatus
        when 0
          success "Command completed with exit status: #{status.exitstatus}"
        when 1
          error "Command failed with exit status: #{status.exitstatus}"
        else
          puts "Command completed with exit status: #{status.exitstatus}"
        end
      end
      
      return status.exitstatus
    end
    
    # New method for real-time output execution
    def execute_with_real_time_output(cmd)
      begin
        exit_status = nil
        Open3.popen2e(cmd) do |stdin, stdout_and_stderr, wait_thread|
          while line = stdout_and_stderr.gets
            print colorize(line, :grey)
            $stdout.flush # Ensure immediate display
          end
          exit_status = wait_thread.value.exitstatus
        end
        
        # Handle non-zero exit status
        unless exit_status == 0
          error "Command failed with exit status: #{exit_status}"
        end
        
        return exit_status
      rescue Interrupt
        # Handle Ctrl+C gracefully
        puts "\nCommand interrupted"
        return 130
      end
    end
  end
end
