# frozen_string_literal: true

require "grot/boards/strategies/base_board_strategy"

module Grot
  module Boards
    module Strategies
      # Default strategy for boards without special needs
      class DefaultBoardStrategy < BaseBoardStrategy
        def applicable?
          true # This is the fallback strategy
        end
        
        def generate_config_options
          {} # No special options for default boards
        end
        
        def write_config_section(file)
          # No special section needed for default boards
        end
        
        def commented_config_example
          {} # Return empty hash instead of nil for consistency
        end
      end
    end
  end
end