# frozen_string_literal: true

require "grot/boards/board_registry"
require "grot/cli/colorator"
require "grot/errors"

module Grot
  module Ports
    class PortHandler
      include Grot::CLI::Colorator
      
      # Port detection patterns organized by platform
      PORT_PATTERNS = {
        # macOS - more comprehensive patterns
        'darwin' => ['/dev/cu.*', '/dev/tty.*'],
        # Linux - support for common Arduino ports
        'linux' => ['/dev/tty[A-Za-z]*', '/dev/ttyACM*', '/dev/ttyUSB*'],
      }.freeze
      
      def validate_port(port)
        return unless port
        
        # Check if the specified port exists
        unless File.exist?(port)
          raise Grot::Errors::SerialPortError, "Specified port '#{port}' not found. Run 'grot ports' to see available ports."
        end
        
        # On Linux, check if port is accessible
        if RUBY_PLATFORM =~ /linux/ && !File.readable?(port)
          raise Grot::Errors::SerialPortError, "Port '#{port}' exists but is not accessible. You might need to add your user to the 'dialout' group with: sudo usermod -a -G dialout $USER"
        end
        return port
      end
      
      def list_available_ports
        ports = find_available_ports

        if ports.empty?
          puts no_ports_found_message
        else
          ports.each do |port|
            puts "#{port}#{guess_device_type(port)}"
          end
        end
      end
      
      # Find a most likely Arduino port to use in default config
      def detect_best_port
        ports = find_available_ports
        
        # No ports available
        return nil if ports.empty?
        
        # Look for likely Arduino ports first
        arduino_ports = ports.select { |p| p =~ /usb|acm|arduino|modem/i }
        return arduino_ports.first unless arduino_ports.empty?
        
        # If no obvious Arduino ports, just return the first port
        ports.first
      end
      
      def detect_board_info(port)
        return nil unless port
        
        # Try to detect board type using arduino-cli
        begin
          output = `arduino-cli board list`
          
          # Check if the command was successful
          unless $?.success?
            # Don't raise an error, just return the port
            return { :port => port }
          end
          
          # Parse the output to find the board connected to our port
          port_base = port.split('/').last
          output.each_line do |line|
            # Match line containing our port
            if line.include?(port_base)
              # Extract FQBN - look for a pattern with 3 colon-separated segments
              if line =~ /([a-zA-Z0-9_-]+:[a-zA-Z0-9_-]+:[a-zA-Z0-9_-]+)/
                fqbn = $1
                
                # Check if this is a supported board
                if Grot::Boards::BoardRegistry.supported?(fqbn)
                  board_info = Grot::Boards::BoardRegistry.get_board_info(fqbn)
                  return {
                    :port => port,
                    :fqbn => fqbn,
                    'board_type' => board_info[:strategy]
                  }
                else
                  # Unsupported board detected
                  return {
                    :port => port,
                    :fqbn => fqbn,
                    'board_type' => 'default'
                  }
                end
              end
            end
          end
        rescue => e
          error "Error detecting board: #{e.message}" if ENV['DEBUG']
          # If arduino-cli fails or isn't available, just return the port
          return { :port => port }
        end
        
        # Board detection failed, just return the port
        { :port => port }
      end
      
      private
      
      def no_ports_found_message
        message = [
          "No serial ports found.",
          "Make sure your device is connected and drivers are installed."
        ]
        
        # Add platform-specific guidance
        if RUBY_PLATFORM =~ /darwin/
          message << "On macOS, check System Information to see if the device appears under USB."
          message << "For some Arduino boards, you may need to install additional drivers."
        elsif RUBY_PLATFORM =~ /linux/
          message << "On Linux, make sure you have permission to access serial ports."
          message << "Try running: sudo usermod -a -G dialout $USER"
          message << "Then log out and back in for the changes to take effect."
        end
        
        message << "For Arduino devices, you may need to press the reset button."
        message.join("\n")
      end
      
      def find_available_ports
        # Determine port patterns based on the current platform
        patterns = []
        
        if RUBY_PLATFORM =~ /darwin/
          patterns = PORT_PATTERNS['darwin']
        elsif RUBY_PLATFORM =~ /linux/
          patterns = PORT_PATTERNS['linux']
        else
          # Unknown platform, use empty list
          warning "Unsupported platform for port detection: #{RUBY_PLATFORM}"
          return []
        end
        
        # Find all ports matching the patterns
        ports = []
        patterns.each do |pattern|
          ports.concat(Dir.glob(pattern))
        end
        
        ports
      end
      
      def guess_device_type(port)
        # Try to provide helpful information about what device this port might be
        case port
        when /usb|acm/i
          # USB-based serial ports, likely Arduino or similar
          " (Possibly Arduino/USB device)"
        when /bluetooth/i
          " (Bluetooth device)"
        when /usbmodem/i
          " (Likely Arduino)"
        else
          ""
        end
      end
    end
  end
end