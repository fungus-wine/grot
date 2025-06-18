require 'test_helper'
require 'grot/keyboard/keyboard_manager'
require 'grot/keyboard/module_provider'

class TestManagerWithProviders < Minitest::Test
  def setup
    # Save original providers to restore later
    @original_providers = Grot::Keyboard::ModuleProvider.all.dup
    
    # Clear providers for testing
    Grot::Keyboard::ModuleProvider.instance_variable_set(:@providers, {})
    
    # Register test modules
    @test_module_class = Class.new(Grot::Keyboard::ModuleBase)
    @test_module_class2 = Class.new(Grot::Keyboard::ModuleBase)
  end
  
  def teardown
    # Restore original providers
    Grot::Keyboard::ModuleProvider.instance_variable_set(:@providers, @original_providers)
  end
  
  def test_manager_loads_modules_from_providers
    # Register test providers
    Grot::Keyboard::ModuleProvider.register(:test_module, @test_module_class, 100) do |config|
      { test_option: "value1" }
    end
    
    Grot::Keyboard::ModuleProvider.register(:test_module2, @test_module_class2, 50) do |config|
      { test_option: "value2" }
    end
    
    # Mock the directory loading
    Dir.stubs(:[]).returns([])
    
    # Create a new manager that will use our test providers
    manager = Grot::Keyboard::KeyboardManager.new(auto_load_modules: true)
    
    # Check that both modules were loaded
    assert_instance_of @test_module_class, manager.get_module(:test_module)
    assert_instance_of @test_module_class2, manager.get_module(:test_module2)
    
    # Check that they were loaded in priority order
    modules = manager.registry.modules_in_order
    assert_equal 2, modules.length
    assert_instance_of @test_module_class, modules[0]  # Higher priority first
    assert_instance_of @test_module_class2, modules[1] # Lower priority second
  end
end