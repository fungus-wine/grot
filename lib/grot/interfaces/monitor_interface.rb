# frozen_string_literal: true

require 'gosu'
require 'fileutils'
require 'grot/interfaces/base_interface'
require 'grot/interfaces/components/command_bar'
require 'grot/interfaces/components/help_dialog'
require 'grot/interfaces/components/status_bar'
require 'grot/interfaces/models/serial_connection'

module Grot
  module Interfaces
    class MonitorInterface < BaseInterface
      WINDOW_TITLE = "Grot Serial Monitor"
      
      # Constants for window sizing
      MIN_WINDOW_WIDTH = 800
      MIN_WINDOW_HEIGHT = 600
      DEFAULT_BUFFER_SIZE = 10000
      
      # Text display constants
      TEXT_MARGIN = 20
      LINE_HEIGHT = 18
      SCROLL_SPEED = 3
      
      attr_reader :monitor_state, :command_state, :text_buffer

      def initialize(config)
        super(config)
        self.caption = WINDOW_TITLE
        self.resizable = true
        
        # Get buffer size from config (defaults already merged)
        buffer_size = config.dig(:monitor, :buffer_size) || DEFAULT_BUFFER_SIZE
        
        # Initialize text buffer for received data
        @text_buffer = []
        @max_buffer_size = buffer_size
        
        # Initialize state for the monitor
        @monitor_state = {
          paused: false,
          show_help: false,
          autoscroll: true,
          scroll_position: 0,
          timestamps: false,
          logging: false,
          log_file: nil,
          log_file_path: nil
        }
        
        # Initialize state for the command bar
        @command_state = {
          text: "",
          active: false
        }

        # Initialize components
        @command_bar = Components::CommandBar.new(self, @font, @theme_manager)
        @help_dialog = Components::HelpDialog.new(self, @font, @theme_manager)
        @status_bar = Components::StatusBar.new(self, @font, @theme_manager)
        
        # Set up help content
        setup_help_content

        # Initialize logging
        setup_logging

        connect_serial
      end
      
      def setup_help_content
        @help_content = [
          "KEYBOARD SHORTCUTS:",
          "Space - Pause/resume data collection",
          "T - Toggle timestamps",
          "L - Start/stop logging to file",
          "B - Insert bookmark in log",
          "H - Show/hide this help dialog",
          "Tab - Activate command input",
          "C - Clear monitor",
          "",
          "COMMANDS:",
          "help - Show this help screen",
          "clear - Clear all received data",
          "exit - Close the monitor"
        ]
        
        # Set the content in the help dialog
        @help_dialog.set_content(@help_content)
      end
      
      def setup_logging
        # Check if auto-start logging is enabled
        auto_start = @config.dig(:monitor, :auto_start_logging) || false
        
        if auto_start
          start_logging
        end
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
        unless @monitor_state[:paused]
          data = @serial_connection.read_data
          if data && !data.empty?
            process_serial_data(data)
          end
        end
        
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
        
        # Update status bar
        update_status_bar
      end
      
      def update_status_bar
        # Connection status
        if @serial_connection&.connected
          @status_bar.set_status("Port", @config.dig(:basic, :port) || "Unknown", @theme_manager.text_color)
        else
          @status_bar.set_status("Port", "Disconnected", Gosu::Color::RED)
        end
        
        # Logging status
        if @monitor_state[:logging]
          @status_bar.set_status("Log", "Recording", @theme_manager.text_color)
          if @monitor_state[:log_file_path]
            @status_bar.set_status("Log File", @monitor_state[:log_file_path], @theme_manager.text_color)
          end
        else
          @status_bar.set_status("Log", "Off", @theme_manager.text_color)
        end
        
        # Pause status
        if @monitor_state[:paused]
          @status_bar.set_status("Status", "Paused", Gosu::Color::YELLOW)
        else
          @status_bar.set_status("Status", "Active", @theme_manager.text_color)
        end
        
        # Timestamps
        if @monitor_state[:timestamps]
          @status_bar.set_status("Timestamps", "On", @theme_manager.text_color)
        else
          @status_bar.set_status("Timestamps", "Off", @theme_manager.text_color)
        end
      end
      
      def draw_interface
        draw_text_display
        @status_bar.draw
        @command_bar.draw
        @help_dialog.draw
      end
      
      def process_serial_data(data)
        # Split data into lines while preserving partial lines
        lines = data.split(/\r?\n/, -1)
        
        # If we have a partial line from before, prepend it to the first line
        if @partial_line && !@partial_line.empty?
          lines[0] = @partial_line + lines[0]
        end
        
        # Save the last element as partial line (might be empty if data ended with newline)
        @partial_line = lines.pop
        
        # Process complete lines
        lines.each do |line|
          add_text_line(line) unless line.empty?
        end
        
        # Auto-scroll to bottom if enabled
        if @monitor_state[:autoscroll]
          @monitor_state[:scroll_position] = 0
        end
      end
      
      def add_text_line(text, color = nil)
        # Log the raw text first (before adding display timestamps)
        write_to_log(text) if @monitor_state[:logging]
        
        # Add timestamp if enabled for display
        if @monitor_state[:timestamps]
          timestamp = Time.now.strftime("%H:%M:%S.%3N")
          text = "[#{timestamp}] #{text}"
        end
        
        # Add to buffer
        @text_buffer << {
          text: text,
          timestamp: Time.now,
          color: color || @theme_manager.text_color
        }
        
        # Trim buffer if it exceeds maximum size
        if @text_buffer.size > @max_buffer_size
          excess = @text_buffer.size - @max_buffer_size
          @text_buffer = @text_buffer.drop(excess)
        end
      end
      
      def draw_text_display
        return if @text_buffer.empty?
        
        # Calculate available space for text (between status bar and command bar)
        text_area_height = height - Components::StatusBar::HEIGHT - Components::CommandBar::HEIGHT
        visible_lines = (text_area_height / LINE_HEIGHT).floor
        
        # Calculate which lines to display based on scroll position
        total_lines = @text_buffer.size
        start_line = [total_lines - visible_lines - @monitor_state[:scroll_position], 0].max
        end_line = [start_line + visible_lines - 1, total_lines - 1].min
        
        # Draw background (positioned below status bar)
        draw_rect(0, Components::StatusBar::HEIGHT, width, text_area_height, @theme_manager.background_color, 0)
        
        # Draw text lines (positioned below status bar)
        (start_line..end_line).each do |i|
          y_position = Components::StatusBar::HEIGHT + (i - start_line) * LINE_HEIGHT
          text_data = @text_buffer[i]
          
          # Use UTF-8 compatible text rendering with custom color
          @font.draw_text(text_data[:text], TEXT_MARGIN, y_position, 1, 1, 1, text_data[:color])
        end
        
        # Draw scrollbar if needed
        draw_scrollbar if total_lines > visible_lines
      end
      
      def draw_scrollbar
        # Simple scrollbar implementation
        scrollbar_width = 10
        scrollbar_x = width - scrollbar_width - 5
        
        text_area_height = height - Components::StatusBar::HEIGHT - Components::CommandBar::HEIGHT
        scrollbar_height = text_area_height
        
        # Calculate scrollbar thumb position and size
        total_lines = @text_buffer.size
        visible_lines = (text_area_height / LINE_HEIGHT).floor
        
        if total_lines > visible_lines
          thumb_height = [scrollbar_height * visible_lines / total_lines, 20].max
          scroll_ratio = @monitor_state[:scroll_position].to_f / (total_lines - visible_lines)
          thumb_y = Components::StatusBar::HEIGHT + (scrollbar_height - thumb_height) * (1 - scroll_ratio)
          
          # Draw scrollbar track (positioned below status bar)
          draw_rect(scrollbar_x, Components::StatusBar::HEIGHT, scrollbar_width, scrollbar_height, @theme_manager.grid_color, 1)
          
          # Draw scrollbar thumb in cyan
          draw_rect(scrollbar_x + 1, thumb_y, scrollbar_width - 2, thumb_height, Gosu::Color::CYAN, 1)
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

        # Handle monitor-specific keys (only when command bar isn't active)
        unless @command_state[:active]
          case id
          when Gosu::KB_SPACE
            toggle_pause
          when Gosu::KB_T
            toggle_timestamps
          when Gosu::KB_L
            toggle_logging
          when Gosu::KB_B
            insert_bookmark
          when Gosu::KB_H
            toggle_help
          when Gosu::KB_UP
            scroll_up
          when Gosu::KB_DOWN
            scroll_down
          when Gosu::KB_PAGE_UP
            scroll_page_up
          when Gosu::KB_PAGE_DOWN
            scroll_page_down
          when Gosu::KB_HOME
            scroll_to_top
          when Gosu::KB_END
            scroll_to_bottom
          when Gosu::KB_C
            clear_monitor
          end
        end
      end
      
      # State manipulation methods
      
      def toggle_pause
        @monitor_state[:paused] = !@monitor_state[:paused]
        # Disable autoscroll when paused to allow manual scrolling
        @monitor_state[:autoscroll] = !@monitor_state[:paused]
      end
      
      def toggle_timestamps
        @monitor_state[:timestamps] = !@monitor_state[:timestamps]
      end
      
      def toggle_logging
        if @monitor_state[:logging]
          stop_logging
        else
          start_logging
        end
      end
      
      def insert_bookmark
        bookmark_text = "=== BOOKMARK: #{Time.now.strftime('%H:%M:%S')} ==="
        add_text_line(bookmark_text, Gosu::Color::CYAN)
      end
      
      def toggle_help
        @monitor_state[:show_help] = !@monitor_state[:show_help]
      end
      
      def toggle_command_bar
        @command_state[:active] = !@command_state[:active]
        @command_state[:text] = "" if @command_state[:active]
      end
      
      def clear_monitor
        @text_buffer.clear
        @partial_line = ""
        @monitor_state[:scroll_position] = 0
      end
      
      # Scrolling methods
      
      def scroll_up
        @monitor_state[:autoscroll] = false
        max_scroll = [@text_buffer.size - visible_line_count, 0].max
        @monitor_state[:scroll_position] = [@monitor_state[:scroll_position] + SCROLL_SPEED, max_scroll].min
      end
      
      def scroll_down
        @monitor_state[:scroll_position] = [@monitor_state[:scroll_position] - SCROLL_SPEED, 0].max
        # Re-enable autoscroll if we've scrolled to the bottom
        @monitor_state[:autoscroll] = true if @monitor_state[:scroll_position] == 0
      end
      
      def scroll_page_up
        @monitor_state[:autoscroll] = false
        page_size = visible_line_count
        max_scroll = [@text_buffer.size - visible_line_count, 0].max
        @monitor_state[:scroll_position] = [@monitor_state[:scroll_position] + page_size, max_scroll].min
      end
      
      def scroll_page_down
        page_size = visible_line_count
        @monitor_state[:scroll_position] = [@monitor_state[:scroll_position] - page_size, 0].max
        # Re-enable autoscroll if we've scrolled to the bottom
        @monitor_state[:autoscroll] = true if @monitor_state[:scroll_position] == 0
      end
      
      def scroll_to_top
        @monitor_state[:autoscroll] = false
        max_scroll = [@text_buffer.size - visible_line_count, 0].max
        @monitor_state[:scroll_position] = max_scroll
      end
      
      def scroll_to_bottom
        @monitor_state[:scroll_position] = 0
        @monitor_state[:autoscroll] = true
      end
      
      def visible_line_count
        text_area_height = height - Components::StatusBar::HEIGHT - Components::CommandBar::HEIGHT
        (text_area_height / LINE_HEIGHT).floor
      end
      
      def handle_command_key(id)
        return nil unless @command_state[:active]
        
        if id == Gosu::KB_RETURN
          command = @command_state[:text].strip
          @command_state[:text] = "" # clear state
          self.text_input.text = "" if self.text_input # clear text input
          return command
        elsif id == Gosu::KB_ESCAPE
          @command_state[:active] = false
          return nil
        end
        
        return nil
      end
      
      def process_command(command)
        # Process commands entered in the command bar
        case command.downcase
        when "clear"
          clear_monitor
        when "help"
          toggle_help
        when "exit"
          close
        else
          # Send the command to the Arduino
          @serial_connection.write_line(command)
          # Show sent command in the monitor with prefix
          sent_command = "> #{command}"
          
          # Log the sent command if logging is enabled
          write_to_log(sent_command) if @monitor_state[:logging]
          
          # Add to display (but don't double-log)
          if @monitor_state[:timestamps]
            timestamp = Time.now.strftime("%H:%M:%S.%3N")
            sent_command = "[#{timestamp}] #{sent_command}"
          end
          
          @text_buffer << {
            text: sent_command,
            timestamp: Time.now,
            color: Gosu::Color::CYAN
          }
        end

        @command_state[:text] = ""
      end
      
      # Logging methods
      
      def find_next_log_number(log_dir)
        # Find existing monitor log files and get the highest number
        existing_logs = Dir.glob(File.join(log_dir, "monitor_*.log"))
        
        if existing_logs.empty?
          return 1
        end
        
        # Extract numbers from filenames
        numbers = existing_logs.map do |file|
          basename = File.basename(file, ".log")
          match = basename.match(/monitor_(\d+)/)
          match ? match[1].to_i : 0
        end
        
        # Return next sequential number
        numbers.max + 1
      end
      
      def start_logging
        return if @monitor_state[:logging]
        
        log_dir = @config.dig(:monitor, :log_directory) || "./log"
        FileUtils.mkdir_p(log_dir) unless Dir.exist?(log_dir)
        
        # Find next sequential number
        next_number = find_next_log_number(log_dir)
        log_filename = "monitor_#{next_number}.log"
        log_path = File.join(log_dir, log_filename)
        
        begin
          @monitor_state[:log_file] = File.open(log_path, 'w')
          @monitor_state[:log_file_path] = log_path
          @monitor_state[:logging] = true
          
          # Write session header
          header = [
            "=== Grot Serial Monitor Log ===",
            "Started: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}",
            "Port: #{@config.dig(:basic, :port)}",
            "Baud Rate: #{@config.dig(:interface, :baud_rate) || 9600}",
            "==============================",
            ""
          ]
          
          header.each { |line| write_to_log(line) }
          add_text_line("=== Logging started: #{log_filename} ===")
          
        rescue => e
          add_text_line("=== Failed to start logging: #{e.message} ===")
        end
      end
      
      def stop_logging
        return unless @monitor_state[:logging]
        
        begin
          if @monitor_state[:log_file]
            write_to_log("")
            write_to_log("=== Session ended: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')} ===")
            @monitor_state[:log_file].close
            @monitor_state[:log_file] = nil
          end
          
          @monitor_state[:logging] = false
          @monitor_state[:log_file_path] = nil
          add_text_line("=== Logging stopped ===")
          
        rescue => e
          add_text_line("=== Error - stopping logging: #{e.message} ===")
          @monitor_state[:logging] = false
          @monitor_state[:log_file] = nil
          @monitor_state[:log_file_path] = nil
        end
      end
      
      def write_to_log(text)
        return unless @monitor_state[:logging] && @monitor_state[:log_file]
        
        begin
          timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S.%3N")
          @monitor_state[:log_file].puts("[#{timestamp}] #{text}")
          @monitor_state[:log_file].flush
        rescue => e
          # If logging fails, stop logging to prevent repeated errors
          add_text_line("Logging error: #{e.message}")
          stop_logging
        end
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
            add_text_line("Connected to #{port} at #{baud_rate} baud")
          else
            Grot::Debug.error "Failed to connect to serial port, no error thrown"
            add_text_line("Failed to connect to #{port}")
          end
        rescue => e
          # Show connection error in window
          @connection_error = "Failed to connect: #{e.message}"
          add_text_line("Connection error: #{e.message}")
          Grot::Debug.error "Connection error: #{e.message}"
        end
      end
      
      def close
        # Stop logging when closing
        stop_logging if @monitor_state[:logging]
        super
      end
    end
  end
end