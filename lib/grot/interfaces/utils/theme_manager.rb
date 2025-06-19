# frozen_string_literal: true

require 'gosu'

module Grot
  module Interfaces
    module Utils
      class ThemeManager
        # Modern dark theme colors inspired by VS Code Dark+
        BACKGROUND_COLOR = Gosu::Color.argb(0xff_1e1e1e)  # Deep dark background
        TEXT_COLOR = Gosu::Color.argb(0xff_d4d4d4)       # Warm light grey text
        PRIMARY_COLOR = Gosu::Color.argb(0xff_007acc)     # Modern blue
        ACCENT_COLOR = Gosu::Color.argb(0xff_14a085)     # Subtle teal
        WARNING_COLOR = Gosu::Color.argb(0xff_ff8c00)    # Warm orange
        ERROR_COLOR = Gosu::Color.argb(0xff_e74c3c)      # Softer red
        GRID_COLOR = Gosu::Color.argb(0x20_ffffff)       # Very subtle grid lines
        
        # Command bar colors
        COMMAND_BAR_COLOR = Gosu::Color.argb(0xff_2d2d30)        # Subtle dark bar
        COMMAND_BAR_ACTIVE_COLOR = Gosu::Color.argb(0xff_3c3c3c)  # Slightly lighter when active
        COMMAND_BAR_TEXT_COLOR = Gosu::Color.argb(0xff_cccccc)     # Light text
        COMMAND_BAR_ACTIVE_TEXT_COLOR = Gosu::Color.argb(0xff_ffffff) # White when active
        COMMAND_BAR_CURSOR_COLOR = Gosu::Color.argb(0xff_007acc)   # Blue cursor
        
        # Modern graph colors optimized for dark backgrounds
        GRAPH_COLORS = [
          Gosu::Color.argb(0xff_ff6b6b),  # Soft coral red
          Gosu::Color.argb(0xff_4ecdc4),  # Teal cyan  
          Gosu::Color.argb(0xff_45b7d1),  # Sky blue
          Gosu::Color.argb(0xff_f9ca24),  # Golden yellow
          Gosu::Color.argb(0xff_6c5ce7),  # Soft purple
          Gosu::Color.argb(0xff_a29bfe),  # Light purple
          Gosu::Color.argb(0xff_fd79a8),  # Pink
          Gosu::Color.argb(0xff_00b894)   # Mint green
        ].freeze

        attr_reader :background_color,
                    :text_color,
                    :primary_color,
                    :accent_color,
                    :warning_color,
                    :error_color,
                    :grid_color,
                    :command_bar_color,
                    :command_bar_active_color,
                    :command_bar_text_color,
                    :command_bar_active_text_color,
                    :command_bar_cursor_color

        def initialize(theme_name = 'dark')
          @background_color = BACKGROUND_COLOR
          @text_color = TEXT_COLOR
          @primary_color = PRIMARY_COLOR
          @accent_color = ACCENT_COLOR
          @warning_color = WARNING_COLOR
          @error_color = ERROR_COLOR
          @grid_color = GRID_COLOR
          @command_bar_color = COMMAND_BAR_COLOR
          @command_bar_active_color = COMMAND_BAR_ACTIVE_COLOR
          @command_bar_text_color = COMMAND_BAR_TEXT_COLOR
          @command_bar_active_text_color = COMMAND_BAR_ACTIVE_TEXT_COLOR
          @command_bar_cursor_color = COMMAND_BAR_CURSOR_COLOR
        end
        
        # Get a color for a specific graph series by index
        def graph_color(index)
          GRAPH_COLORS[index % GRAPH_COLORS.size]
        end
      end
    end
  end
end