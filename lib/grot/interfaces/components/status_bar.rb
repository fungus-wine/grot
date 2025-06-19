# frozen_string_literal: true

require 'gosu'

module Grot
  module Interfaces
    module Components
      class StatusBar
        HEIGHT = 25  # Fixed height for status bar
        
        # Visual styling constants
        TEXT_PADDING = 8
        TEXT_SCALE = 0.9
        ITEM_SPACING = 20

        def initialize(interface, font, theme_manager)
          @interface = interface
          @font = font
          @theme_manager = theme_manager
          @status_items = {}
        end

        def set_status(key, value, color = nil)
          @status_items[key] = {
            value: value,
            color: color || @theme_manager.text_color
          }
        end

        def draw
          # Position at top of window with full width
          y_position = 0
          width = @interface.width
          
          # Draw status bar background
          Gosu.draw_rect(0, y_position, width, HEIGHT, @theme_manager.command_bar_color)
          
          # Add subtle bottom border for definition
          bottom_border_color = Gosu::Color.rgba(80, 80, 80, 200)
          Gosu.draw_rect(0, y_position + HEIGHT - 1, width, 1, bottom_border_color)
          
          # Draw status items
          draw_status_items(y_position)
        end
        
        private
        
        def draw_status_items(y_position)
          return if @status_items.empty?
          
          x_position = TEXT_PADDING
          
          @status_items.each do |key, item|
            text = "#{key}: #{item[:value]}"
            
            @font.draw_text(
              text, 
              x_position, 
              y_position + TEXT_PADDING, 
              1, 
              TEXT_SCALE, 
              TEXT_SCALE, 
              item[:color]
            )
            
            # Move to next position
            x_position += @font.text_width(text) * TEXT_SCALE + ITEM_SPACING
            
            # Break if we're getting close to the edge
            break if x_position > @interface.width - 100
          end
        end
      end
    end
  end
end