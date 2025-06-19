require 'grot/keyboard/module_provider'
require 'grot/keyboard/modules/buffer_module'

Grot::Keyboard::ModuleProvider.register(
  :buffer,
  Grot::Keyboard::Modules::Buffer,
  80
) do |config|
  # Get module-specific config with defaults
  keyboard_config = config[:keyboard_buffer] || {}
  
  # Return configuration hash
  {
    enabled: keyboard_config[:enabled] != false,  # Default to true
    priority: keyboard_config[:priority] || 80,
    delay: keyboard_config[:buffer_time] || 0.01  # Note: Module uses 'delay' internally
  }
end