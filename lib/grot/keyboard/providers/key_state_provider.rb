require 'grot/keyboard/module_provider'
require 'grot/keyboard/modules/key_state_module'

Grot::Keyboard::ModuleProvider.register(
  :key_state,
  Grot::Keyboard::Modules::KeyState,
  90
) do |config|
  # Get module-specific config with defaults
  keyboard_config = config[:keyboard_key_state] || {}
  
  # Return configuration hash with defaults
  {
    enabled: keyboard_config[:enabled] != false, # Default to true
    priority: keyboard_config[:priority] || 90
  }
end