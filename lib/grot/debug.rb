# frozen_string_literal: true

# Debug utility for Grot
# ======================
#
# This module provides a simple, global debug system that can be used anywhere
# in the codebase without requiring imports in every file.
#
# Features:
# - Global debug() method accessible throughout the codebase
# - Multiple log levels (error, warn, info, debug, trace)
# - Optional context parameter to identify message source
# - Colored output based on log level
# - Configurable via environment variables
# - Timestamp with millisecond precision
# 
# Usage:
#
# Basic debug method (available globally):
#   debug("Message")                       # Uses default :debug level
#   debug("Error message", :error)         # Specify log level
#   debug("Connection info", :info, "TCP") # With context
#
# Level-specific methods:
#   Grot::Debug.error("Something failed")
#   Grot::Debug.warn("Suspicious activity", "Security")
#   Grot::Debug.info("Process started")
#   Grot::Debug.debug("Processing data", "Parser")
#   Grot::Debug.trace("Function called with args", "Utils")
#
# Configuration:
# Set the GROT_DEBUG_LEVEL environment variable to control verbosity:
#   export GROT_DEBUG_LEVEL=error  # Only show errors
#   export GROT_DEBUG_LEVEL=warn   # Show warnings and errors
#   export GROT_DEBUG_LEVEL=info   # Show info and above (default)
#   export GROT_DEBUG_LEVEL=debug  # Show debug messages and above
#   export GROT_DEBUG_LEVEL=trace  # Show everything
#   export GROT_DEBUG_LEVEL=off    # Turn off all debug output
#
# Example in production:
#   GROT_DEBUG_LEVEL=error ruby my_script.rb
#
# Example in development:
#   GROT_DEBUG_LEVEL=debug ruby my_script.rb

module Grot
  # Simple global debug utility that can be used anywhere in the codebase
  module Debug
    # Log levels in order of increasing verbosity
    LEVELS = {
      off: 0,
      error: 1, 
      warn: 2,
      info: 3,
      debug: 4,
      trace: 5
    }.freeze
    
    # ANSI color codes for different log levels
    COLORS = {
      error: "\e[31m", # Red
      warn: "\e[33m",  # Yellow
      info: "\e[36m",  # Cyan
      debug: "\e[35m", # Magenta
      trace: "\e[90m", # Gray
      text: "\e[90m"   # Gray
    }.freeze
    
    RESET_COLOR = "\e[0m"
    
    # Get current log level from environment or default to info
    def self.level
      env_level = ENV['GROT_DEBUG_LEVEL']&.downcase&.to_sym
      env_level && LEVELS.key?(env_level) ? env_level : :info
    end
    
    # Check if a particular log level is enabled
    def self.enabled?(log_level)
      LEVELS[log_level] <= LEVELS[level]
    end
    
    # Main debug method that can be called globally
    def self.log(message, level = :debug, context = nil)
      return unless enabled?(level)
      # Get caller information (file and line)
      caller_info = caller_locations(2,1).first
      file = File.basename(caller_info.path)
      line = caller_info.lineno

      timestamp = "#{COLORS[:text]}#{Time.now.strftime("%H:%M:%S.%L")}#{RESET_COLOR}"

      context_str = context ? "#{COLORS[:text]}(#{context})#{RESET_COLOR}" : ""
      
      location_str = "#{COLORS[:text]}#{line.to_s.ljust(4)}:#{file}#{RESET_COLOR}"
      
      level_str = "[#{COLORS[level]}#{level.to_s.upcase}#{RESET_COLOR}]"
      
      puts "#{timestamp} #{level_str} #{location_str}: #{context_str} #{message}"
    end
    
    # Convenience methods for different log levels
    def self.error(message, context = nil)
      log(message, :error, context)
    end
    
    def self.warn(message, context = nil)
      log(message, :warn, context)
    end
    
    def self.info(message, context = nil)
      log(message, :info, context)
    end
    
    def self.debug(message, context = nil)
      log(message, :debug, context)
    end
    
    def self.trace(message, context = nil)
      log(message, :trace, context)
    end
  end
end

# Define global debug method that is accessible from anywhere
def debug(message, level = :debug, context = nil)
  Grot::Debug.log(message, level, context)
end
