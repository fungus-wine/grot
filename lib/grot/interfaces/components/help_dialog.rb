# frozen_string_literal: true

require 'gosu'
require 'grot/interfaces/utils/drawing_kit'

module Grot
  module Interfaces
    module Components
      class HelpDialog
        include Grot::Interfaces::DrawingKit
        
        # Layout constants
        PADDING = 15
        MIN_WIDTH = 300
        WINDOW_MARGIN = 40
        WINDOW_PADDING = 80
        
        # Z-index constants
        DIALOG_Z_INDEX = 6
        CONTENT_Z_INDEX = 7
        
        # Text styling constants
        TITLE_SCALE = 1.1
        CONTENT_SCALE = 0.9
        BORDER_RADIUS = 8
        
        def initialize(interface, font, theme_manager)
          @interface = interface
          @font = font
          @theme_manager = theme_manager
          @content = []
        end
        
        def set_content(content)
          @content = content
        end
        
        def draw
          # Support both plotter and monitor interfaces
          state = @interface.respond_to?(:plotter_state) ? @interface.plotter_state : @interface.monitor_state
          return unless state[:show_help]
          
          # Calculate dialog dimensions based on content
          dialog_area = calculate_dialog_area
          
          draw_dialog_background(dialog_area)
          draw_dialog_content(dialog_area)
        end
        
        private
        
        def calculate_dialog_area
          # Set some defaults
          width = [MIN_WIDTH, @interface.width * 0.6].max
          height = @font.height * (@content.size + 2) + PADDING * 2
          
          # Calculate max width based on content
          @content.each do |line|
            line_width = @font.text_width(line) + PADDING * 2
            width = [width, line_width].max
          end
          
          # Constrain to window size
          width = [@interface.width - WINDOW_MARGIN, width].min
          height = [@interface.height - WINDOW_PADDING, height].min
          
          # Center in the window
          x = (@interface.width - width) / 2
          y = (@interface.height - height) / 2
          
          {
            x: x,
            y: y,
            width: width,
            height: height
          }
        end
        
        def draw_dialog_background(dialog_area)
          # Modern semi-transparent dark background matching legend style
          background_color = Gosu::Color.rgba(45, 45, 48, 240)  # VS Code-inspired dark
          
          # Draw rounded rectangle background with higher z-index
          draw_rounded_rect(
            dialog_area[:x],
            dialog_area[:y],
            dialog_area[:width],
            dialog_area[:height],
            background_color,
            BORDER_RADIUS,
            DIALOG_Z_INDEX
          )
          
          # Add subtle border for modern look
          border_color = Gosu::Color.rgba(80, 80, 80, 180)
          draw_rounded_rect_outline(
            dialog_area[:x],
            dialog_area[:y],
            dialog_area[:width],
            dialog_area[:height],
            border_color,
            BORDER_RADIUS,
            DIALOG_Z_INDEX
          )
        end
        
        def draw_dialog_content(dialog_area)
          # Title at the top with modern styling
          title = "Help"
          title_x = dialog_area[:x] + (dialog_area[:width] - @font.text_width(title)) / 2
          @font.draw_text(
            title,
            title_x,
            dialog_area[:y] + PADDING,
            CONTENT_Z_INDEX,
            TITLE_SCALE,
            TITLE_SCALE,
            Gosu::Color.rgba(212, 212, 212, 255)  # Modern text color matching legend
          )
          
          # Draw each line of content with modern text hierarchy
          @content.each_with_index do |line, index|
            line_y = dialog_area[:y] + PADDING + @font.height * (index + 2)
            
            # Skip if outside visible area
            next if line_y > dialog_area[:y] + dialog_area[:height] - PADDING
            
            @font.draw_text(
              line,
              dialog_area[:x] + PADDING,
              line_y,
              CONTENT_Z_INDEX,
              CONTENT_SCALE,
              CONTENT_SCALE,
              Gosu::Color.rgba(220, 220, 220, 255)  # Brighter content text
            )
          end
          
        end
      end
    end
  end
end