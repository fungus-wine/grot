# frozen_string_literal: true

require 'gosu'
require 'grot/interfaces/base_interface'
require 'grot/interfaces/components/command_bar'
require 'grot/interfaces/components/help_dialog'
require 'grot/interfaces/components/status_bar'
require 'grot/interfaces/models/serial_connection'
require 'grot/interfaces/models/serial_data_parser'
require 'grot/interfaces/models/data_buffer_manager'
require 'grot/interfaces/components/plotter_component'
require 'grot/interfaces/utils/drawing_kit'

module Grot
  module Interfaces
    class PlotterInterface < BaseInterface
      WINDOW_TITLE = "Grot Serial Plotter"
      
      # Constants for window sizing and scaling
      MIN_WINDOW_WIDTH = 800
      MIN_WINDOW_HEIGHT = 600
      DEFAULT_BUFFER_SIZE = 500
      DEFAULT_Y_MIN = 0
      DEFAULT_Y_MAX = 100
      DEFAULT_Y_GRID_LINES = 5
      
      # Y-scale calculation constants
      Y_SCALE_PADDING_RATIO = 0.1
      MIN_Y_SCALE_PADDING = 1.0
      MIN_Y_RANGE = 0.001
      Y_RANGE_FALLBACK = 1.0

      attr_reader :data_buffer, :plotter_state, :command_state

      def initialize(config)
        super(config)
        self.caption = WINDOW_TITLE
        self.resizable = true
        
        # Get buffer size from config (defaults already merged)
        buffer_size = config.dig(:plotter, :buffer_size) || DEFAULT_BUFFER_SIZE
        
        # Initialize models
        @serial_parser = Models::SerialDataParser.new
        @data_buffer = Models::DataBufferManager.new(buffer_size)

        # Initialize state for the plotter
        @plotter_state = {
          paused: false,
          show_legend: true,
          show_help: false,
          y_min: DEFAULT_Y_MIN,
          y_max: DEFAULT_Y_MAX,
          y_grid_lines: DEFAULT_Y_GRID_LINES,
          active_series: {},
          series_visibility: {},
          data_rate: 0.0,
          data_count: 0,
          rate_window: [],
          rate_stable: false
        }
        
        # Initialize state for the command bar
        @command_state = {
          text: "",
          active: false
        }

        # Initialize components
        @command_bar = Components::CommandBar.new(self, @font, @theme_manager)
        @plotter = Components::PlotterComponent.new(self, @font, @theme_manager, @data_buffer)
        @help_dialog = Components::HelpDialog.new(self, @font, @theme_manager)
        @status_bar = Components::StatusBar.new(self, @font, @theme_manager)
        
        # Set up help content
        setup_help_content

        connect_serial
      end
      
      def setup_help_content
        @help_content = [
          "KEYBOARD SHORTCUTS:",
          "Space - Pause/resume data collection",
          "L - Toggle legend display",
          "H - Show/hide this help dialog",
          "1-9 - Toggle series visibility",
          "",
          "COMMANDS:",
          "help - Show this help screen",
          "clear - Clear all data points",
          "exit - Close the plotter"
        ]
        
        # Set the content in the help dialog
        @help_dialog.set_content(@help_content)
      end
      
      def resize(requested_width, requested_height)
        # Enforce minimum window size
        safe_width = [requested_width, MIN_WINDOW_WIDTH].max
        safe_height = [requested_height, MIN_WINDOW_HEIGHT].max
        
        # Call Gosu's parent class resize method with our enforced dimensions
        super(safe_width, safe_height)
        
        # Force a complete redraw
        self.needs_redraw = true
      end

      def update_interface
        # Read from serial if not paused
        unless @plotter_state[:paused]
          data = @serial_connection.read_data
          if data && !data.empty?
            process_serial_data(data)
          end
        end
        
        # Always update y-scale (autoscale always enabled)
        update_y_scale
        
        # Update status bar
        update_status_bar
        
        # Update text input for command bar
        if @command_state[:active] && text_input.nil?
          self.text_input = Gosu::TextInput.new
          self.text_input.text = @command_state[:text]
        elsif !@command_state[:active] && text_input
          self.text_input = nil
        end
        
        # Update command text from text input
        if @command_state[:active] && text_input
          # Only update if they're different to avoid circular updates
          if text_input.text != @command_state[:text]
            @command_state[:text] = text_input.text
          end
        end
      end
      
      def draw_interface
        @plotter.draw
        @status_bar.draw
        @command_bar.draw
        @help_dialog.draw
      end
      
      def process_serial_data(data)
        # Parse the data
        parsed_data = @serial_parser.process_data(data)
        
        # Only continue if we actually got some parsed data
        return if parsed_data.empty?
        
        # Track data rate
        current_time = Time.now
        update_data_rate(parsed_data.size, current_time)
        
        # Add each parsed data point to the buffer
        parsed_data.each do |data_point|
          @data_buffer.add_data_point(data_point)
        end
      end

      def button_down(id)
        super
        
        # Handle command bar input
        if id == Gosu::KB_TAB
          toggle_command_bar
        elsif @command_state[:active]
          command = handle_command_key(id)
          if command
            process_command(command)
          end
        end

        # Handle plotter-specific keys (only when command bar isn't active)
        unless @command_state[:active]
          case id
          when Gosu::KB_SPACE
            toggle_pause
          when Gosu::KB_L
            toggle_legend
          when Gosu::KB_H
            toggle_help
          when Gosu::KB_1, Gosu::KB_2, Gosu::KB_3, Gosu::KB_4, Gosu::KB_5, Gosu::KB_6, Gosu::KB_7, Gosu::KB_8, Gosu::KB_9
            handle_number_key(id)
          end
        end
      end
      
      # State manipulation methods
      
      def toggle_pause
        @plotter_state[:paused] = !@plotter_state[:paused]
        # Clear rate calculation when unpausing to get fresh data
        if !@plotter_state[:paused]
          @plotter_state[:rate_window].clear
          @plotter_state[:data_rate] = 0.0
          @plotter_state[:rate_stable] = false
        end
      end
      
      
      def toggle_legend
        @plotter_state[:show_legend] = !@plotter_state[:show_legend]
      end
      
      def toggle_help
        @plotter_state[:show_help] = !@plotter_state[:show_help]
      end
      
      def toggle_command_bar
        @command_state[:active] = !@command_state[:active]
        @command_state[:text] = "" if @command_state[:active]
      end
      
      def handle_number_key(key_id)
        # Convert key ID to number (1-9)
        number = key_id - Gosu::KB_1 + 1
        
        # Get active series list
        active_series = @plotter_state[:active_series]
        return if active_series.empty?
        
        # Get series name by index
        series_names = active_series.keys
        return if number > series_names.size
        
        series_name = series_names[number - 1]
        toggle_series_visibility(series_name)
      end
      
      def toggle_series_visibility(series_name)
        # Default to visible if not set
        current_visibility = @plotter_state[:series_visibility][series_name]
        current_visibility = true if current_visibility.nil?
        
        # Toggle visibility
        @plotter_state[:series_visibility][series_name] = !current_visibility
      end
      
      def handle_command_key(id)
        return nil unless @command_state[:active]
        
        if id == Gosu::KB_RETURN
          command = @command_state[:text].strip
          @command_state[:text] = "" # clear state
          self.text_input.text = "" if self.text_input #clear text input.
          return command
        elsif id == Gosu::KB_ESCAPE
          @command_state[:active] = false
          return nil
        end
        
        return nil
      end
      
      def update_y_scale
        stats = @data_buffer.statistics
        return if stats.empty?
        
        data_min, data_max = calculate_data_range(stats)
        padding = calculate_y_scale_padding(data_min, data_max)
        
        update_y_scale_if_needed(data_min, data_max, padding)
      end
      
      def process_command(command)
        # Process commands entered in the command bar
        case command.downcase
        when "clear"
          # Clear the data buffer
          @data_buffer.clear
        when "help"
          # Toggle help dialog
          toggle_help
        when "exit"
          close
        else
          # Send the command to the Arduino
          @serial_connection.write_line(command)
        end

        @command_state[:text] = ""
      end

      def update_status_bar
        # Connection status
        if @serial_connection&.connected
          @status_bar.set_status("Port", @config.dig(:basic, :port) || "Unknown", @theme_manager.text_color)
        else
          @status_bar.set_status("Port", "Disconnected", Gosu::Color::RED)
        end
        
        # Pause status
        if @plotter_state[:paused]
          @status_bar.set_status("Status", "Paused", Gosu::Color::YELLOW)
        else
          @status_bar.set_status("Status", "Active", @theme_manager.text_color)
        end
        
        # Data rate - show -- when calculation is unstable
        if @plotter_state[:rate_stable]
          rate = @plotter_state[:data_rate]
          rate_text = "#{rate.round(1)} Hz"
        else
          rate_text = "--"
        end
        @status_bar.set_status("Rate", rate_text, @theme_manager.text_color)
      end
      
      def update_data_rate(data_points, current_time)
        # Keep a rolling window of data timestamps for rate calculation
        @plotter_state[:rate_window] << current_time
        @plotter_state[:data_count] += data_points
        
        # Keep only last 10 seconds of data for rate calculation (longer window for stability)
        cutoff_time = current_time - 10.0
        @plotter_state[:rate_window].reject! { |time| time < cutoff_time }
        
        # Calculate rate based on data points in the last 10 seconds
        if @plotter_state[:rate_window].size > 1
          time_span = @plotter_state[:rate_window].last - @plotter_state[:rate_window].first
          if time_span > 0
            # Calculate data points per second
            points_in_window = @plotter_state[:rate_window].size
            new_rate = points_in_window / time_span
            
            # Apply exponential smoothing to reduce jitter (especially for low rates)
            if @plotter_state[:rate_stable]
              # Smooth the rate with previous value (85% old, 15% new for more smoothing)
              @plotter_state[:data_rate] = @plotter_state[:data_rate] * 0.85 + new_rate * 0.15
            else
              @plotter_state[:data_rate] = new_rate
            end
            
            # Mark as stable when we have at least 5 seconds of data and 3+ points
            @plotter_state[:rate_stable] = time_span >= 5.0 && points_in_window >= 3
          end
        else
          @plotter_state[:data_rate] = 0.0
          @plotter_state[:rate_stable] = false
        end
      end

      def calculate_data_range(stats)
        min_values = stats.values.map { |s| s[:min] }
        max_values = stats.values.map { |s| s[:max] }
        [min_values.min, max_values.max]
      end
      
      def calculate_y_scale_padding(data_min, data_max)
        range = data_max - data_min
        [range * Y_SCALE_PADDING_RATIO, MIN_Y_SCALE_PADDING].max
      end
      
      def update_y_scale_if_needed(data_min, data_max, padding)
        needs_update = @plotter_state[:y_min].nil? || @plotter_state[:y_max].nil? ||
                       (data_min - padding < @plotter_state[:y_min]) ||
                       (data_max + padding > @plotter_state[:y_max])
        
        return unless needs_update
        
        @plotter_state[:y_min] = data_min - padding
        @plotter_state[:y_max] = data_max + padding
        
        ensure_minimum_y_range
      end
      
      def ensure_minimum_y_range
        current_range = (@plotter_state[:y_max] - @plotter_state[:y_min]).abs
        return unless current_range < MIN_Y_RANGE
        
        @plotter_state[:y_min] -= Y_RANGE_FALLBACK
        @plotter_state[:y_max] += Y_RANGE_FALLBACK
      end
      
      def connect_serial
        # Get baud rate from config or registry defaults
        baud_rate = @config.dig(:interface, :baud_rate) || 9600
        
        port = @config.dig(:basic, :port)
        
        begin
          # Make sure we're not already connected
          @serial_connection.disconnect if @serial_connection.connected
          
          # Try to connect
          result = @serial_connection.connect
          Grot::Debug.info "Connection result: #{result}, Connected: #{@serial_connection.connected}"
          
          if @serial_connection.connected
            Grot::Debug.info "Successfully connected to serial port"
          else
            Grot::Debug.error "Failed to connect to serial port, no error thrown"
          end
        rescue => e
          # Show connection error in window
          @connection_error = "Failed to connect: #{e.message}"
          Grot::Debug.error "Connection error: #{e.message}"
        end
      end
    end
  end
end