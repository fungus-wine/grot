# frozen_string_literal: true

module Grot
  module Keyboard
    module MacUtils
      # Key codes that are commonly problematic on macOS
      PROBLEM_KEYS = [
        Gosu::KB_LEFT_META,      # Left Command key
        Gosu::KB_RIGHT_META,     # Right Command key
        Gosu::KB_LEFT_ALT,       # Left Option key
        Gosu::KB_RIGHT_ALT,      # Right Option key
        Gosu::KB_TAB             # Tab key
      ].freeze
      
      # Key codes that need special repeat rate handling on macOS
      SPECIAL_REPEAT_KEYS = {
        # Command key combinations
        Gosu::KB_Q => { repeat_delay: 0.5, repeat_rate: 0.0 },  # No repeat for Cmd+Q
        Gosu::KB_W => { repeat_delay: 0.5, repeat_rate: 0.0 },  # No repeat for Cmd+W
        # Option key combinations for special characters
        Gosu::KB_E => { repeat_delay: 0.3, repeat_rate: 0.15 },  # Option+E for accented e
        Gosu::KB_U => { repeat_delay: 0.3, repeat_rate: 0.15 },  # Option+U for umlaut
        Gosu::KB_N => { repeat_delay: 0.3, repeat_rate: 0.15 }   # Option+N for tilde
      }.freeze
      
      # Returns true if running on macOS
      def self.macos?
        @macos ||= (RUBY_PLATFORM =~ /darwin/) != nil
      end
      
      # Returns configuration for the stuck key fixer
      def self.stuck_key_config
        {
          problem_keys: PROBLEM_KEYS,
          auto_release_delay: 1.0  # 1 second for macOS
        }
      end
      
      # Returns configuration for key repeat handling
      def self.key_repeat_config
        {
          special_keys: SPECIAL_REPEAT_KEYS,
          default_repeat_delay: 0.4,  # 400ms initial delay
          default_repeat_rate: 0.05   # 50ms between repeats (20Hz)
        }
      end
      
      # Check if a key is a command key
      def self.command_key?(key_code)
        [Gosu::KB_LEFT_META, Gosu::KB_RIGHT_META].include?(key_code)
      end
      
      # Check if a key is an option key
      def self.option_key?(key_code)
        [Gosu::KB_LEFT_ALT, Gosu::KB_RIGHT_ALT].include?(key_code)
      end
      
      # Check if a key is a modifier key
      def self.modifier_key?(key_code)
        [
          Gosu::KB_LEFT_META, Gosu::KB_RIGHT_META,
          Gosu::KB_LEFT_ALT, Gosu::KB_RIGHT_ALT,
          Gosu::KB_LEFT_CONTROL, Gosu::KB_RIGHT_CONTROL,
          Gosu::KB_LEFT_SHIFT, Gosu::KB_RIGHT_SHIFT
        ].include?(key_code)
      end
    end
  end
end