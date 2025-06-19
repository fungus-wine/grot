require 'grot/keyboard/module_provider'
require 'grot/keyboard/modules/stuck_key_fixer_module'
require 'grot/keyboard/key_constants'

Grot::Keyboard::ModuleProvider.register(
  :stuck_key_fixer,
  Grot::Keyboard::Modules::StuckKeyFixer,
  50
) do |config|
  # Get module-specific config with defaults
  keyboard_config = config[:keyboard_stuck_key_fixer] || {}
  
  # Get values with defaults
  enabled = keyboard_config[:enabled] != false  # Default to true
  priority = keyboard_config[:priority] || 50
  timeout = keyboard_config[:auto_release_delay] || 1.0
  
  # Get problem keys or use platform-specific defaults
  problem_keys = keyboard_config[:problem_keys] || begin
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