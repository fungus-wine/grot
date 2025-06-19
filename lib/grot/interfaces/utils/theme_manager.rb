# frozen_string_literal: true

require 'gosu'
require 'grot/config/config_registry'

module Grot
  module Interfaces
    module Utils
      class ThemeManager
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
          # Try to load colors from registry
          init_from_registry(theme_name)
          
          # If registry wasn't available, set up defaults
          init_default_colors if @background_color.nil?
        end
        
        # Initialize from registry if available
        def init_from_registry(theme_name)
          registry = Grot::Config::ConfigRegistry.instance
          return unless registry
          
          load_colors_from_registry(registry)
        end
        
        # Set up modern dark theme colors inspired by VS Code Dark+
        def init_default_colors
          @background_color = Gosu::Color.argb(0xff_1e1e1e)  # Deep dark background
          @text_color = Gosu::Color.argb(0xff_d4d4d4)       # Warm light grey text
          @primary_color = Gosu::Color.argb(0xff_007acc)     # Modern blue
          @accent_color = Gosu::Color.argb(0xff_14a085)     # Subtle teal
          @warning_color = Gosu::Color.argb(0xff_ff8c00)    # Warm orange
          @error_color = Gosu::Color.argb(0xff_e74c3c)      # Softer red
          @grid_color = Gosu::Color.argb(0x20_ffffff)       # Very subtle grid lines
          
          @command_bar_color = Gosu::Color.argb(0xff_2d2d30)        # Subtle dark bar
          @command_bar_active_color = Gosu::Color.argb(0xff_3c3c3c)  # Slightly lighter when active
          @command_bar_text_color = Gosu::Color.argb(0xff_cccccc)     # Light text
          @command_bar_active_text_color = Gosu::Color.argb(0xff_ffffff) # White when active
          @command_bar_cursor_color = Gosu::Color.argb(0xff_007acc)   # Blue cursor
           
          # Modern graph colors optimized for dark backgrounds
          @graph_colors = [
            Gosu::Color.argb(0xff_ff6b6b),  # Soft coral red
            Gosu::Color.argb(0xff_4ecdc4),  # Teal cyan  
            Gosu::Color.argb(0xff_45b7d1),  # Sky blue
            Gosu::Color.argb(0xff_f9ca24),  # Golden yellow
            Gosu::Color.argb(0xff_6c5ce7),  # Soft purple
            Gosu::Color.argb(0xff_a29bfe),  # Light purple
            Gosu::Color.argb(0xff_fd79a8),  # Pink
            Gosu::Color.argb(0xff_00b894)   # Mint green
          ]
        end
        
        # Get a color for a specific graph series by index
        def graph_color(index)
          @graph_colors[index % @graph_colors.size]
        end
        
        # Get a specific graph color by index
        def get_graph_color(index)
          return nil if index < 0 || index >= @graph_colors.size
          @graph_colors[index]
        end
        
        # Set a specific graph color
        def set_graph_color(index, color)
          return false if index < 0 || index >= @graph_colors.size
          @graph_colors[index] = color
          true
        end
        
        # Apply a theme from configuration
        def apply_theme(theme_config)
          return false unless theme_config.is_a?(Hash)
          
          apply_main_colors_from_config(theme_config)
          apply_graph_colors_from_config(theme_config)
          apply_command_bar_colors_from_config(theme_config)
          
          true
        end
        
        # Get all theme settings as a hash
        def to_hash
          {
            :background_color => color_to_s(@background_color),
            :text_color => color_to_s(@text_color),
            :primary_color => color_to_s(@primary_color),
            :accent_color => color_to_s(@accent_color),
            :warning_color => color_to_s(@warning_color),
            :error_color => color_to_s(@error_color),
            :grid_color => color_to_s(@grid_color),
            :command_bar => {
              :color => color_to_s(@command_bar_color),
              :active_color => color_to_s(@command_bar_active_color),
              :text_color => color_to_s(@command_bar_text_color),
              :active_text_color => color_to_s(@command_bar_active_text_color),
              :cursor_color => color_to_s(@command_bar_cursor_color)
            },
            :graph_colors => @graph_colors.map { |c| color_to_s(c) }
          }
        end
        
        private
        
        def load_colors_from_registry(registry)
          # Load main theme colors
          if registry[:theme_colors]
            colors = registry[:theme_colors].defaults
            
            @background_color = parse_color(colors[:background_color] || '0xff_444444')
            @text_color = parse_color(colors[:text_color] || '0xff_E0E0E0')
            @primary_color = parse_color(colors[:primary_color] || '0xff_6200EE')
            @accent_color = parse_color(colors[:accent_color] || '0xff_03DAC6')
            @warning_color = parse_color(colors[:warning_color] || '0xff_FFA726')
            @error_color = parse_color(colors[:error_color] || '0xff_F44336')
            @grid_color = parse_color(colors[:grid_color] || '0x40_FFFFFF')
            
            # Load graph colors
            @graph_colors = []
            (1..8).each do |i|
              color = colors["graph_color_#{i}"]
              @graph_colors << parse_color(color) if color
            end
            
            ensure_complete_graph_color_set
          end
          
          # Load command bar colors
          if registry[:theme_command_bar]
            command_bar = registry[:theme_command_bar].defaults
            
            @command_bar_color = parse_color(command_bar[:color] || '0xff_2d2d30')
            @command_bar_active_color = parse_color(command_bar[:active_color] || '0xff_3c3c3c')
            @command_bar_text_color = parse_color(command_bar[:text_color] || '0xff_cccccc')
            @command_bar_active_text_color = parse_color(command_bar[:active_text_color] || '0xff_ffffff')
            @command_bar_cursor_color = parse_color(command_bar[:cursor_color] || '0xff_007acc')
          end
        end
        
        def apply_main_colors_from_config(theme_config)
          color_mappings = {
            :background_color => :@background_color,
            :text_color => :@text_color,
            :primary_color => :@primary_color,
            :accent_color => :@accent_color,
            :warning_color => :@warning_color,
            :error_color => :@error_color,
            :grid_color => :@grid_color
          }
          
          color_mappings.each do |config_key, instance_var|
            if theme_config[config_key]
              parsed_color = parse_color(theme_config[config_key])
              instance_variable_set(instance_var, parsed_color) if parsed_color
            end
          end
        end
        
        def apply_graph_colors_from_config(theme_config)
          (1..8).each do |i|
            color = theme_config["graph_color_#{i}"]
            parsed = parse_color(color)
            @graph_colors[i-1] = parsed if color && parsed
          end
        end
        
        def apply_command_bar_colors_from_config(theme_config)
          return unless theme_config[:command_bar]
          
          cmd_bar = theme_config[:command_bar]
          command_bar_mappings = {
            :color => :@command_bar_color,
            :active_color => :@command_bar_active_color,
            :text_color => :@command_bar_text_color,
            :active_text_color => :@command_bar_active_text_color,
            :cursor_color => :@command_bar_cursor_color
          }
          
          command_bar_mappings.each do |config_key, instance_var|
            if cmd_bar[config_key]
              parsed_color = parse_color(cmd_bar[config_key])
              instance_variable_set(instance_var, parsed_color) if parsed_color
            end
          end
        end
        
        def ensure_complete_graph_color_set
          return unless @graph_colors.empty? || @graph_colors.size < 8
          
          default_graph_colors = [
            '0xff_F44336', '0xff_2196F3', '0xff_4CAF50', '0xff_FF9800',
            '0xff_9C27B0', '0xff_00BCD4', '0xff_FFEB3B', '0xff_795548'
          ]
          
          if @graph_colors.empty?
            @graph_colors = default_graph_colors.map { |c| parse_color(c) }
          else
            remaining_count = 8 - @graph_colors.size
            default_graph_colors[0...remaining_count].each do |color|
              @graph_colors << parse_color(color)
            end
          end
        end
        
        # Parse color string in format 0xAA_RRGGBB
        def parse_color(color_str)
          return nil unless color_str.is_a?(String)
          
          # Remove underscores and 0x prefix if present
          clean_str = color_str.gsub('_', '').gsub(/^0x/i, '')
          
          # Parse hexadecimal value
          begin
            color_int = Integer("0x#{clean_str}")
            alpha = (color_int >> 24) & 0xFF
            red = (color_int >> 16) & 0xFF
            green = (color_int >> 8) & 0xFF
            blue = color_int & 0xFF
            
            Gosu::Color.rgba(red, green, blue, alpha)
          rescue => e
            # Return nil on parsing error
            nil
          end
        end
        
        # Convert Gosu::Color to string format (0xAA_RRGGBB)
        def color_to_s(color)
          return nil unless color.is_a?(Gosu::Color)
          
          # Format as 0xAA_RRGGBB
          "0x%02X_%02X%02X%02X" % [color.alpha, color.red, color.green, color.blue]
        end
      end
    end
  end
end
