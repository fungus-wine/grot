# frozen_string_literal: true

require 'grot/keyboard/module_provider'
require 'grot/keyboard/modules/debouncer_module'
require 'grot/keyboard/key_constants'

Grot::Keyboard::ModuleProvider.register(
  :debouncer,
  Grot::Keyboard::Modules::Debouncer,
  60
) do |config|
  # Get module-specific config with defaults
  keyboard_config = config[:keyboard_debouncer] || {}
  
  # Special configs for arrow keys - slower repeat for improved menu navigation
  arrow_keys_config = {
    repeat_delay: keyboard_config.dig(:arrow_keys, :repeat_delay) || 0.3,
    repeat_rate: keyboard_config.dig(:arrow_keys, :repeat_rate) || 0.12
  }
  
  # Special configs for navigation keys (page up/down, home, end)
  navigation_keys_config = {
    repeat_delay: keyboard_config.dig(:navigation_keys, :repeat_delay) || 0.4,
    repeat_rate: keyboard_config.dig(:navigation_keys, :repeat_rate) || 0.15
  }
  
  # Return the full configuration
  {
    # Enable by default unless explicitly disabled
    enabled: keyboard_config[:enabled] != false,
    
    # Priority from config or default
    priority: keyboard_config[:priority] || 60,
    
    # Configuration options
    repeat_delay: keyboard_config[:repeat_delay] || 0.5,
    repeat_rate: keyboard_config[:repeat_rate] || 0.05,
    arrow_keys: arrow_keys_config,
    navigation_keys: navigation_keys_config,
    key_configs: keyboard_config[:key_configs] || {},
  }
end
