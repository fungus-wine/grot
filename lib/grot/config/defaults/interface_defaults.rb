# frozen_string_literal: true

require_relative '../config_registry'

module Grot
  module Config
    module Defaults
      module InterfaceDefaults
        def self.load_defaults(registry = ConfigRegistry.instance)
          # Define interface-related categories
          registry.define_category(:interface, "Common interface settings")
          registry.define_category(:monitor, "Serial monitor settings")
          registry.define_category(:plotter, "Serial plotter settings")
          
          # Common interface settings
          load_common_interface_config(registry)
          
          # Monitor-specific settings
          load_monitor_config(registry)
          
          # Plotter-specific settings
          load_plotter_config(registry)
        end

        # These settings apply to both monitor and plotter        
        def self.load_common_interface_config(registry)
          
          registry.add_option(
            :interface,
            :baud_rate,
            :integer,
            9600,
            "Default serial baud rate"
          )
          
          registry.add_option(
            :interface,
            :logs_directory,
            :string,
            "#{Dir.home}/grot_logs",
            "Directory for saving log files"
          )
        end
        
        def self.load_monitor_config(registry)
          registry.add_option(
            :monitor,
            :buffer_size,
            :integer,
            10000,
            "Maximum number of lines to keep in the monitor buffer"
          )
          
          registry.add_option(
            :monitor,
            :show_timestamps,
            :boolean,
            false,
            "Show timestamps for each line by default"
          )
          
          registry.add_option(
            :monitor,
            :show_line_numbers,
            :boolean,
            false,
            "Show line numbers by default"
          )
          
          registry.add_option(
            :monitor,
            :timestamp_format,
            :string,
            "%H:%M:%S.%L",
            "Format for timestamps (strftime format string)"
          )
          
          registry.add_option(
            :monitor,
            :auto_scroll,
            :boolean,
            true,
            "Automatically scroll to the bottom when new data arrives"
          )
        end
        
        def self.load_plotter_config(registry)
          registry.add_option(
            :plotter,
            :buffer_size,
            :integer,
            500,
            "Maximum number of data points to keep for each series"
          )
          
        end
      end
    end
  end
end

# Load the defaults when this file is required
Grot::Config::Defaults::InterfaceDefaults.load_defaults