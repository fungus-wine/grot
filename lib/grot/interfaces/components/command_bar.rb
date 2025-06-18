# frozen_string_literal: true

require 'gosu'

module Grot
  module Interfaces
    module Components
      class CommandBar
        PROMPT = "Press Tab to enter commands..."
        HEIGHT = 40  # Fixed height for command bar
        
        # Visual styling constants
        TEXT_PADDING = 12
        TEXT_SCALE = 0.9
        CURSOR_WIDTH = 2

        def initialize(interface, font, theme_manager)
          @interface = interface
          @font = font
          @theme_manager = theme_manager
        end

        def draw
          state = @interface.command_state
          
          # Position at bottom of window with full width
          y_position = @interface.height - HEIGHT
          width = @interface.width
          
          background_color = state[:active] ? @theme_manager.command_bar_active_color : @theme_manager.command_bar_color
          text_color = state[:active] ? @theme_manager.command_bar_active_text_color : @theme_manager.command_bar_text_color
          
          # Draw full-width bar with modern styling
          Gosu.draw_rect(0, y_position, width, HEIGHT, background_color)
          
          # Add subtle top border for definition
          top_border_color = Gosu::Color.rgba(80, 80, 80, 200)
          Gosu.draw_rect(0, y_position, width, 1, top_border_color)
          
          prefix = "❯ "
          
          if state[:active] && @interface.text_input
            text = @interface.text_input.text
            @font.draw_text(prefix + text, TEXT_PADDING, y_position + TEXT_PADDING, 1, 1, 1, text_color)
            
            cursor_x = TEXT_PADDING + @font.text_width(prefix + text[0...@interface.text_input.caret_pos])
            Gosu.draw_line(cursor_x, y_position + TEXT_PADDING, @theme_manager.command_bar_cursor_color,
                          cursor_x, y_position + TEXT_PADDING + @font.height, @theme_manager.command_bar_cursor_color, CURSOR_WIDTH)
          else
            display_text = state[:active] ? state[:text] : PROMPT
            # Use more subtle color for prompt when inactive
            prompt_color = state[:active] ? text_color : Gosu::Color.rgba(120, 120, 120, 255)
            final_text = state[:active] ? prefix + display_text : display_text
            @font.draw_text(final_text, TEXT_PADDING, y_position + TEXT_PADDING, 1, TEXT_SCALE, TEXT_SCALE, prompt_color)
          end
        end
      end
    end
  end
end