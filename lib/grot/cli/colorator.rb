# frozen_string_literal: true

module Grot
  module CLI
    # Provides colorized output capabilities
    module Colorator
      # ANSI color codes
      COLORS = {
        reset: "\e[0m",
        bold: "\e[1m",
        italic: "\e[3m",
        underline: "\e[4m",
        black: "\e[30m",
        red: "\e[31m",
        green: "\e[32m",
        yellow: "\e[33m",
        blue: "\e[34m",
        magenta: "\e[35m",
        cyan: "\e[36m",
        white: "\e[37m",
        grey: "\e[90m",
        gray: "\e[90m", # cause spelling
        bright_white: "\e[97m",
        bg_black: "\e[40m",
        bg_red: "\e[41m",
        bg_green: "\e[42m",
        bg_yellow: "\e[43m",
        bg_blue: "\e[44m",
        bg_magenta: "\e[45m",
        bg_cyan: "\e[46m",
        bg_white: "\e[47m"
      }.freeze

      # Colorize text with given color
      # @param text [String] the text to colorize
      # @param color [Symbol] the color to use
      # @return [String] the colorized text
      def colorize(text, color)
        return text unless use_colors?
        "#{COLORS[color]}#{text}#{COLORS[:reset]}"
      end

      # Print info message (cyan)
      # @param text [String] the message to print
      def info(text)
        puts colorize(text, :reset)
      end

      # Print success message (green)
      # @param text [String] the message to print
      def success(text)
        puts colorize(text, :green)
      end

      # Print warning message (yellow)
      # @param text [String] the message to print
      def warning(text)
        puts colorize(text, :yellow)
      end

      # Print error message (red)
      # @param text [String] the message to print
      def error(text)
        puts colorize(text, :red)
      end

      # Print header message (bold cyan)
      # @param text [String] the message to print
      def header(text)
        puts colorize(colorize(text, :bold), :white)
      end

      # Print command message (magenta)
      # @param text [String] the message to print
      def command(text)
        puts colorize(text, :cyan)
      end

      # Print separator line
      def separator
        puts colorize("-" * 80, :white)
      end

      # Determine if colors should be used in output
      # @return [Boolean] true if colors should be used
      def use_colors?
        # Always use colors by default, but provide an escape hatch
        # by checking for NO_COLOR environment variable
        ENV["NO_COLOR"].nil? || ENV["NO_COLOR"].empty?
      end
    end
  end
end