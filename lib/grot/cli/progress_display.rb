# frozen_string_literal: true

require "grot/cli/colorator"

module Grot
  module CLI
    module ProgressDisplay
      # Spinner class for displaying animated progress indicators
      class Spinner
        include Grot::CLI::Colorator
        
        # Animation frames
        ANIMATION_FRAMES = ['█', '▓', '▒', '░'].freeze
        
        attr_reader :message, :color
        
        def initialize(message, color = :cyan)
          @message = message
          @color = color
          @frames = ANIMATION_FRAMES
          @current_frame = 0
          @running = false
          @thread = nil
          @interval = 0.2  # Slower animation speed
        end
        
        def start
          return if @running
          
          @running = true
          @start_time = Time.now
          
          # Clear the line and print initial frame
          print "\r" + ' ' * terminal_width + "\r"
          render_frame
          
          # Start the animation thread
          @thread = Thread.new do
            while @running
              sleep @interval
              @current_frame = (@current_frame + 1) % @frames.length
              render_frame
            end
          end
          
          self
        end
        
        def stop(success = true)
          return unless @running
          
          @running = false
          @thread.kill if @thread
          @thread = nil
          
          # Clear line
          print "\r" + ' ' * terminal_width + "\r"
          
          # Print completion message
          if success
            puts colorize("#{message} #{colorize('✓', :green)}", :reset)
          else
            puts colorize("#{message} #{colorize('✗', :red)}", :reset)
          end
          
          self
        end
        
        private
        
        def render_frame
          return unless @running
          
          frame = @frames[@current_frame]
          elapsed = Time.now - @start_time
          elapsed_text = format_elapsed(elapsed)
          
          # Construct the spinner line
          line = "\r#{colorize(frame, @color)} #{@message} #{colorize(elapsed_text, :grey)}"
          
          # Make sure we don't exceed terminal width
          if line.length > terminal_width
            line = line[0..terminal_width-4] + "..."
          end
          
          # Print the spinner frame
          print line
          $stdout.flush
        end
        
        def format_elapsed(seconds)
          if seconds < 60
            "(#{seconds.round(1)}s)"
          else
            mins = (seconds / 60).to_i
            secs = (seconds % 60).round
            "(#{mins}m #{secs}s)"
          end
        end
        
        def terminal_width
          # Get terminal width or default to 80
          if defined?(IO.console) && IO.console
            IO.console.winsize[1]
          else
            80  # Default if unable to determine terminal width
          end
        rescue
          80  # Default if error occurs
        end
      end
    end
  end
end