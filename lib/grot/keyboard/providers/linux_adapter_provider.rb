require 'grot/keyboard/module_provider'
require 'grot/keyboard/modules/linux_adapter_module'
require 'grot/keyboard/key_constants'
require 'grot/config/config_registry'

Grot::Keyboard::ModuleProvider.register(
  :linux_adapter,
  Grot::Keyboard::Modules::LinuxAdapter,
  71
) do |config|
  # Get module-specific config
  module_config = config[:module_config] || {}
  
  # Get registry instance
  registry = Grot::Config::ConfigRegistry.instance
  
  # Only enable on Linux, or if explicitly enabled in config
  default_enabled = Grot::Keyboard::KeyConstants.platform == :linux
  enabled = registry.get_value(module_config, :keyboard_linux_adapter, :enabled, default_enabled)
  
  # Get priority with fallback
  priority = registry.get_value(module_config, :keyboard_linux_adapter, :priority, 71)
  
  # Get window manager conflict setting with fallback
  fix_wm_conflicts = registry.get_value(
    module_config, 
    :keyboard_linux_adapter, 
    :fix_window_manager_conflicts, 
    true
  )
  
  # Return the configuration
  {
    enabled: enabled,
    priority: priority,
    fix_window_manager_conflicts: fix_wm_conflicts
  }
end