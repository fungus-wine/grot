require 'test_helper'
require 'grot/keyboard/module_provider'

class TestModuleProvider < Minitest::Test
  def setup
    # Save original providers to restore later
    @original_providers = Grot::Keyboard::ModuleProvider.all.dup
    
    # Clear providers for testing
    Grot::Keyboard::ModuleProvider.instance_variable_set(:@providers, {})
  end
  
  def teardown
    # Restore original providers
    Grot::Keyboard::ModuleProvider.instance_variable_set(:@providers, @original_providers)
  end
  
  def test_register_and_retrieve_provider
    # Test basic registration
    test_class = Class.new
    Grot::Keyboard::ModuleProvider.register(:test, test_class, 50) do |config|
      { configured: true }
    end
    
    # Verify it was registered correctly
    providers = Grot::Keyboard::ModuleProvider.all
    assert_includes providers.keys, :test
    assert_equal test_class, providers[:test][:class]
    assert_equal 50, providers[:test][:priority]
    
    # Test the config block works
    result = providers[:test][:config_block].call({})
    assert_equal({ configured: true }, result)
  end
end