# frozen_string_literal: true

require 'grot/keyboard/key_constants'

module Grot
  module Config
    DEFAULTS = {
      basic: {
        cli_path: "arduino-cli"
      },
      
      interface: {
        baud_rate: 9600,
        logs_directory: "#{Dir.home}/grot_logs"
      },
      
      plotter: {
        buffer_size: 500
      },
      
      monitor: {
        buffer_size: 10000,
        auto_start_logging: false,
        log_directory: "./log"
      },
      
      keyboard: {
        auto_load_modules: true
      },
      
      # Board-specific defaults
      esp32_options: {
        core_config: "dual",
        frequency: 240
      },
      
      giga_options: {
        target_core: "CM7",
        flash_split: 0.5
      },
      
      # Keyboard module configurations
      keyboard_key_state: {
        enabled: true,
        priority: 90
      },
      
      keyboard_debouncer: {
        enabled: true,
        priority: 60,
        repeat_delay: 0.5,
        repeat_rate: 0.05,
        arrow_keys_repeat_delay: 0.3,
        arrow_keys_repeat_rate: 0.12,
        navigation_keys_repeat_delay: 0.4,
        navigation_keys_repeat_rate: 0.15
      },
      
      keyboard_mac_adapter: {
        enabled: (Grot::Keyboard::KeyConstants.platform == :macos),
        priority: 70,
        command_fix: true,
        auto_fix_stuck_modifiers: true
      },
      
      keyboard_linux_adapter: {
        enabled: (Grot::Keyboard::KeyConstants.platform == :linux),
        priority: 71,
        fix_window_manager_conflicts: true
      },
      
      keyboard_stuck_key_fixer: {
        enabled: true,
        priority: 50,
        auto_release_delay: 1.0
      },
      
      keyboard_buffer: {
        enabled: true,
        priority: 80,
        buffer_time: 0.01
      }
    }.freeze
  end
end