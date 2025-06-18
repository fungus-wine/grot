# frozen_string_literal: true

require "optparse"
require "grot/version"
require "grot/commands/command_registry"

module Grot
  module CLI
    class CLIParser
      def initialize(options)
        @options = options
      end
      
      def parse
        parser = OptionParser.new do |opts|
          opts.banner = "Usage: grot [options] COMMAND"
          opts.separator ""
          opts.separator "Commands:"
          
          Grot::Commands::CommandRegistry.list_commands.each do |cmd, desc|
            opts.separator "  #{cmd.ljust(14)} #{desc}"
          end
          
          opts.separator ""
          opts.separator "Options:"
          
          opts.on("-c", "--config CONFIG_FILE", "Specify config file (default: ./[directory_name].toml)") do |file|
            @options[:config_file] = file
          end
          
          opts.on("-h", "--help", "Show this help message") do
            puts opts
            exit
          end
          
          opts.on("-v", "--version", "Show version") do
            puts "grot version #{Grot::VERSION}"
            exit
          end
        end
        
        parser.parse!
        
        # Get the command from the remaining arguments
        @options[:command] = ARGV.shift
      end
    end
  end
end