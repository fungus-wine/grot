# frozen_string_literal: true

require "grot/boards/board_registry"
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
        requirements = command_definition[:requirements] || []
        cmd_parts << config[:basic][:sketch_path] if requirements.include?(:sketch_path)

        # Add standard options
        cmd_parts = add_standard_options(cmd_parts, config, command_definition)

        # Append board-specific FQBN options if needed
        requirements = command_definition[:requirements] || []
        if requirements.include?(:fqbn) && config[:basic][:fqbn]
          append_fqbn_options(cmd_parts, config)
        end

        # Join all parts into a single command string
        cmd_parts.join(' ')
      end

      private

      def add_standard_options(cmd_parts, config, command_definition)
        requirements = command_definition[:requirements] || []

        # Add FQBN if required and specified in config
        cmd_parts << "--fqbn #{config[:basic][:fqbn]}" if requirements.include?(:fqbn) && config[:basic][:fqbn]

        # Add port if required and specified in config
        cmd_parts << "--port #{config[:basic][:port]}" if requirements.include?(:port) && config[:basic][:port]

        cmd_parts << "--verbose" if command_definition[:verbose]

        cmd_parts
      end

      def append_fqbn_options(cmd_parts, config)
        fqbn = config[:basic][:fqbn]
        options_spec = Boards::BoardRegistry.fqbn_options_for(fqbn)
        return if options_spec.empty?

        # Build options string from config values
        option_parts = []
        options_spec.each do |config_section, mappings|
          mappings.each do |config_key, fqbn_option_name|
            value = config.dig(config_section, config_key)
            option_parts << "#{fqbn_option_name}=#{value}" if value
          end
        end

        return if option_parts.empty?

        # Find the --fqbn entry and append options
        fqbn_index = cmd_parts.index { |part| part.start_with?("--fqbn ") }
        if fqbn_index
          cmd_parts[fqbn_index] = "#{cmd_parts[fqbn_index]}:#{option_parts.join(',')}"
        end
      end
    end
  end
end
