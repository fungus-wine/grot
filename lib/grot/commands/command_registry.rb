# frozen_string_literal: true

require "grot/commands/command_handlers"

module Grot
  module Commands
    # Registry of available commands and their configurations
    class CommandRegistry
      # Map of command names to their definitions
      COMMANDS = {
        # Commands that don't require config
        "version" => {
          description: "Show version information",
          action: ->(app) { Commands::Handlers.version_command(app) }
        },
        "init" => {
          description: "Initialize a new configuration file",
          action: ->(app) { Commands::Handlers.init_command(app) }
        },
        "ports" => {
          description: "List available serial ports",
          action: ->(app) { Commands::Handlers.ports_command(app) }
        },
        "boards" => {
          description: "List supported boards",
          action: ->(app) { Commands::Handlers.boards_command(app) }
        },
        "clean" => {
          description: "Clean arduino-cli cache",
          requirements: [:config],
          spinner_message: "Cleaning cache",
          post_action: ->(app, cmd) { app.display_executed_command(cmd) },
          action: ->(app, config) { Commands::Handlers.clean_command(app, config) }
        },
        "dump" => {
          description: "Print out configuration info",
          action: ->(app) { Commands::Handlers.dump_command(app) }
        },
        "build" => {
          description: "Compile the sketch",
          requirements: [:config, :fqbn, :sketch_path],
          verbose: false,
          spinner_message: "Building sketch",
          pre_action: ->(app) { puts "Compiling code...\n" },
          post_action: ->(app, cmd) { app.display_executed_command(cmd) },
          action: "compile"
        },
        "load" => {
          description: "Upload sketch to board",
          requirements: [:config, :fqbn, :port, :sketch_path],
          verbose: false,
          spinner_message: "Uploading to board",
          post_action: ->(app, cmd) { app.display_executed_command(cmd) },
          action: "upload"
        },
        "validate" => {
          description: "Validate configuration file",
          requirements: [:config],
          action: ->(app, config) { Commands::Handlers.validate_command(app, config) }
        }
      }.freeze
      
      # Get command definition by name
      def self.get_command(cmd_name)
        COMMANDS[cmd_name]
      end
      
      # List all commands with descriptions
      def self.list_commands
        COMMANDS.map { |cmd, def_hash| [cmd, def_hash[:description]] }
      end
    end
  end
end