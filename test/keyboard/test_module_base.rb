require 'test_helper'
require 'grot/keyboard/module_base'
require 'grot/keyboard/key_event'

class TestModuleBase < Minitest::Test
  include Grot::Keyboard
  
  # Test implementation of ModuleBase with hooks for testing
  class TestModule < ModuleBase
    attr_reader :updated, :enabled_called, 
                :disabled_called, :shutdown_called, :reset_called
    
    # Add an explicit test helper method
    def clear_updated_flag
      @updated = false
      self # Return self for method chaining
    end
    
    def init(options)
      @test_option = options[:test_option]
      @event_handler = options[:event_handler]
    end
    
    def handle_event(event)
      return @event_handler.call(event) if @event_handler
      event # Default pass-through
    end
    
    def on_update(delta_time)
      @updated = true
      @last_delta = delta_time
    end
    
    def on_enable
      @enabled_called = true
    end
    
    def on_disable
      @disabled_called = true
    end
    
    def on_shutdown
      @shutdown_called = true
    end
    
    def on_reset
      @reset_called = true
    end
    
    # Expose for testing
    def test_option
      @test_option
    end
    
    def last_delta
      @last_delta
    end
  end
  
  def setup
    # Create test module with default options
    @module = TestModule.new
    
    # Create test module with custom options
    @module_with_options = TestModule.new(
      priority: 10,
      enabled: false,
      test_option: "test value"
    )
    
    # Create test module with event handler
    @event_consuming_module = TestModule.new(
      event_handler: ->(event) { nil } # Always consume events
    )
    
    # Create a test keyboard manager mock
    @manager = Object.new
    
    # Create a test event
    @event = KeyEvent.new(KeyEvent::KEY_DOWN, 65)
  end
  
  def test_initialization
    assert_equal 0, @module.priority
    assert @module.enabled
    
    assert_equal 10, @module_with_options.priority
    refute @module_with_options.enabled
    assert_equal "test value", @module_with_options.test_option
  end
  
  def test_manager_association
    @module.set_manager(@manager)
    # In a real test we'd verify the association but ModuleBase doesn't expose it
    # This just ensures the method doesn't raise errors
    assert_nil @module.set_manager(@manager)
  end
  
  def test_enable_disable
    # Create a module for testing
    @module = TestModule.new
    
    # Test enabling an already enabled module (should do nothing)
    refute @module.enabled_called
    @module.enable
    refute @module.enabled_called
    
    # Test disabling
    refute @module.disabled_called
    @module.disable
    assert @module.disabled_called
    
    # Test enabling a disabled module
    @module.enable
    assert @module.enabled_called
  end
    
  def test_event_processing
    # When enabled, should process events
    result = @module.process_event(@event)
    assert_equal @event, result
    
    # When disabled, should not process events
    @module.disable
    result = @module.process_event(@event)
    assert_equal @event, result
    
    # Test a module that consumes events
    result = @event_consuming_module.process_event(@event)
    assert_nil result
  end
  
  def test_update
    # When enabled, should update
    refute @module.updated
    @module.update(0.016)
    assert @module.updated
    assert_equal 0.016, @module.last_delta
    
    # When disabled, should not update
    @module.clear_updated_flag  # Using our explicit helper method
    @module.disable
    @module.update(0.016)
    refute @module.updated
  end
  
  def test_shutdown_and_reset
    refute @module.shutdown_called
    @module.shutdown
    assert @module.shutdown_called
    
    refute @module.reset_called
    @module.reset
    assert @module.reset_called
  end
end