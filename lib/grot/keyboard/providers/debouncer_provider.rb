# frozen_string_literal: true

require 'grot/keyboard/module_provider'
require 'grot/keyboard/modules/debouncer_module'
require 'grot/keyboard/key_constants'
require 'grot/config/config_registry'

Grot::Keyboard::ModuleProvider.register(
  :debouncer,
  Grot::Keyboard::Modules::Debouncer,
  60
) do |config|
  # Get module-specific config
  module_config = config[:module_config] || {}
  
  # Get registry instance
  registry = Grot::Config::ConfigRegistry.instance
  
  # Special configs for arrow keys - slower repeat for improved menu navigation
  arrow_keys_config = {
    repeat_delay: registry.get_nested_value(
      module_config, 
      [:arrow_keys, :repeat_delay], 
      :keyboard_debouncer, 
      :arrow_keys_repeat_delay, 
      0.3
    ),
    repeat_rate: registry.get_nested_value(
      module_config, 
      [:arrow_keys, :repeat_rate], 
      :keyboard_debouncer, 
      :arrow_keys_repeat_rate, 
      0.12
    )
  }
  
  # Special configs for navigation keys (page up/down, home, end)
  navigation_keys_config = {
    repeat_delay: registry.get_nested_value(
      module_config, 
      [:navigation_keys, :repeat_delay], 
      :keyboard_debouncer, 
      :navigation_keys_repeat_delay, 
      0.4
    ),
    repeat_rate: registry.get_nested_value(
      module_config, 
      [:navigation_keys, :repeat_rate], 
      :keyboard_debouncer, 
      :navigation_keys_repeat_rate, 
      0.15
    )
  }
  
  # Return the full configuration
  {
    # Enable by default unless explicitly disabled
    enabled: registry.get_value(module_config, :keyboard_debouncer, :enabled, true),
    
    # Priority from config or default
    priority: registry.get_value(module_config, :keyboard_debouncer, :priority, 60),
    
    # Configuration options
    repeat_delay: registry.get_value(module_config, :keyboard_debouncer, :repeat_delay, 0.5),
    repeat_rate: registry.get_value(module_config, :keyboard_debouncer, :repeat_rate, 0.05),
    arrow_keys: arrow_keys_config,
    navigation_keys: navigation_keys_config,
    key_configs: module_config[:key_configs] || {},
  }
end
