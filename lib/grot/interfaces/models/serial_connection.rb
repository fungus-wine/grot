# frozen_string_literal: true

require 'rubyserial'
require 'grot/config/config_registry'

module Grot
  module Interfaces
    module Models
      class SerialConnection
        DEFAULT_BAUD_RATE = 9600
        
        attr_reader :port_name, :baud_rate, :connected, :error
        
        def initialize(port, baud_rate = nil)
          @port_name = port
          
          # Get registry instance
          registry = Grot::Config::ConfigRegistry.instance
          
          # Get baud rate from param, registry, or default
          @baud_rate = baud_rate || 
                      registry.get_value({}, :interface, :baud_rate, DEFAULT_BAUD_RATE)
          
          @connected = false
          @connection = nil
          @error = nil
        end
        
        def connect
          begin
            @connection = Serial.new(@port_name, @baud_rate)
            @connected = true
            true
          rescue => e
            Grot::Debug.error "Connection failure: #{e.message}"
            @error = e.message
            false
          end
        end
        
        def disconnect
          @connection.close if @connection
          @connected = false
        end
        
        def read_data
          return nil unless @connected
          
          begin
            data = @connection.read(1024)
            return nil if data.nil? || data.empty?
            
            return data
          rescue => e
            @error = e.message
            Grot::Debug.error "Error reading data: #{e.message}"
            nil
          end
        end
        
        def write_data(data)
          return false unless @connected
          
          begin
            @connection.write(data)
            true
          rescue => e
            @error = e.message
            false
          end
        end
        
        def write_line(line)
          write_data("#{line}\n")
        end
      end
    end
  end
end
