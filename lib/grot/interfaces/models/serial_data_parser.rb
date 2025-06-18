# frozen_string_literal: true

require 'grot/config/config_registry'

module Grot
  module Interfaces
    module Models
      # SerialDataParser converts raw serial data into structured format
      # It handles buffering and Arduino-style serial data parsing
      class SerialDataParser
        def initialize(config = {})
          # Get registry instance
          registry = Grot::Config::ConfigRegistry.instance
          
          # Get buffer size from config, registry, or default
          @buffer_size = config[:parser_buffer_size] || 
                         config[:buffer_size] || 
                         registry.get_value({}, :plotter, :parser_buffer_size, 4096)
          
          @buffer = ""
          reset
        end
        
        # Process a chunk of raw data and extract complete lines
        # Returns an array of parsed data points (Hash of name => value)
        def process_data(data)
          return [] if data.nil? || data.empty?
          
          results = []
          
          # Add new data to buffer
          @buffer += data
          
          # Process complete lines
          while line_end = @buffer.index("\n")
            line = @buffer[0...line_end].strip
            @buffer = @buffer[(line_end + 1)..-1] || ""
            
            # Skip empty lines
            next if line.empty?
            
            # Parse the line and add to results
            parsed = parse_line(line)
            results << parsed unless parsed.empty?
          end
          
          # Prevent buffer from growing too large
          if @buffer.length > @buffer_size
            # Keep only the last 1/4 of the buffer if it gets too large
            @buffer = @buffer[-@buffer_size/4..-1] || ""
          end
          
          results
        end
        
        # Clear the internal buffer
        def reset
          @buffer = ""
        end
        
        # Parse a line into key-value pairs
        # Returns a hash of { series_name => value }
        def parse_line(line)
          result = {}
          
          # Try labeled format first (name:value name2:value2)
          if line.include?(':')
            # Parse labels and values in Arduino format
            # For format: "Room Temp:80.12 Outside Temp:-30.45 Humidity %:100.00"
            # First extract all parts that might contain label:value pairs
            parts = []
            current_part = ""
            value_found = false
            
            line.chars.each_with_index do |char, i|
              current_part += char
              
              # When we find a colon, we've likely found the label separator
              if char == ':'
                value_found = true
              # When we find a space after a value has been found, we're at the end of a part
              elsif char == ' ' && value_found && i < line.length - 1
                # If the next character is not a digit or minus, 
                # we're probably starting a new label
                if line[i+1] !~ /[\d\-\.]/
                  parts << current_part.strip
                  current_part = ""
                  value_found = false
                end
              end
            end
            
            # Add the last part if not empty
            parts << current_part.strip if !current_part.strip.empty?
            
            # Process each part to extract label and value
            parts.each do |part|
              if part =~ /(.+):(-?\d+\.?\d*)/
                name = $1.strip
                value = $2.to_f
                result[name] = value
              end
            end
          else
            # If no labels, treat as space-separated values
            values = line.strip.split(/\s+/)
            
            # Only proceed if we have numeric values
            has_numeric = false
            
            # Try to convert each value to a float
            values.each_with_index do |val, idx|
              begin
                # Use index as name for unlabeled series
                result["Series #{idx+1}"] = Float(val)
                has_numeric = true
              rescue ArgumentError
                # Skip non-numeric values
              end
            end
            
            # If no numeric values were found, return empty hash
            return {} unless has_numeric
          end
          
          result
        end
      end
    end
  end
end