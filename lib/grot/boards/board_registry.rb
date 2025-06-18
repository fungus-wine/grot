# frozen_string_literal: true

module Grot
  module Boards
    # Registry of all supported boards with their configuration details
    class BoardRegistry
      # Strategy-specific configuration templates
      STRATEGY_TEMPLATES = {
        # Default options for ESP32-S3 boards
        'esp32_s3' => {
          :core_config => 'dual',
          :frequency => '240'
        },
        # Default options for GIGA boards
        'giga' => {
          :target_core => 'CM7',
          :flash_split => 1.0
        }
      }.freeze

      # Board definitions
      # Organized by board type for easier maintenance
      BOARD_DEFINITIONS = {
        # Standard Arduino AVR boards
        'arduino:avr:uno' => {
          name: 'Arduino Uno',
          strategy: 'default'
        },
        'arduino:avr:mega' => {
          name: 'Arduino Mega or Mega 2560',
          strategy: 'default'
        },
        'arduino:avr:nano' => {
          name: 'Arduino Nano',
          strategy: 'default'
        },
        'arduino:avr:leonardo' => {
          name: 'Arduino Leonardo',
          strategy: 'default'
        },
        'arduino:avr:micro' => {
          name: 'Arduino Micro',
          strategy: 'default'
        },
        'arduino:avr:pro' => {
          name: 'Arduino Pro or Pro Mini',
          strategy: 'default'
        },
        'arduino:avr:lilypad' => {
          name: 'LilyPad Arduino',
          strategy: 'default'
        },
        'arduino:avr:fio' => {
          name: 'Arduino Fio',
          strategy: 'default'
        },
        'arduino:avr:ethernet' => {
          name: 'Arduino Ethernet',
          strategy: 'default'
        },
        
        # Arduino SAMD Boards
        'arduino:samd:arduino_zero_native' => {
          name: 'Arduino Zero',
          strategy: 'default'
        },
        'arduino:samd:mkr1000' => {
          name: 'Arduino MKR1000',
          strategy: 'default'
        },
        'arduino:samd:mkrzero' => {
          name: 'Arduino MKRZero',
          strategy: 'default'
        },
        
        # GIGA boards
        'arduino:mbed_giga:giga' => {
          name: 'Arduino Giga R1',
          strategy: 'giga',
          # Reference the template rather than duplicating values
          config_options: STRATEGY_TEMPLATES['giga'].dup
        },
        
        # ESP32-S3 boards
        'esp32:esp32:adafruit_feather_esp32s3_reversetft' => {
          name: 'Adafruit Feather ESP32-S3 Reverse TFT',
          strategy: 'esp32_s3',
          config_options: STRATEGY_TEMPLATES['esp32_s3'].dup
        },
        'esp32:esp32:adafruit_qtpy_esp32s3_n4r2' => {
          name: 'Adafruit QT Py ESP32-S3 (4M Flash 2M PSRAM)',
          strategy: 'esp32_s3',
          config_options: STRATEGY_TEMPLATES['esp32_s3'].dup
        },
        'esp32:esp32:adafruit_feather_esp32s3' => {
          name: 'Adafruit Feather ESP32-S3 2MB PSRAM',
          strategy: 'esp32_s3',
          config_options: STRATEGY_TEMPLATES['esp32_s3'].dup
        },
        'esp32:esp32:adafruit_feather_esp32s3_nopsram' => {
          name: 'Adafruit Feather ESP32-S3 No PSRAM',
          strategy: 'esp32_s3',
          config_options: STRATEGY_TEMPLATES['esp32_s3'].dup
        },
        'esp32:esp32:adafruit_feather_esp32s3_tft' => {
          name: 'Adafruit Feather ESP32-S3 TFT',
          strategy: 'esp32_s3',
          config_options: STRATEGY_TEMPLATES['esp32_s3'].dup
        },
        'esp32:esp32:adafruit_metro_esp32s3' => {
          name: 'Adafruit Metro ESP32-S3',
          strategy: 'esp32_s3',
          config_options: STRATEGY_TEMPLATES['esp32_s3'].dup
        },
        'esp32:esp32:adafruit_qtpy_esp32s3_nopsram' => {
          name: 'Adafruit QT Py ESP32-S3 No PSRAM',
          strategy: 'esp32_s3',
          config_options: STRATEGY_TEMPLATES['esp32_s3'].dup
        },
        'esp32:esp32:esp32s3' => {
          name: 'ESP32S3 Dev Module',
          strategy: 'esp32_s3',
          config_options: STRATEGY_TEMPLATES['esp32_s3'].dup
        },
        'esp32:esp32:esp32s3-octal' => {
          name: 'ESP32S3 Dev Module Octal (WROOM2)',
          strategy: 'esp32_s3',
          config_options: STRATEGY_TEMPLATES['esp32_s3'].dup
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

      # Get all boards that use a specific strategy
      def self.get_boards_by_strategy(strategy)
        supported_boards.select { |_, info| info[:strategy] == strategy }
      end

      # Get a list of all board names with their FQBNs for display
      def self.list_supported_boards
        supported_boards.map { |fqbn, info| "#{info[:name]} (#{fqbn})" }
      end

      # Check if a board is supported
      def self.supported?(fqbn)
        supported_boards.key?(fqbn)
      end

      # Get the appropriate strategy name for a given FQBN
      def self.strategy_for(fqbn)
        info = get_board_info(fqbn)
        info ? info[:strategy] : 'default'
      end

      # Get the config options template for a given FQBN
      def self.config_options_for(fqbn)
        info = get_board_info(fqbn)
        info && info[:config_options] ? info[:config_options] : {}
      end
    end
  end
end