# frozen_string_literal: true

module Grot
  module Boards
    # Registry of all supported boards with their configuration details
    class BoardRegistry
      # Board definitions
      # Organized by board type for easier maintenance
      BOARD_DEFINITIONS = {
        # Standard Arduino AVR boards
        'arduino:avr:uno' => {
          name: 'Arduino Uno'
        },
        'arduino:avr:mega' => {
          name: 'Arduino Mega or Mega 2560'
        },
        'arduino:avr:nano' => {
          name: 'Arduino Nano'
        },
        'arduino:avr:leonardo' => {
          name: 'Arduino Leonardo'
        },
        'arduino:avr:micro' => {
          name: 'Arduino Micro'
        },
        'arduino:avr:pro' => {
          name: 'Arduino Pro or Pro Mini'
        },
        'arduino:avr:lilypad' => {
          name: 'LilyPad Arduino'
        },
        'arduino:avr:fio' => {
          name: 'Arduino Fio'
        },
        'arduino:avr:ethernet' => {
          name: 'Arduino Ethernet'
        },

        # Arduino SAMD Boards
        'arduino:samd:arduino_zero_native' => {
          name: 'Arduino Zero'
        },
        'arduino:samd:mkr1000' => {
          name: 'Arduino MKR1000'
        },
        'arduino:samd:mkrzero' => {
          name: 'Arduino MKRZero'
        },

        # GIGA boards
        'arduino:mbed_giga:giga' => {
          name: 'Arduino Giga R1',
          fqbn_options: {
            giga_options: { target_core: 'target_core', split: 'split' }
          }
        },

        # ESP32-S3 boards
        'esp32:esp32:adafruit_feather_esp32s3_reversetft' => {
          name: 'Adafruit Feather ESP32-S3 Reverse TFT'
        },
        'esp32:esp32:adafruit_qtpy_esp32s3_n4r2' => {
          name: 'Adafruit QT Py ESP32-S3 (4M Flash 2M PSRAM)'
        },
        'esp32:esp32:adafruit_feather_esp32s3' => {
          name: 'Adafruit Feather ESP32-S3 2MB PSRAM'
        },
        'esp32:esp32:adafruit_feather_esp32s3_nopsram' => {
          name: 'Adafruit Feather ESP32-S3 No PSRAM'
        },
        'esp32:esp32:adafruit_feather_esp32s3_tft' => {
          name: 'Adafruit Feather ESP32-S3 TFT'
        },
        'esp32:esp32:adafruit_metro_esp32s3' => {
          name: 'Adafruit Metro ESP32-S3'
        },
        'esp32:esp32:adafruit_qtpy_esp32s3_nopsram' => {
          name: 'Adafruit QT Py ESP32-S3 No PSRAM'
        },
        'esp32:esp32:esp32s3' => {
          name: 'ESP32S3 Dev Module'
        },
        'esp32:esp32:esp32s3-octal' => {
          name: 'ESP32S3 Dev Module Octal (WROOM2)'
        }

        # Add new boards here following the pattern above
      }.freeze

      # Returns a hash of all supported boards with their details
      def self.supported_boards
        BOARD_DEFINITIONS
      end

      # Get information about a specific board by FQBN
      def self.get_board_info(fqbn)
        supported_boards[fqbn]
      end

      # Get a list of all board names with their FQBNs for display
      def self.list_supported_boards
        supported_boards.map { |fqbn, info| "#{info[:name]} (#{fqbn})" }
      end

      # Check if a board is supported
      def self.supported?(fqbn)
        supported_boards.key?(fqbn)
      end

      # Get the FQBN options spec for a given board
      def self.fqbn_options_for(fqbn)
        info = get_board_info(fqbn)
        info && info[:fqbn_options] ? info[:fqbn_options] : {}
      end
    end
  end
end
