# frozen_string_literal: true

module Grot
  module Config
    DEFAULTS = {
      basic: {
        cli_path: "arduino-cli"
      },

      interface: {
        baud_rate: 115200,
        logs_directory: "#{Dir.home}/grot_logs"
      },

      giga_options: {
        target_core: "cm7",
        split: "100_0"
      },

      teensy: {
        loader_path: "teensy_loader_cli"
      }
    }.freeze
  end
end
