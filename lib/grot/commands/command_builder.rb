# frozen_string_literal: true

require "grot/boards/board_strategy_factory"
require "grot/commands/command_registry"

module Grot
  module Commands
    # Builder for arduino-cli command strings based on config
    class CommandBuilder
      def build_command(command, config)
        command_definition = CommandRegistry.get_command(command)
        
        # If command isn't a CLI action, return empty string
        # (these commands are handled by custom handlers)
        return "" unless command_definition && !command_definition[:action].is_a?(Proc)
        
        # Start with base command
        cmd_parts = [
          config[:basic][:cli_path],
          command_definition[:action]  # Use action instead of cli_action
        ]
        
        # Add sketch path if required (specified in command definition)
        cmd_parts << config[:basic][:sketch_path] if command_definition[:requires_sketch_path]
        
        # Add standard options
        cmd_parts = add_standard_options(cmd_parts, config, command_definition)
        
        # Apply board-specific modifications if needed
        if command_definition[:board_specific] && config[:basic][:fqbn]
          board_strategy = Boards::BoardStrategyFactory.create_strategy(config)
          board_strategy.customize_board_command(cmd_parts, command)
        end
        
        # Join all parts into a single command string
        cmd_parts.join(' ')
      end
      
      private
      
      def add_standard_options(cmd_parts, config, command_definition)
        # Add FQBN if required and specified in config
        cmd_parts << "--fqbn #{config[:basic][:fqbn]}" if command_definition[:requires_fqbn] && config[:basic][:fqbn]
        
        # Add port if required and specified in config
        cmd_parts << "--port #{config[:basic][:port]}" if command_definition[:requires_port] && config[:basic][:port]
        
        cmd_parts << "--verbose" if command_definition[:verbose]

        cmd_parts
      end
    end
  end
end