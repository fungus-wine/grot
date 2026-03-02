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

      giga_options: {
        target_core: "cm7",
        split: "50_50"
      }
    }.freeze
  end
end
