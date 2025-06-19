# frozen_string_literal: true

require "grot/version"
require "grot/errors"
require "grot/debug"

# Config system
require "grot/config/config_option"
require "grot/config/config_category"
require "grot/config/config_registry"

# Load all configuration defaults
require "grot/config/defaults/board_defaults"
require "grot/config/defaults/keyboard_defaults"
require "grot/config/defaults/interface_defaults"

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

# Keyboard system
require 'grot/keyboard/key_event'
require 'grot/keyboard/module_base'
require 'grot/keyboard/module_registry'
require 'grot/keyboard/event_bus'
require 'grot/keyboard/key_constants'
require 'grot/keyboard/keyboard_manager'
require 'grot/keyboard/module_provider'

require 'grot/keyboard/providers/key_state_provider'
require 'grot/keyboard/providers/stuck_key_fixer_provider'
require 'grot/keyboard/providers/mac_adapter_provider'
require 'grot/keyboard/providers/buffer_provider'
require 'grot/keyboard/providers/debouncer_provider'

require 'grot/keyboard/modules/key_state_module'
require 'grot/keyboard/modules/stuck_key_fixer_module'
require 'grot/keyboard/modules/mac_adapter_module'
require 'grot/keyboard/modules/buffer_module'
require 'grot/keyboard/modules/debouncer_module'

# Interface modules
require 'grot/interfaces/base_interface'
require 'grot/interfaces/monitor_interface'
require 'grot/interfaces/plotter_interface'

require 'grot/interfaces/utils/drawing_kit'
require 'grot/interfaces/utils/theme_manager'

require 'grot/interfaces/components/command_bar'
require 'grot/interfaces/components/plotter_component'

require 'grot/interfaces/models/serial_connection'
require 'grot/interfaces/models/serial_data_parser'
require 'grot/interfaces/models/data_buffer_manager'

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