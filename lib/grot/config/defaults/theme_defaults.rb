# frozen_string_literal: true

require_relative '../config_registry'

module Grot
  module Config
    module Defaults
      module ThemeDefaults
        def self.load_defaults(registry = ConfigRegistry.instance)

          # Define theme-related categories
          registry.define_category(:theme, "Theme and appearance settings")
          registry.define_category(:theme_colors, "Color scheme settings")
          registry.define_category(:theme_command_bar, "Command bar appearance")
          
          # Theme settings
          load_theme_config(registry)
          
          # Color scheme
          load_color_config(registry)
          
          # Command bar appearance
          load_command_bar_config(registry)
        end

        def self.load_theme_config(registry)
          registry.add_option(
            :theme,
            :name,
            :string,
            "dark",
            "Theme name (dark, light)"
          )
        end
        
        def self.load_color_config(registry)
          registry.add_option(
            :theme_colors,
            :background_color,
            :string,
            "0xff_444444",
            "Background color (ARGB format)"
          )
          
          registry.add_option(
            :theme_colors,
            :text_color,
            :string,
            "0xff_E0E0E0",
            "Text color (ARGB format)"
          )
          
          registry.add_option(
            :theme_colors,
            :primary_color,
            :string,
            "0xff_6200EE",
            "Primary color for UI elements (ARGB format)"
          )
          
          registry.add_option(
            :theme_colors,
            :accent_color,
            :string,
            "0xff_03DAC6",
            "Accent color for UI elements (ARGB format)"
          )
          
          registry.add_option(
            :theme_colors,
            :warning_color,
            :string,
            "0xff_FFA726",
            "Warning color (ARGB format)"
          )
          
          registry.add_option(
            :theme_colors,
            :error_color,
            :string,
            "0xff_F44336",
            "Error color (ARGB format)"
          )
          
          registry.add_option(
            :theme_colors,
            :grid_color,
            :string,
            "0x40_FFFFFF",
            "Grid color for plotter (ARGB format)"
          )
          
          (1..8).each do |i|
            color_value = case i
                          when 1 then "0xff_F44336" # Red
                          when 2 then "0xff_2196F3" # Blue
                          when 3 then "0xff_4CAF50" # Green
                          when 4 then "0xff_FF9800" # Orange
                          when 5 then "0xff_9C27B0" # Purple
                          when 6 then "0xff_00BCD4" # Cyan
                          when 7 then "0xff_FFEB3B" # Yellow
                          when 8 then "0xff_795548" # Brown
                          end
                          
            registry.add_option(
              :theme_colors,
              "graph_color_#{i}".to_sym,
              :string,
              color_value,
              "Color for graph series #{i} (ARGB format)"
            )
          end
        end
        
        def self.load_command_bar_config(registry)
          registry.add_option(
            :theme_command_bar,
            :color,
            :string,
            "0xff_2d2d30",
            "Command bar background color (ARGB format)"
          )
          
          registry.add_option(
            :theme_command_bar,
            :active_color,
            :string,
            "0xff_3c3c3c",
            "Command bar background color when active (ARGB format)"
          )
          
          registry.add_option(
            :theme_command_bar,
            :text_color,
            :string,
            "0xff_cccccc",
            "Command bar text color (ARGB format)"
          )
          
          registry.add_option(
            :theme_command_bar,
            :active_text_color,
            :string,
            "0xff_ffffff",
            "Command bar text color when active (ARGB format)"
          )
          
          registry.add_option(
            :theme_command_bar,
            :cursor_color,
            :string,
            "0xff_007acc",
            "Command bar cursor color (ARGB format)"
          )
          
          registry.add_option(
            :theme_command_bar,
            :height,
            :integer,
            40,
            "Command bar height in pixels"
          )
        end
      end
    end
  end
end

# Load the defaults when this file is required
Grot::Config::Defaults::ThemeDefaults.load_defaults