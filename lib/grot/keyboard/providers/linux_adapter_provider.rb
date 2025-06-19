require 'grot/keyboard/module_provider'
require 'grot/keyboard/modules/linux_adapter_module'
require 'grot/keyboard/key_constants'

Grot::Keyboard::ModuleProvider.register(
  :linux_adapter,
  Grot::Keyboard::Modules::LinuxAdapter,
  71
) do |config|
  # Get module-specific config with defaults
  keyboard_config = config[:keyboard_linux_adapter] || {}
  
  # Only enable on Linux by default, or if explicitly enabled in config
  default_enabled = Grot::Keyboard::KeyConstants.platform == :linux
  enabled = keyboard_config.key?(:enabled) ? keyboard_config[:enabled] : default_enabled
  
  # Return the configuration
  {
    enabled: enabled,
    priority: keyboard_config[:priority] || 71,
    fix_window_manager_conflicts: keyboard_config[:fix_window_manager_conflicts] != false  # Default to true
  }
end