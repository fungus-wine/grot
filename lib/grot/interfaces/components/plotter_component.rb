# frozen_string_literal: true

require 'gosu'
require 'grot/interfaces/utils/drawing_kit'

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
          
          # Calculate available space for plotting
          {
            x: LEFT_MARGIN,
            y: MARGIN,
            width: @interface.width - LEFT_MARGIN - MARGIN,
            height: @interface.height - (MARGIN * 2) - CommandBar::HEIGHT
          }
        end
        
        def draw_graph_background(graph_area)
          # Graph area with slightly different tone - flat, no 3D effect
          graph_bg = Gosu::Color.rgba(35, 35, 38, 255)  # Slightly lighter than main bg
          Gosu.draw_rect(
            graph_area[:x], 
            graph_area[:y], 
            graph_area[:width], 
            graph_area[:height], 
            graph_bg
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
          
          # Position legend
          legend_x = graph_area[:x] + graph_area[:width] - LEGEND_WIDTH
          legend_y = graph_area[:y] + LEGEND_EXTRA_HEIGHT
          
          # Modern semi-transparent dark background with subtle border
          background_color = Gosu::Color.rgba(45, 45, 48, 240)  # VS Code-inspired dark
          
          # Calculate height based on content
          series_count = active_series.size.clamp(1, LEGEND_MAX_VISIBLE_SERIES)
          legend_height = (series_count * LEGEND_ENTRY_HEIGHT)
          legend_height += LEGEND_EXTRA_HEIGHT if active_series.size > LEGEND_MAX_VISIBLE_SERIES # Add space for "...more" text
          
          # Draw legend background with modern styling
          draw_rounded_rect(
            legend_x - LEGEND_PADDING,
            legend_y - LEGEND_PADDING,
            LEGEND_WIDTH,
            legend_height + LEGEND_PADDING,
            background_color,
            LEGEND_BORDER_RADIUS,
            3
          )
          
          # Add subtle border for modern look
          border_color = Gosu::Color.rgba(80, 80, 80, 180)
          draw_rounded_rect_outline(
            legend_x - LEGEND_PADDING,
            legend_y - LEGEND_PADDING,
            LEGEND_WIDTH,
            legend_height + LEGEND_PADDING,
            border_color,
            LEGEND_BORDER_RADIUS,
            3
          )
          
          # Draw entries with number keys
          active_series.first(LEGEND_MAX_VISIBLE_SERIES).each_with_index do |(name, info), i|
            y_pos = legend_y + (i * LEGEND_ENTRY_HEIGHT)
            
            # Color swatch - use dimmed color if hidden
            swatch_color = info[:visible] ? info[:color] : 
                          Gosu::Color.rgba(info[:color].red, info[:color].green, info[:color].blue, 100)
            
            draw_circle(
              legend_x + 10,
              y_pos + 6,
              7,
              swatch_color,
              4
            )
            
            # Draw number key indicator with modern styling
            key_number = i + 1
            key_color = info[:visible] ? Gosu::Color.rgba(130, 130, 130, 255) : Gosu::Color.rgba(80, 80, 80, 255)
            @font.draw_text(
              "#{key_number}",
              legend_x + 25,
              y_pos,
              5,
              0.8,
              0.8,
              key_color
            )
            
            # Draw name with modern text hierarchy
            text_color = info[:visible] ? Gosu::Color.rgba(212, 212, 212, 255) : Gosu::Color.rgba(120, 120, 120, 255)
            @font.draw_text(
              name.to_s,
              legend_x + 40,
              y_pos,
              5,
              1.0,
              1.0,
              text_color
            )
          end
          
          # Draw count if more series than active
          if active_series.size > LEGEND_MAX_VISIBLE_SERIES
            y_pos = legend_y + (LEGEND_MAX_VISIBLE_SERIES * LEGEND_ENTRY_HEIGHT)
            @font.draw_text(
              "... #{active_series.size - LEGEND_MAX_VISIBLE_SERIES} more",
              legend_x + 40,
              y_pos,
              5,
              0.8,
              0.8,
              Gosu::Color.rgba(160, 160, 160, 255)
            )
          end
        end
        
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
          target_lines = state[:y_grid_lines] + 1 # Usually 6 lines
          
          # Check if zero should be included
          range = y_max - y_min
          zero_distance_from_center = [(0 - y_min).abs, (0 - y_max).abs].min
          
          # Include zero if it's within the range or close to it (within 20% of range)
          include_zero = (y_min <= 0 && y_max >= 0) || zero_distance_from_center <= range * 0.2
          
          if include_zero
            # Build grid with zero line
            if y_min >= 0
              # All positive values, start from 0
              step = (y_max - 0) / (target_lines - 1)
              step = round_to_nice_step(step)
              (0...target_lines).map { |i| 0 + i * step }
            elsif y_max <= 0
              # All negative values, end at 0
              step = (0 - y_min) / (target_lines - 1)
              step = round_to_nice_step(step)
              (0...target_lines).map { |i| 0 - (target_lines - 1 - i) * step }
            else
              # Spans zero, make zero one of the lines
              positive_lines = (target_lines / 2.0).ceil
              negative_lines = target_lines - positive_lines
              
              pos_step = round_to_nice_step(y_max / positive_lines)
              neg_step = round_to_nice_step(-y_min / negative_lines)
              
              values = []
              # Negative values
              (1..negative_lines).each { |i| values << -i * neg_step }
              # Zero
              values << 0
              # Positive values  
              (1...positive_lines).each { |i| values << i * pos_step }
              
              values.sort
            end
          else
            # Standard even spacing without zero
            step = (y_max - y_min) / (target_lines - 1)
            step = round_to_nice_step(step)
            (0...target_lines).map { |i| y_min + i * step }
          end
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