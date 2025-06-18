# frozen_string_literal: true

require "grot/errors"

module Grot
  module Config
    class ConfigValidator
      def initialize(port_handler, board_registry)
        @port_handler = port_handler
        @board_registry = board_registry
      end

      # Validate configuration based on command requirements
      def validate_config(config, command_def)
        # Only validate when command requires config
        return unless command_def && command_def[:requires_config]
        
        validate_required_fields(config)
        
        # Only validate FQBN if required
        validate_fqbn(config) if command_def[:requires_fqbn]
        
        # Use the board-specific strategy for validation if needed
        if command_def[:board_specific]
          board_strategy = Grot::Boards::BoardStrategyFactory.create_strategy(config)
          begin
            board_strategy.validate_config
          rescue => e
            # Convert any errors from strategy validation to BoardStrategyError
            raise Grot::Errors::BoardStrategyError, e.message
          end
        end
        
        # Check if port exists for commands that require it
        if command_def[:requires_port]
          begin
            @port_handler.validate_port(config[:port])
          rescue => e
            raise Grot::Errors::SerialPortError, e.message
          end
        end
      end

      # Validate that all required configuration fields are present
      def validate_required_fields(config)
        required_fields = [:sketch_path, :cli_path, :fqbn]
        
        missing_fields = required_fields.select { |field| config[field].nil? || config[field].to_s.strip.empty? }
        
        unless missing_fields.empty?
          raise Grot::Errors::ConfigurationError, "Missing required field(s) in config: #{missing_fields.join(', ')}"
        end
      end

      # Validate that the specified board is supported
      def validate_fqbn(config)
        unless @board_registry.supported?(config[:fqbn])
          # Suggest similar boards if possible
          similar_boards = find_similar_boards(config[:fqbn])
          
          message = "Invalid board (fqbn) specified: #{config[:fqbn]}"
          
          if similar_boards.any?
            message += "\n\nDid you mean one of these?\n"
            similar_boards.each do |board|
              message += "  - #{board}\n"
            end
          else
            message += "\n\nRun 'grot boards' for a list of all supported boards."
          end
          
          raise Grot::Errors::ConfigurationError, message
        end
      end
      
      private
      
      # Find boards that are similar to the given FQBN
      # This helps provide better error messages
      def find_similar_boards(fqbn)
        return [] unless fqbn
        
        # If we have a vendor part, try to find boards from the same vendor
        if fqbn.include?(':')
          vendor = fqbn.split(':').first
          
          similar = @board_registry.supported_boards.keys.select do |board_fqbn|
            board_fqbn.start_with?("#{vendor}:")
          end
          
          return similar.take(5) if similar.any?
        end
        
        # If no similar boards found, return empty array
        []
      end
    end
  end
end