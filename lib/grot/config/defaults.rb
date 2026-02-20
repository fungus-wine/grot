# frozen_string_literal: true

module Grot
  module Config
    DEFAULTS = {
      basic: {
        cli_path: "arduino-cli"
      },

      interface: {
        baud_rate: 9600,
        logs_directory: "#{Dir.home}/grot_logs"
      },

      # Board-specific defaults
      esp32_options: {
        core_config: "dual",
        frequency: 240
      },

      giga_options: {
        target_core: "CM7",
        flash_split: 0.5
      }
    }.freeze
  end
end