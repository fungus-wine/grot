require 'test_helper'
require 'grot/keyboard/module_registry'
require 'grot/keyboard/module_base'

class TestModuleRegistry < Minitest::Test
  include Grot::Keyboard
  
  # Simple test module implementation
  class TestModule < ModuleBase
    attr_reader :priority
    
    def initialize(options = {})
      super
    end
  end
  
  def setup
    @registry = ModuleRegistry.new
    
    # Create modules with different priorities
    @high_priority = TestModule.new(priority: 10)
    @medium_priority = TestModule.new(priority: 5)
    @low_priority = TestModule.new(priority: 0)
  end
  
  def test_registration
    # Register modules
    assert @registry.register(:high, @high_priority)
    assert @registry.register(:medium, @medium_priority)
    assert @registry.register(:low, @low_priority)
    
    # Verify count
    assert_equal 3, @registry.count
    
    # Verify retrieval
    assert_equal @high_priority, @registry[:high]
    assert_equal @medium_priority, @registry[:medium]
    assert_equal @low_priority, @registry[:low]
    
    # Verify existence check
    assert @registry.has_module?(:high)
    refute @registry.has_module?(:nonexistent)
  end
  
  def test_duplicate_registration
    @registry.register(:test, @high_priority)
    
    # Should not allow duplicate without override
    assert_raises(RuntimeError) do
      @registry.register(:test, @medium_priority)
    end
    
    # Should allow with override
    assert @registry.register(:test, @medium_priority, true)
    assert_equal @medium_priority, @registry[:test]
  end
  
  def test_unregistration
    @registry.register(:test, @high_priority)
    
    # Unregister and verify
    assert_equal @high_priority, @registry.unregister(:test)
    refute @registry.has_module?(:test)
    assert_nil @registry[:test]
    
    # Unregistering non-existent should return nil
    assert_nil @registry.unregister(:nonexistent)
  end
  
  def test_priority_ordering
    # Register in non-priority order
    @registry.register(:low, @low_priority)
    @registry.register(:high, @high_priority)
    @registry.register(:medium, @medium_priority)
    
    # Get modules in priority order
    modules = @registry.modules_in_order
    
    # Should be sorted by priority (highest first)
    assert_equal @high_priority, modules[0]
    assert_equal @medium_priority, modules[1]
    assert_equal @low_priority, modules[2]
  end
  
  def test_module_enable_disable
    # Add a module to registry
    @registry.register(:test, @high_priority)
    
    # Test module's own enable/disable methods
    assert @high_priority.enabled, "Module should be enabled by default"
    
    @high_priority.disable
    refute @high_priority.enabled, "Module should be disabled after disable call"
    
    @high_priority.enable
    assert @high_priority.enabled, "Module should be enabled after enable call"
    
    # The registry should still have the module regardless of its enabled state
    assert @registry.has_module?(:test)
  end
end
