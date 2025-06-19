# frozen_string_literal: true

require "grot/boards/strategies/base_board_strategy"
require "grot/boards/board_registry"
require "grot/cli/progress_display"
require "grot/errors"
require "open3"

module Grot
  module Boards
    module Strategies
      # Strategy for Arduino GIGA R1 WiFi board
      class GigaBoardStrategy < BaseBoardStrategy
        include Grot::CLI::Colorator
        
        attr_reader :last_executed_compile_cmd
        
        def applicable?
          BoardRegistry.get_board_info(config[:fqbn])&.dig(:strategy) == 'giga'
        end
        
        def customize_board_command(cmd_parts, command)
          command_definition = Grot::Commands::CommandRegistry.get_command(command)
          
          # Skip board-specific modifications if not required
          return if command_definition[:board_specific] == false
          
          if command == 'load'
            # For upload commands, we need to ensure compilation happened with the right properties
            ensure_compiled
          else
            # For compilation commands, add build properties
            add_giga_build_properties(cmd_parts)
          end
        end
        
        def validate_config
          validate_target_core
          validate_flash_split
        end
        
        def generate_config_options
          # Return default config options for GIGA board
          {
            target_core: 'CM7',
            flash_split: 0.5
          }
        end
        
        def write_config_section(file)
          options = generate_config_options
          
          file.puts "giga_options:"
          file.puts "  target_core: #{options[:target_core]}"
          file.puts "  flash_split: #{options[:flash_split]}"
        end
        
        def commented_config_example
          {
            :giga_options => generate_config_options
          }
        end
        
        # Documentation for GIGA board configuration options
        def configuration_docs
          {
            giga_options: {
              description: 'GIGA R1 WiFi boards',
              options: {
                target_core: 'Target processor core (CM4 or CM7)',
                flash_split: 'Memory allocation between cores (0.0 - 1.0) This is the fraction available to the M7 core'
              }
            }
          }
        end
        
        private
        
        def validate_target_core
          target_core = get_config_option(:giga_options, :target_core)
          
          unless target_core && ['CM4', 'CM7'].include?(target_core)
            raise Grot::Errors::BoardStrategyError, "For GIGA R1 WiFi, target_core must be either 'CM4' or 'CM7'"
          end
        end
        
        def validate_flash_split
          flash_split = get_config_option(:giga_options, :flash_split)
          
          unless flash_split && flash_split.to_f >= 0.0 && flash_split.to_f <= 1.0
            raise Grot::Errors::BoardStrategyError, "For GIGA R1 WiFi, flash_split must be specified (0.0 - 1.0)"
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
          
          # Add the GIGA-specific build properties
          add_giga_build_properties(compile_cmd_parts)
          
          # Join the command parts
          compile_cmd = compile_cmd_parts.join(' ')
          
          # Execute compilation with spinner
          puts "Compiling GIGA R1 code before upload..."
          
          # Create and start spinner
          spinner = CLI::ProgressDisplay::Spinner.new("Compiling for GIGA", :dots, :blue)
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

        def add_giga_build_properties(cmd_parts)
          # Get target_core with fallback to default
          target_core = get_config_option(:giga_options, :target_core) || 'CM7'
          
          # Add to command
          cmd_parts << "--build-property build.core.#{target_core}=true"
          
          # Get flash_split with fallback to default
          flash_split = get_config_option(:giga_options, :flash_split) || 0.5
          
          # Add to command
          cmd_parts << "--build-property build.flash.split=#{flash_split}"
        end
      end
    end
  end
end
