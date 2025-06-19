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
          requires_config: false,
          action: ->(app) { Commands::Handlers.version_command(app) }
        },
        "init" => {
          description: "Initialize a new configuration file",
          requires_config: false,
          action: ->(app) { Commands::Handlers.init_command(app) }
        },
        "ports" => {
          description: "List available serial ports",
          requires_config: false,
          action: ->(app) { Commands::Handlers.ports_command(app) }
        },
        "boards" => {
          description: "List supported boards",
          requires_config: false,
          action: ->(app) { Commands::Handlers.boards_command(app) }
        },
        "clean" => {
          description: "Clean arduino-cli cache",
          requires_config: true,
          board_specific: false,
          spinner: true,
          spinner_message: "Cleaning cache",
          spinner_type: :simple,
          spinner_color: :blue,
          post_action: ->(app, cmd) { app.display_executed_command(cmd) },
          action: ->(app, config) { Commands::Handlers.clean_command(app, config) }
        },
        "dump" => {
          description: "Print out configuration info",
          requires_config: false,
          action: ->(app) { Commands::Handlers.dump_command(app) }
        },
        "build" => {
          description: "Compile the sketch",
          requires_config: true,
          requires_fqbn: true,
          requires_sketch_path: true,
          board_specific: true,
          verbose: false,
          spinner: true,
          spinner_message: "Building sketch",
          spinner_type: :dots,
          spinner_color: :green,
          pre_action: ->(app) { puts "Compiling code...\n" },
          post_action: ->(app, cmd) { app.display_executed_command(cmd) },
          action: "compile"
        },
        "load" => {
          description: "Upload sketch to board",
          requires_config: true,
          requires_fqbn: true,
          requires_port: true,
          requires_sketch_path: true,
          board_specific: true,
          verbose: false,
          spinner: true,
          spinner_message: "Uploading to board",
          spinner_type: :line,
          spinner_color: :cyan,
          post_action: ->(app, cmd) { app.display_executed_command(cmd) },
          action: "upload"
        },
        "monitor" => {
          description: "Open serial monitor",
          requires_config: true,
          requires_port: true,
          board_specific: false,
          action: ->(app, config) { Commands::Handlers.monitor_command(app, config) }
        },
        "plotter" => {
          description: "Open serial plotter",
          requires_config: true,
          requires_port: true,
          board_specific: false,
          action: ->(app, config) { Commands::Handlers.plotter_command(app, config) }
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