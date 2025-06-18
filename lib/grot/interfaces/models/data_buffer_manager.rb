# frozen_string_literal: true

require 'grot/config/config_registry'

module Grot
  module Interfaces
    module Models
      # DataBufferManager manages time series data storage with ring buffers
      # It can be used by both plotter and monitor interfaces
      class DataBufferManager
        # Default number of data points to keep in history
        DEFAULT_MAX_POINTS = 500
        
        # Default cleanup threshold
        DEFAULT_CLEANUP_THRESHOLD = 1.1  # Clean when buffer reaches 110% of max size
        
        attr_reader :data_series, :timestamps
        
        def initialize(config = {})
          # Get registry instance
          registry = Grot::Config::ConfigRegistry.instance
          
          # Get max points from config, registry, or default
          if config.is_a?(Hash)
            @max_points = config[:buffer_size] || registry.get_value({}, :plotter, :buffer_size, DEFAULT_MAX_POINTS)
          elsif config.is_a?(Integer)
            @max_points = config
          else
            @max_points = registry.get_value({}, :plotter, :buffer_size, DEFAULT_MAX_POINTS)
          end
          
          # Calculate cleanup size based on max points and threshold from config or registry
          cleanup_threshold = registry.get_value({}, :plotter, 'cleanup_threshold', DEFAULT_CLEANUP_THRESHOLD)
          
          # If config is a hash, check if it contains the threshold
          if config.is_a?(Hash) && config[:cleanup_threshold]
            cleanup_threshold = config[:cleanup_threshold]
          end
          
          @cleanup_size = (@max_points * cleanup_threshold).to_i
          
          clear
        end
        
        # Add a new data point
        def add_data_point(data_point, timestamp = Time.now.to_f)
          # Add timestamp
          @timestamps << timestamp
          
          # Add data series
          data_point.each do |name, value|
            # Create series if it doesn't exist
            @data_series[name] ||= []
            
            # Add the value to the series
            @data_series[name] << value.to_f
          end
          
          # Perform cleanup if needed
          cleanup if needs_cleanup?
        end
        
        # Get the most recent data points limited to max_points
        def recent_data
          active_series = {}
          
          @data_series.each do |name, values|
            active_series[name] = values.last(@max_points)
          end
          
          {
            series: active_series,
            timestamps: @timestamps.last(@max_points)
          }
        end
        
        # Get data series statistics
        def statistics
          stats = {}
          
          @data_series.each do |name, values|
            next if values.empty?
            
            active_values = values.last(@max_points)
            
            stats[name] = {
              min: active_values.min,
              max: active_values.max,
              avg: active_values.sum / active_values.size,
              count: active_values.size
            }
          end
          
          stats
        end
        
        # Clear all data
        def clear
          @data_series = {}
          @timestamps = []
        end
        
        private
        
        # Check if buffer needs cleanup
        def needs_cleanup?
          !@timestamps.empty? && @timestamps.size > @cleanup_size
        end
        
        # Cleanup buffer to prevent memory bloat
        def cleanup
          # Trim timestamps to max size
          if @timestamps.size > @max_points
            @timestamps = @timestamps.last(@max_points)
          end
          
          # Trim all data series to max size
          @data_series.each do |name, values|
            if values.size > @max_points
              @data_series[name] = values.last(@max_points)
            end
          end
        end
      end
    end
  end
end
