# frozen_string_literal: true

require 'gosu'
require 'rubyserial'
require 'grot/keyboard/keyboard_manager'
require 'grot/config/config_manager'
require 'grot/interfaces/utils/theme_manager'
require 'grot/interfaces/utils/font_loader'
require 'grot/errors'

module Grot
  module Interfaces
    class BaseInterface < Gosu::Window
      # Interface constants
      FONT_NAME = "InconsolataNerdFont-Regular"
      FONT_SIZE = 16
      WINDOW_WIDTH = 1200
      WINDOW_HEIGHT = 800
      MIN_WINDOW_WIDTH = 400
      MIN_WINDOW_HEIGHT = 300

      attr_reader :config, :serial, :keyboard, :font, :theme_manager

      def initialize(config)
        @config = config
        
        
        super(WINDOW_WIDTH, WINDOW_HEIGHT, false)
        self.caption = "Grot Interface"

        # Setup theme manager and font
        @theme_manager = Utils::ThemeManager.new
        
        @font = Utils::FontLoader.load_font(FONT_NAME, FONT_SIZE) 

        # Initialize serial connection    
        initialize_serial
        
        # Initialize keyboard manager
        initialize_keyboard
      end
      
      
      # Initialize serial connection
      def initialize_serial
        port_handler = Ports::PortHandler.new
        port = port_handler.validate_port(@config.dig(:basic, :port))
        begin
          baud_rate = @config.dig(:interface, :baud_rate) || 9600
          @serial_connection = Grot::Interfaces::Models::SerialConnection.new(port, baud_rate.to_i)
        rescue 
          raise 
        end
      end
      
      # Initialize keyboard system
      def initialize_keyboard
        keyboard_auto_load = @config.dig(:keyboard, :auto_load_modules)
        keyboard_auto_load = true if keyboard_auto_load.nil? # Default to true if not specified
        
        @keyboard = Grot::Keyboard::KeyboardManager.new(
          auto_load_modules: keyboard_auto_load,
          config: @config
        )
      end

      # Gosu update callback
      def update
        @keyboard.update
        update_serial_data
        update_interface
      end

      # Gosu draw callback
      def draw
        draw_background
        draw_interface
      end

      # Gosu button down callback
      def button_down(id)
        @keyboard.handle_button_down(id)
        handle_global_keys(id)
      end

      # Gosu button up callback
      def button_up(id)
        @keyboard.handle_button_up(id)
      end

      # Check if window needs closing
      def needs_cursor?
        true  # Show cursor by default
      end

      # Cleanup on close
      def close
        @serial_connection.disconnect if @serial_connection
        @keyboard.shutdown
        super
      end

      private

      # Read and process serial data
      def update_serial_data
      end

      # Draw themed background using ThemeManager
      def draw_background
        Gosu.draw_rect(0, 0, self.width, self.height, @theme_manager.background_color)
      end

      # Handle global key bindings (e.g., Escape to close)
      def handle_global_keys(id)
      end

      # Abstract methods to be implemented by subclasses
      def update_interface
        raise NotImplementedError, "Subclasses must implement update_interface"
      end

      def draw_interface
        raise NotImplementedError, "Subclasses must implement draw_interface"
      end

      def process_serial_data(data)
        raise NotImplementedError, "Subclasses must implement process_serial_data"
      end
    end
  end
end
