# frozen_string_literal: true

require 'gosu'
require 'grot/interfaces/utils/drawing_kit'
require 'grot/interfaces/components/status_bar'
require 'grot/interfaces/components/command_bar'

module Grot
  module Interfaces
    module Components
      class PlotterComponent
        include Grot::Interfaces::DrawingKit
        
        # Grid and layout constants
        GRID_DIVISIONS = 10
        MARGIN = 40
        LEFT_MARGIN = 60  # Extra space for Y-axis labels
        LEGEND_WIDTH = 180
        LEGEND_MAX_VISIBLE_SERIES = 8
        LEGEND_ENTRY_HEIGHT = 25
        LEGEND_EXTRA_HEIGHT = 20
        
        # Time scale constants
        TIME_SCALE_MILLISECONDS_THRESHOLD = 1.0
        
        # Visual styling constants (non-color)
        LEGEND_BORDER_RADIUS = 8
        LEGEND_PADDING = 10
        
        # Color constants
        LEGEND_BACKGROUND_COLOR = Gosu::Color.rgba(45, 45, 48, 240)
        LEGEND_BORDER_COLOR = Gosu::Color.rgba(80, 80, 80, 180)
        LEGEND_TEXT_VISIBLE_COLOR = Gosu::Color.rgba(212, 212, 212, 255)
        LEGEND_TEXT_HIDDEN_COLOR = Gosu::Color.rgba(120, 120, 120, 255)
        LEGEND_NUMBER_VISIBLE_COLOR = Gosu::Color.rgba(130, 130, 130, 255)
        LEGEND_NUMBER_HIDDEN_COLOR = Gosu::Color.rgba(80, 80, 80, 255)
        LEGEND_OVERFLOW_COLOR = Gosu::Color.rgba(160, 160, 160, 255)
        GRAPH_BACKGROUND_COLOR = Gosu::Color.rgba(35, 35, 38, 255)
        
        # Alpha values for transparency effects
        HIDDEN_SERIES_ALPHA = 100
        
        def initialize(interface, font, theme_manager, data_buffer)
          @interface = interface
          @font = font
          @theme_manager = theme_manager
          @data_buffer = data_buffer
        end
        
        def draw
          state = @interface.plotter_state
          
          # Calculate graph area for current window dimensions
          graph_area = calculate_graph_area

          draw_graph_background(graph_area)
          draw_grid(state, graph_area)
          draw_data_series(state, graph_area)
          draw_legend(state, graph_area) if state[:show_legend]
          draw_time_scale_label(graph_area)
        end
        
        private
        
        def calculate_graph_area
          state = @interface.plotter_state
          
          # Calculate available space for plotting (between status bar and command bar)
          {
            x: LEFT_MARGIN,
            y: MARGIN + StatusBar::HEIGHT,
            width: @interface.width - LEFT_MARGIN - MARGIN,
            height: @interface.height - (MARGIN * 2) - StatusBar::HEIGHT - CommandBar::HEIGHT
          }
        end
        
        def draw_graph_background(graph_area)
          Gosu.draw_rect(
            graph_area[:x], 
            graph_area[:y], 
            graph_area[:width], 
            graph_area[:height], 
            GRAPH_BACKGROUND_COLOR
          )
        end
        
        def draw_grid(state, graph_area)
          # Draw grid lines
          grid_color = @theme_manager.grid_color
          
          # Draw vertical grid lines (time)
          x_step = graph_area[:width] / GRID_DIVISIONS.to_f
          (GRID_DIVISIONS + 1).times do |i|
            x = graph_area[:x] + i * x_step
            Gosu.draw_line(
              x, graph_area[:y],
              grid_color,
              x, graph_area[:y] + graph_area[:height],
              grid_color,
              0
            )
          end
          
          # Draw horizontal grid lines (values) with smart zero handling
          grid_values = calculate_smart_grid_values(state)
          
          grid_values.each do |value|
            # Calculate Y position for this value
            y_normalized = 1.0 - ((value - state[:y_min]) / (state[:y_max] - state[:y_min]))
            y = graph_area[:y] + (y_normalized * graph_area[:height])
            
            # Only draw if the line is within the graph area
            if y >= graph_area[:y] && y <= graph_area[:y] + graph_area[:height]
              # Use thicker line for zero
              line_color = (value == 0) ? @theme_manager.text_color : grid_color
              
              Gosu.draw_line(
                graph_area[:x], y,
                line_color,
                graph_area[:x] + graph_area[:width], y,
                line_color,
                0
              )
              
              # Draw y-axis labels
              @font.draw_text(
                "#{value.round(1)}", 
                graph_area[:x] - 35, 
                y - 10, 
                1, 
                0.8, 
                0.8, 
                @theme_manager.text_color
              )
            end
          end
        end
        
        def draw_data_series(state, graph_area)
          # Get data from buffer
          data = @data_buffer.recent_data
          return if data[:series].empty?
          
          # Local copy for active series tracking
          active_series = {}
          
          data[:series].each_with_index do |(name, values), index|
            next if values.empty?

            # Check if series is visible (default to true if not set)
            visible = state[:series_visibility][name]
            visible = true if visible.nil?

            color = @theme_manager.graph_color(index)
            
            # Only draw if visible
            if visible
              points = calculate_points(values, state, graph_area)
              draw_line_series(points, color)
            end
            
            # Track active series for legend (include hidden series too)
            active_series[name] = {
              color: color,
              index: index,
              last_value: values.last,
              visible: visible
            }
          end
          
          # Update interface state with active series
          @interface.plotter_state[:active_series] = active_series
        end
        
        def calculate_points(values, state, graph_area)
          points = []
          
          # Calculate range
          y_range = state[:y_max] - state[:y_min]
          y_range = 1.0 if y_range.zero? # Avoid division by zero
          
          # Calculate x-step based on number of values and graph width
          x_step = graph_area[:width] / [values.size - 1, 1].max.to_f
          
          # Generate point coordinates
          values.each_with_index do |value, i|
            # Normalize value to graph coordinates
            x = graph_area[:x] + (i * x_step)
            y_normalized = 1.0 - ((value - state[:y_min]) / y_range)
            y = graph_area[:y] + (y_normalized * graph_area[:height])
            
            # Clamp y value to graph area
            y = graph_area[:y] if y < graph_area[:y]
            y = graph_area[:y] + graph_area[:height] if y > graph_area[:y] + graph_area[:height]
            
            points << [x, y]
          end
          
          points
        end
        
        def draw_line_series(points, color)
          (points.size - 1).times do |i|
            Gosu.draw_line(
              points[i][0], points[i][1],
              color,
              points[i+1][0], points[i+1][1],
              color,
              2
            )
          end
        end
        
        def draw_legend(state, graph_area)
          active_series = state[:active_series]
          return if active_series.empty?
          
          legend_position = calculate_legend_position(graph_area)
          legend_height = calculate_legend_height(active_series)
          
          draw_legend_background(legend_position, legend_height)
          draw_legend_entries(active_series, legend_position)
          draw_series_overflow_indicator(active_series, legend_position) if active_series.size > LEGEND_MAX_VISIBLE_SERIES
        end

        private

        def calculate_legend_position(graph_area)
          {
            x: graph_area[:x] + graph_area[:width] - LEGEND_WIDTH,
            y: graph_area[:y] + LEGEND_EXTRA_HEIGHT
          }
        end

        def calculate_legend_height(active_series)
          series_count = active_series.size.clamp(1, LEGEND_MAX_VISIBLE_SERIES)
          legend_height = series_count * LEGEND_ENTRY_HEIGHT
          legend_height += LEGEND_EXTRA_HEIGHT if active_series.size > LEGEND_MAX_VISIBLE_SERIES
          legend_height
        end

        def draw_legend_background(position, height)
          # Background
          draw_rounded_rect(
            position[:x] - LEGEND_PADDING,
            position[:y] - LEGEND_PADDING,
            LEGEND_WIDTH,
            height + LEGEND_PADDING,
            LEGEND_BACKGROUND_COLOR,
            LEGEND_BORDER_RADIUS,
            3
          )
          
          # Border
          draw_rounded_rect_outline(
            position[:x] - LEGEND_PADDING,
            position[:y] - LEGEND_PADDING,
            LEGEND_WIDTH,
            height + LEGEND_PADDING,
            LEGEND_BORDER_COLOR,
            LEGEND_BORDER_RADIUS,
            3
          )
        end

        def draw_legend_entries(active_series, position)
          active_series.first(LEGEND_MAX_VISIBLE_SERIES).each_with_index do |(name, info), i|
            y_pos = position[:y] + (i * LEGEND_ENTRY_HEIGHT)
            
            draw_legend_entry_swatch(info, position[:x], y_pos)
            draw_legend_entry_number(i + 1, info[:visible], position[:x], y_pos)
            draw_legend_entry_name(name, info[:visible], position[:x], y_pos)
          end
        end

        def draw_legend_entry_swatch(info, x, y)
          swatch_color = info[:visible] ? info[:color] : create_transparent_color(info[:color], HIDDEN_SERIES_ALPHA)
          draw_circle(x + 10, y + 6, 7, swatch_color, 4)
        end

        def draw_legend_entry_number(number, visible, x, y)
          key_color = visible ? LEGEND_NUMBER_VISIBLE_COLOR : LEGEND_NUMBER_HIDDEN_COLOR
          @font.draw_text("#{number}", x + 25, y, 5, 0.8, 0.8, key_color)
        end

        def draw_legend_entry_name(name, visible, x, y)
          text_color = visible ? LEGEND_TEXT_VISIBLE_COLOR : LEGEND_TEXT_HIDDEN_COLOR
          @font.draw_text(name.to_s, x + 40, y, 5, 1.0, 1.0, text_color)
        end

        def draw_series_overflow_indicator(active_series, position)
          y_pos = position[:y] + (LEGEND_MAX_VISIBLE_SERIES * LEGEND_ENTRY_HEIGHT)
          overflow_count = active_series.size - LEGEND_MAX_VISIBLE_SERIES
          @font.draw_text(
            "... #{overflow_count} more",
            position[:x] + 40,
            y_pos,
            5,
            0.8,
            0.8,
            LEGEND_OVERFLOW_COLOR
          )
        end
        
        def create_transparent_color(color, alpha)
          Gosu::Color.rgba(color.red, color.green, color.blue, alpha)
        end

        public
        
        def draw_time_scale_label(graph_area)
          # Get data from buffer to calculate time range
          data = @data_buffer.recent_data
          timestamps = data[:timestamps]
          
          if timestamps.size >= 2
            # Calculate time span across the entire graph
            time_span = timestamps.last - timestamps.first
            
            # There are 10 divisions on the X axis
            time_per_division = time_span / 10.0
            
            # Round to stable intervals to prevent jitter
            stable_time = round_to_nice_interval(time_per_division)
            
            # Format the time nicely
            if stable_time >= 1.0
              time_text = "#{stable_time} seconds per division"
            else
              ms_value = (stable_time * 1000).round(0)
              time_text = "#{ms_value} ms per division"
            end
          else
            time_text = "No timing data"
          end
          
          # Position label below the graph, centered
          label_x = graph_area[:x] + graph_area[:width] / 2
          label_y = graph_area[:y] + graph_area[:height] + 15
          
          # Draw the label
          @font.draw_text(
            time_text,
            label_x - (@font.text_width(time_text) / 2), # Center the text
            label_y,
            1,
            0.8,
            0.8,
            @theme_manager.text_color
          )
        end
        
        def round_to_nice_interval(value)
          # Define nice intervals for different ranges
          nice_intervals = [
            # Seconds
            10.0, 5.0, 2.0, 1.0, 0.5, 0.2, 0.1,
            # Milliseconds (as seconds)
            0.05, 0.02, 0.01, 0.005, 0.002, 0.001
          ]
          
          # Find the closest nice interval
          nice_intervals.min_by { |interval| (value - interval).abs }
        end
        
        def calculate_smart_grid_values(state)
          y_min = state[:y_min]
          y_max = state[:y_max]
          target_lines = state[:y_grid_lines] + 1
          
          if should_include_zero_line?(y_min, y_max)
            calculate_zero_based_grid_values(y_min, y_max, target_lines)
          else
            calculate_standard_grid_values(y_min, y_max, target_lines)
          end
        end
        
        def should_include_zero_line?(y_min, y_max)
          range = y_max - y_min
          zero_distance_from_center = [(0 - y_min).abs, (0 - y_max).abs].min
          
          (y_min <= 0 && y_max >= 0) || zero_distance_from_center <= range * 0.2
        end
        
        def calculate_zero_based_grid_values(y_min, y_max, target_lines)
          if y_min >= 0
            calculate_positive_only_grid(y_max, target_lines)
          elsif y_max <= 0
            calculate_negative_only_grid(y_min, target_lines)
          else
            calculate_spanning_zero_grid(y_min, y_max, target_lines)
          end
        end
        
        def calculate_positive_only_grid(y_max, target_lines)
          step = round_to_nice_step(y_max / (target_lines - 1))
          (0...target_lines).map { |i| i * step }
        end
        
        def calculate_negative_only_grid(y_min, target_lines)
          step = round_to_nice_step(-y_min / (target_lines - 1))
          (0...target_lines).map { |i| -(target_lines - 1 - i) * step }
        end
        
        def calculate_spanning_zero_grid(y_min, y_max, target_lines)
          positive_lines = (target_lines / 2.0).ceil
          negative_lines = target_lines - positive_lines
          
          pos_step = round_to_nice_step(y_max / positive_lines)
          neg_step = round_to_nice_step(-y_min / negative_lines)
          
          values = []
          (1..negative_lines).each { |i| values << -i * neg_step }
          values << 0
          (1...positive_lines).each { |i| values << i * pos_step }
          
          values.sort
        end
        
        def calculate_standard_grid_values(y_min, y_max, target_lines)
          step = round_to_nice_step((y_max - y_min) / (target_lines - 1))
          (0...target_lines).map { |i| y_min + i * step }
        end
        
        def round_to_nice_step(step)
          # Round step to nice values
          magnitude = 10 ** Math.log10(step).floor
          normalized = step / magnitude
          
          nice_normalized = if normalized <= 1
                             1
                           elsif normalized <= 2
                             2
                           elsif normalized <= 5
                             5
                           else
                             10
                           end
          
          nice_normalized * magnitude
        end
        
      end
    end
  end
end