require 'grot/keyboard/module_provider'
require 'grot/keyboard/modules/mac_adapter_module'
require 'grot/keyboard/mac_utils'
require 'grot/config/config_registry'

Grot::Keyboard::ModuleProvider.register(
  :mac_adapter,
  Grot::Keyboard::Modules::MacAdapter,
  70
) do |config|
  # Get module-specific config
  module_config = config[:module_config] || {}
  
  # Get registry instance
  registry = Grot::Config::ConfigRegistry.instance
  
  # Only enable on macOS, or if explicitly enabled in config
  default_enabled = Grot::Keyboard::MacUtils.macos?
  enabled = registry.get_value(module_config, :keyboard_mac_adapter, :enabled, default_enabled)
  
  # Get priority from registry or default
  priority = registry.get_value(module_config, :keyboard_mac_adapter, :priority, 70)
  
  # Get command_fix setting with fallbacks
  command_fix = registry.get_value(module_config, :keyboard_mac_adapter, :command_fix, true)
  
  # Get auto_fix_stuck_modifiers setting with fallbacks
  auto_fix = registry.get_value(
    module_config, 
    :keyboard_mac_adapter, 
    :auto_fix_stuck_modifiers, 
    true
  )
  
  # Return the configuration
  {
    enabled: enabled,
    priority: priority,
    command_fix: command_fix,
    auto_fix_stuck_modifiers: auto_fix
  }
end