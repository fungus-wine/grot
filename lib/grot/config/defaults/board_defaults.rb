# frozen_string_literal: true

require_relative '../config_registry'
require 'grot/boards/board_registry'

module Grot
  module Config
    module Defaults

      module BoardDefaults
        def self.load_defaults(registry = ConfigRegistry.instance)
          # Define board-specific categories
          registry.define_category(:esp32_options, "ESP32-S3 board configuration")
          registry.define_category(:giga_options, "GIGA board configuration")
          
          # Load ESP32-S3 board options
          load_esp32_options(registry)
          
          # Load GIGA board options
          load_giga_options(registry)
          
          # Add FQBN validation
          add_fqbn_validation(registry)
        end
        
        def self.load_esp32_options(registry)
          # Extract defaults from BoardRegistry.STRATEGY_TEMPLATES
          defaults = Grot::Boards::BoardRegistry::STRATEGY_TEMPLATES['esp32_s3']
          
          # Valid options for configuration
          valid_core_configs = ['dual', 'single-0', 'single-1']
          valid_frequencies = [80, 160, 240]
          
          # Add options with validation
          registry.add_option(
            :esp32_options,
            :core_config,
            :string,
            defaults[:core_config],
            "How to use ESP32-S3 cores (dual, single-0, single-1)",
            ->(value) { 
              unless valid_core_configs.include?(value)
                return [nil, "core_config must be one of: #{valid_core_configs.join(', ')}"]
              end
              [value, nil]
            }
          )
          
          registry.add_option(
            :esp32_options,
            :frequency,
            :integer,
            defaults[:frequency].to_i,
            "CPU frequency in MHz (80, 160, 240)",
            ->(value) {
              value = value.to_i
              unless valid_frequencies.include?(value)
                return [nil, "frequency must be one of: #{valid_frequencies.join(', ')}"]
              end
              [value, nil]
            }
          )
        end
        
        def self.load_giga_options(registry)
          # Extract defaults from BoardRegistry.STRATEGY_TEMPLATES
          defaults = Grot::Boards::BoardRegistry::STRATEGY_TEMPLATES['giga']
          
          # Valid options
          valid_cores = ['CM4', 'CM7']
          
          # Add options with validation
          registry.add_option(
            :giga_options,
            :target_core, 
            :string,
            defaults[:target_core],
            "Target processor core (CM4 or CM7)",
            ->(value) {
              unless valid_cores.include?(value)
                return [nil, "target_core must be one of: #{valid_cores.join(', ')}"]
              end
              [value, nil]
            }
          )
          
          registry.add_option(
            :giga_options,
            :flash_split,
            :float,
            defaults[:flash_split].to_f,
            "Memory allocation between cores (0.0-1.0, fraction available to the M7 core)",
            ->(value) {
              value = value.to_f
              unless value >= 0.0 && value <= 1.0
                return [nil, "flash_split must be between 0.0 and 1.0"]
              end
              [value, nil]
            }
          )
        end
        
        def self.add_fqbn_validation(registry)
          # Get the basic.fqbn option and add board-specific validation
          fqbn_option = registry[:basic][:fqbn]
          
          # Replace the validation with one that checks for valid boards
          if fqbn_option
            fqbn_option.instance_variable_set(
              :@validation, 
              ->(value) {
                # Skip validation if nil (will be caught elsewhere if required)
                return [value, nil] if value.nil?
                
                # Check if board is supported
                unless Grot::Boards::BoardRegistry.supported?(value)
                  # Try to find similar boards
                  similar_boards = find_similar_boards(value)
                  suggestion = ""
                  
                  if similar_boards.any?
                    suggestion = "\n\nDid you mean one of these?\n" +
                                similar_boards.map { |b| "  - #{b}" }.join("\n")
                  else
                    suggestion = "\n\nRun 'grot boards' for a list of all supported boards."
                  end
                  
                  return [nil, "Invalid board (fqbn) specified: #{value}#{suggestion}"]
                end
                
                [value, nil]
              }
            )
          end
        end
        
        def self.find_similar_boards(fqbn)
          return [] unless fqbn
          
          # If we have a vendor part, try to find boards from the same vendor
          if fqbn.include?(':')
            vendor = fqbn.split(':').first
            
            similar = Grot::Boards::BoardRegistry.supported_boards.keys.select do |board_fqbn|
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
end

# Load the defaults when this file is required
Grot::Config::Defaults::BoardDefaults.load_defaults