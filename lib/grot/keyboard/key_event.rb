# frozen_string_literal: true

module Grot
  module Keyboard
    class KeyEvent
      # Event types
      KEY_DOWN = :key_down
      KEY_UP = :key_up  
      KEY_HELD = :key_held

      attr_reader :type, :key_code, :modifiers, :timestamp

      def initialize(type, key_code, modifiers = {}, timestamp = nil)
        @type = type
        @key_code = key_code
        @modifiers = modifiers || {}
        @timestamp = timestamp || Time.now.to_f
      end

      def key_down?
        @type == KEY_DOWN
      end

      def key_up?
        @type == KEY_UP
      end

      def key_held?
        @type == KEY_HELD
      end

      def modifier?(modifier)
        @modifiers[modifier] == true
      end

      def age(current_time = Time.now.to_f)
        current_time - @timestamp
      end

      def to_s
        "KeyEvent[#{@type}, key:#{@key_code}, mods:#{@modifiers}, time:#{@timestamp}]"
      end
    end
  end
end