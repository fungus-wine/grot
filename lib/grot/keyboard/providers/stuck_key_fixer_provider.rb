require 'grot/keyboard/module_provider'
require 'grot/keyboard/modules/stuck_key_fixer_module'
require 'grot/keyboard/key_constants'
require 'grot/config/config_registry'

Grot::Keyboard::ModuleProvider.register(
  :stuck_key_fixer,
  Grot::Keyboard::Modules::StuckKeyFixer,
  50
) do |config|
  # Get module-specific config
  module_config = config[:module_config] || {}
  
  # Get registry instance
  registry = Grot::Config::ConfigRegistry.instance
  
  # Get values with registry fallbacks
  enabled = registry.get_value(module_config, :keyboard_stuck_key_fixer, :enabled, true)
  priority = registry.get_value(module_config, :keyboard_stuck_key_fixer, :priority, 50)
  
  # Get auto_release_delay with fallback
  timeout = registry.get_value(
    module_config, 
    :keyboard_stuck_key_fixer, 
    :auto_release_delay, 
    1.0
  )
  
  # Get problem keys from config/registry or use platform-specific defaults
  problem_keys = if module_config.key?(:problem_keys)
                   module_config[:problem_keys]
                 elsif registry[:keyboard_stuck_key_fixer] && 
                       registry[:keyboard_stuck_key_fixer][:problem_keys]
                   registry[:keyboard_stuck_key_fixer][:problem_keys]
                 else
                   # Platform-specific defaults
                   if Grot::Keyboard::KeyConstants.platform == :macos
                     [Gosu::KB_LEFT_ALT, Gosu::KB_RIGHT_ALT,
                      Gosu::KB_LEFT_META, Gosu::KB_RIGHT_META, Gosu::KB_TAB]
                   else
                     [Gosu::KB_LEFT_ALT, Gosu::KB_RIGHT_ALT, Gosu::KB_TAB]
                   end
                 end
  
  # Return the configuration
  {
    enabled: enabled,
    priority: priority,
    timeout: timeout,
    problem_keys: problem_keys
  }
end