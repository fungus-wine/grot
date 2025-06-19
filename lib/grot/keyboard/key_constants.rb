# frozen_string_literal: true

require 'gosu'

module Grot
  module Keyboard
    module KeyConstants

      LETTERS = [
        Gosu::KB_A, Gosu::KB_B, Gosu::KB_C, Gosu::KB_D, Gosu::KB_E,
        Gosu::KB_F, Gosu::KB_G, Gosu::KB_H, Gosu::KB_I, Gosu::KB_J,
        Gosu::KB_K, Gosu::KB_L, Gosu::KB_M, Gosu::KB_N, Gosu::KB_O,
        Gosu::KB_P, Gosu::KB_Q, Gosu::KB_R, Gosu::KB_S, Gosu::KB_T,
        Gosu::KB_U, Gosu::KB_V, Gosu::KB_W, Gosu::KB_X, Gosu::KB_Y,
        Gosu::KB_Z
      ].freeze

      NUMBERS = [
        Gosu::KB_0, Gosu::KB_1, Gosu::KB_2, Gosu::KB_3, Gosu::KB_4,
        Gosu::KB_5, Gosu::KB_6, Gosu::KB_7, Gosu::KB_8, Gosu::KB_9
      ].freeze

      NUMPAD = [
        Gosu::KB_NUMPAD_0, Gosu::KB_NUMPAD_1, Gosu::KB_NUMPAD_2, Gosu::KB_NUMPAD_3, Gosu::KB_NUMPAD_4,
        Gosu::KB_NUMPAD_5, Gosu::KB_NUMPAD_6, Gosu::KB_NUMPAD_7, Gosu::KB_NUMPAD_8, Gosu::KB_NUMPAD_9,
        Gosu::KB_NUMPAD_PLUS, Gosu::KB_NUMPAD_MINUS, Gosu::KB_NUMPAD_MULTIPLY, 
        Gosu::KB_NUMPAD_DIVIDE
      ].freeze

      FUNCTION_KEYS = [
        Gosu::KB_F1, Gosu::KB_F2, Gosu::KB_F3, Gosu::KB_F4, Gosu::KB_F5,
        Gosu::KB_F6, Gosu::KB_F7, Gosu::KB_F8, Gosu::KB_F9, Gosu::KB_F10,
        Gosu::KB_F11, Gosu::KB_F12
      ].freeze

      ARROWS = [
        Gosu::KB_UP, Gosu::KB_DOWN, Gosu::KB_LEFT, Gosu::KB_RIGHT
      ].freeze

      NAVIGATION = [
        Gosu::KB_HOME, Gosu::KB_END, Gosu::KB_PAGE_UP, Gosu::KB_PAGE_DOWN
      ].freeze

      MODIFIERS = [
        Gosu::KB_LEFT_SHIFT, Gosu::KB_RIGHT_SHIFT,
        Gosu::KB_LEFT_CONTROL, Gosu::KB_RIGHT_CONTROL,
        Gosu::KB_LEFT_ALT, Gosu::KB_RIGHT_ALT,
        Gosu::KB_LEFT_META, Gosu::KB_RIGHT_META
      ].freeze

      EDITING = [
        Gosu::KB_BACKSPACE, Gosu::KB_DELETE, Gosu::KB_INSERT,
        Gosu::KB_TAB, Gosu::KB_RETURN, Gosu::KB_ESCAPE
      ].freeze

      WHITESPACE = [
        Gosu::KB_SPACE, Gosu::KB_TAB, Gosu::KB_RETURN
      ].freeze

      KEY_NAMES = {
        # Special keys
        Gosu::KB_ESCAPE => "Escape",
        Gosu::KB_SPACE => "Space",
        Gosu::KB_LEFT => "Left",
        Gosu::KB_RIGHT => "Right",
        Gosu::KB_UP => "Up",
        Gosu::KB_DOWN => "Down",
        Gosu::KB_RETURN => "Return",
        Gosu::KB_TAB => "Tab",
        Gosu::KB_HOME => "Home",
        Gosu::KB_END => "End",
        Gosu::KB_PAGE_UP => "Page Up",
        Gosu::KB_PAGE_DOWN => "Page Down",
        Gosu::KB_INSERT => "Insert",
        Gosu::KB_DELETE => "Delete",
        Gosu::KB_BACKSPACE => "Backspace",
        Gosu::KB_LEFT_SHIFT => "Left Shift",
        Gosu::KB_RIGHT_SHIFT => "Right Shift",
        Gosu::KB_LEFT_CONTROL => "Left Control",
        Gosu::KB_RIGHT_CONTROL => "Right Control",
        Gosu::KB_LEFT_ALT => "Left Alt",
        Gosu::KB_RIGHT_ALT => "Right Alt",
        Gosu::KB_LEFT_META => "Left Meta",
        Gosu::KB_RIGHT_META => "Right Meta",
        
        # Would include full mapping in actual implementation
      }.freeze

      def self.key_name(key_code)
        KEY_NAMES[key_code] || "Key #{key_code}"
      end

      def self.modifier_key?(key_code)
        MODIFIERS.include?(key_code)
      end

      def self.letter_key?(key_code)
        LETTERS.include?(key_code)
      end

      def self.number_key?(key_code)
        NUMBERS.include?(key_code)
      end

      def self.arrow_key?(key_code)
        ARROWS.include?(key_code)
      end

      def self.navigation_key?(key_code)
        NAVIGATION.include?(key_code)
      end

      def self.platform
        @platform ||= detect_platform
      end

      private

      # move this into a grot utils module if it becomes unclear why it's here
      def self.detect_platform
        case RUBY_PLATFORM
        when /darwin/
          :macos
        when /linux/
          :linux
        when /mingw|mswin/
          :windows
        else
          :unknown
        end
      end
    end
  end
end