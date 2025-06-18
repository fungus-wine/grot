require 'grot/keyboard/module_provider'
require 'grot/keyboard/modules/buffer_module'
require 'grot/config/config_registry'

Grot::Keyboard::ModuleProvider.register(
  :buffer,
  Grot::Keyboard::Modules::Buffer,
  80
) do |config|
  # Get module-specific config
  module_config = config[:module_config] || {}
  
  # Get registry instance
  registry = Grot::Config::ConfigRegistry.instance
  
  # Get values with registry fallbacks
  enabled = registry.get_value(module_config, :keyboard_buffer, :enabled, true)
  priority = registry.get_value(module_config, :keyboard_buffer, :priority, 80)
  buffer_time = registry.get_value(module_config, :keyboard_buffer, :buffer_time, 0.01)
  
  # Return configuration hash
  {
    enabled: enabled,
    priority: priority,
    delay: buffer_time  # Note: Module uses 'delay' internally, registry uses :buffer_time
  }
end