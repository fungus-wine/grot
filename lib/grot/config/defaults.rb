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

    }.freeze
  end
end
