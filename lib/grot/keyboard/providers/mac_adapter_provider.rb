require 'grot/keyboard/module_provider'
require 'grot/keyboard/modules/mac_adapter_module'
require 'grot/keyboard/key_constants'

Grot::Keyboard::ModuleProvider.register(
  :mac_adapter,
  Grot::Keyboard::Modules::MacAdapter,
  70
) do |config|
  # Get module-specific config with defaults
  keyboard_config = config[:keyboard_mac_adapter] || {}
  
  # Only enable on macOS by default, or if explicitly enabled in config
  default_enabled = Grot::Keyboard::KeyConstants.platform == :macos
  enabled = keyboard_config.key?(:enabled) ? keyboard_config[:enabled] : default_enabled
  
  # Return the configuration
  {
    enabled: enabled,
    priority: keyboard_config[:priority] || 70,
    command_fix: keyboard_config[:command_fix] != false,  # Default to true
    auto_fix_stuck_modifiers: keyboard_config[:auto_fix_stuck_modifiers] != false  # Default to true
  }
end