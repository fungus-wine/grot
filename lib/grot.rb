# frozen_string_literal: true

require "grot/version"
require "grot/errors"
require "grot/debug"

# Config system
require "grot/config/defaults"
require "grot/config/config_manager"

# Board-related requires
require "grot/boards/board_registry"
require "grot/boards/board_strategy_factory"

require "grot/boards/strategies/base_board_strategy"
require "grot/boards/strategies/default_board_strategy"
require "grot/boards/strategies/esp32_s3_board_strategy"
require "grot/boards/strategies/giga_board_strategy"

# CLI-related requires
require "grot/cli/cli_parser"
require "grot/cli/colorator"
require "grot/cli/progress_display"

# Command-related requires
require "grot/commands/command_registry"
require "grot/commands/command_builder"
require "grot/commands/command_handlers"

# Hardware-related requires
require "grot/ports/port_handler"

# Main app class
require "grot/app"

module Grot
  class Error < StandardError; end
  
  # Convenience method to create a new app instance and run it
  def self.run(args = ARGV)
    app = App.new
    ARGV.replace(args) unless args == ARGV
    app.run
  end
end