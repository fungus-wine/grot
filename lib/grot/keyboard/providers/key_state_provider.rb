require 'grot/keyboard/module_provider'
require 'grot/keyboard/modules/key_state_module'
require 'grot/config/config_registry'

Grot::Keyboard::ModuleProvider.register(
  :key_state,
  Grot::Keyboard::Modules::KeyState,
  90
) do |config|
  # Get module-specific config
  module_config = config[:module_config] || {}
  
  # Get registry instance
  registry = Grot::Config::ConfigRegistry.instance
  
  # Get values with registry fallbacks
  enabled = registry.get_value(module_config, :keyboard_key_state, :enabled, true)
  priority = registry.get_value(module_config, :keyboard_key_state, :priority, 90)
  
  # Return configuration hash
  {
    enabled: enabled,
    priority: priority
  }
end