# frozen_string_literal: true

require "grot/boards/strategies/base_board_strategy"
require "grot/boards/board_registry"
require "grot/cli/progress_display"
require "grot/errors"
require "open3"

module Grot
  module Boards
    module Strategies
      # Strategy for ESP32-S3 based boards
      class ESP32S3BoardStrategy < BaseBoardStrategy
        include Grot::CLI::Colorator
        
        attr_reader :last_executed_compile_cmd
        
        # Valid options for configuration
        VALID_CORE_CONFIGS = ['dual', 'single-0', 'single-1'].freeze
        VALID_FREQUENCIES = [80, 160, 240].freeze
        
        def applicable?
          BoardRegistry.get_board_info(config[:fqbn])&.dig(:strategy) == 'esp32_s3'
        end
        
        def customize_board_command(cmd_parts, command)
          command_definition = Grot::Commands::CommandRegistry.get_command(command)
          
          # Skip board-specific modifications if not required
          return if command_definition[:board_specific] == false
          
          if command == 'load'
            # For upload command, ensure compilation happened with the right properties
            ensure_compiled if has_config_section?(:esp32_options)
          else
            # For compilation commands, add ESP32-S3 specific build properties
            add_esp32_s3_build_properties(cmd_parts) if has_config_section?(:esp32_options)
          end
        end
        
        def validate_config
          validate_esp32_s3_options if has_config_section?(:esp32_options)
        end
        
        def generate_config_options
          # Return default config options for ESP32-S3 board
          {
            core_config: 'dual',
            frequency: 240
          }
        end
        
        def write_config_section(file)
          options = generate_config_options
          
          file.puts "esp32_options:"
          file.puts "  core_config: #{options[:core_config]}"
          file.puts "  frequency: #{options[:frequency]}"
        end
        
        def commented_config_example
          {
            :esp32_options => generate_config_options
          }
        end
        
        # Documentation for ESP32-S3 configuration options
        def configuration_docs
          {
            esp32_options: {
              description: 'ESP32-S3 boards',
              options: {
                core_config: 'How to use cores (dual, single-0, single-1)',
                frequency: 'CPU frequency in MHz (80, 160, 240)'
              }
            }
          }
        end
        
        private
        
        def validate_esp32_s3_options
          # Validate core_config
          core_config = get_config_option(:esp32_options, :core_config)
          if core_config && !VALID_CORE_CONFIGS.include?(core_config)
            raise Grot::Errors::BoardStrategyError, "For ESP32-S3, core_config must be one of: #{VALID_CORE_CONFIGS.map { |c| "'#{c}'" }.join(', ')}"
          end
          
          # Validate frequency
          frequency = get_config_option(:esp32_options, :frequency)
          if frequency
            frequency = frequency.to_i
            unless VALID_FREQUENCIES.include?(frequency)
              raise Grot::Errors::BoardStrategyError, "For ESP32-S3, frequency must be one of: #{VALID_FREQUENCIES.join(', ')}"
            end
          end
        end
        
        def ensure_compiled
          # Build compile command
          compile_cmd_parts = [
            config[:cli_path],
            "compile",
            config[:sketch_path],
            "--fqbn #{config[:fqbn]}"
          ]
          
          # Add ESP32-S3 specific build properties
          add_esp32_s3_build_properties(compile_cmd_parts)
          
          # Join the command parts
          compile_cmd = compile_cmd_parts.join(' ')
          
          # Execute compilation with spinner
          puts "Compiling ESP32-S3 code before upload..."
          
          # Create and start spinner
          spinner = CLI::ProgressDisplay::Spinner.new("Compiling for ESP32-S3", :green)
          spinner.start
          
          begin
            # Use Open3 to capture output
            stdout, stderr, status = Open3.capture3(compile_cmd)
            
            # Stop spinner with status
            spinner.stop(status.success?)
            
            # Strip any ANSI color codes
            stdout = stdout.gsub(/\e\[[0-9;]*m/, '')
            stderr = stderr.gsub(/\e\[[0-9;]*m/, '')
            
            # Print output in grey
            puts colorize(stdout, :grey) unless stdout.empty?
            puts colorize(stderr, :grey) unless stderr.empty?
            
            unless status.success?
              raise Grot::Errors::BoardStrategyError, "Compilation failed with exit code: #{status.exitstatus}"
            end
            
            puts "Compilation successful, proceeding with upload..."
            
            # We'll display the executed command at the very end of the complete process
            # Store the command in a class variable so App can display it later
            @last_executed_compile_cmd = compile_cmd
          rescue => e
            # Ensure spinner is stopped on error
            spinner.stop(false)
            raise e
          end
        end
        
        def add_esp32_s3_build_properties(cmd_parts)
          # Get config options with fallbacks to defaults
          core_config = get_config_option(:esp32_options, :core_config) || 'dual'
          frequency = get_config_option(:esp32_options, :frequency) || 240
          
          # Add build properties to command
          cmd_parts << "--build-property esp32.cores=#{core_config}"
          cmd_parts << "--build-property esp32.frequency=#{frequency}"
        end
      end
    end
  end
end
