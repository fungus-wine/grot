# frozen_string_literal: true


module Grot
  module Boards
    module Strategies
      # Base class for all board-specific strategies
      class BaseBoardStrategy
        attr_reader :config
        
        def initialize(config)
          @config = config
        end
        
        # Apply board-specific modifications to the command parts
        def customize_board_command(cmd_parts, command)
          # Default implementation does nothing
          # Subclasses should override this method
        end
        
        # Check if this strategy should be used for the given config
        def applicable?
          false # Override in subclasses
        end
        
        # Validate board-specific configuration 
        def validate_config
          # Default implementation does nothing
          # Subclasses should override this method
        end
        
        # Generate default configuration options for this board type
        def generate_config_options
          {} # Override in subclasses to provide board-specific options
        end
        
        # Add board-specific configuration to a config file
        def write_config_section(file)
          # Default implementation does nothing
          # Subclasses should override this method if needed
        end
        
        # Get commented example configuration for this board type
        def commented_config_example
          # Default implementation returns empty hash instead of nil
          # This ensures consistent return types across all methods
          {}
        end
        
        # Get a descriptive name for this board strategy
        def strategy_name
          self.class.name.split('::').last
        end
        
        # Get documentation for this strategy's configuration options
        # Returns a hash with option names as keys and documentation strings as values
        def configuration_docs
          strategy_name = self.class.name.gsub(/.*::/, '').gsub(/Strategy$/, '').downcase
          
          # Return basic config options for this strategy
          {
            strategy_name => generate_config_options
          }
        end
        
        protected
        
        # Helper method to access configuration settings safely
        def get_config_option(section, option, default = nil)
          return default unless config[section]
          config[section][option] || default
        end
        
        # Helper method to check if a configuration section exists
        def has_config_section?(section)
          !config[section].nil? && !config[section].empty?
        end
      end
    end
  end
end
