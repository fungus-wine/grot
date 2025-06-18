require 'test_helper'
require 'grot/keyboard/event_bus'
require 'grot/keyboard/module_registry'
require 'grot/keyboard/module_base'
require 'grot/keyboard/key_event'

class TestEventBus < Minitest::Test
  include Grot::Keyboard
  
  # Test module implementations
  class TestModule < ModuleBase
    attr_reader :processed, :updated, :shutdown_called, :reset_called
    
    def initialize(options = {})
      super
      @processed = []
      @updated = false
      @shutdown_called = false
      @reset_called = false
    end
    
    def handle_event(event)
      @processed << event
      event  # Return the event (pass through)
    end
    
    def on_update(delta_time)
      @updated = true
    end
    
    def on_shutdown
      @shutdown_called = true
    end
    
    def on_reset
      @reset_called = true
    end
  end
  
  # Test module that consumes events
  class ConsumingModule < ModuleBase
    attr_reader :processed
    
    def initialize(options = {})
      super
      @processed = []
    end
    
    def handle_event(event)
      @processed << event
      nil  # Consume the event
    end
  end
  
  def setup
    # Create registry and modules
    @registry = ModuleRegistry.new
    
    # Create modules with different priorities
    @high_priority = TestModule.new(priority: 10)
    @medium_priority = TestModule.new(priority: 5)
    @low_priority = TestModule.new(priority: 0)
    
    # Create a consuming module
    @consuming = ConsumingModule.new(priority: 8)
    
    # Create the event bus
    @event_bus = EventBus.new(@registry)
    
    # Create a test key event
    @event = KeyEvent.new(KeyEvent::KEY_DOWN, Gosu::KB_A)
  end
  
  def test_process_event
    # Register modules in reverse priority order
    @registry.register(:low, @low_priority)
    @registry.register(:medium, @medium_priority)
    @registry.register(:high, @high_priority)
    
    # Process event through the event bus
    result = @event_bus.process_event(@event)
    
    # All modules should have processed the event
    assert_includes @high_priority.processed, @event
    assert_includes @medium_priority.processed, @event
    assert_includes @low_priority.processed, @event
    
    # Event should pass through
    assert_equal @event, result
  end
  
  def test_event_consumption
    # Register modules including consuming one
    @registry.register(:high, @high_priority)
    @registry.register(:consuming, @consuming)
    @registry.register(:low, @low_priority)
    
    # Process event through the event bus
    result = @event_bus.process_event(@event)
    
    # High priority should process first
    assert_includes @high_priority.processed, @event
    assert_includes @consuming.processed, @event
    
    # Consumer should consume the event
    assert_nil result
    
    # Low priority should not process (event was consumed)
    assert_empty @low_priority.processed
  end
  
  def test_process_event_respects_disabled_modules
    # Register modules
    @registry.register(:high, @high_priority)
    @registry.register(:medium, @medium_priority)
    
    # Disable one module
    @medium_priority.disable
    
    # Process event
    @event_bus.process_event(@event)
    
    # Enabled module should receive event
    assert_includes @high_priority.processed, @event
    
    # Disabled module should not receive event
    assert_empty @medium_priority.processed
  end
  
  def test_update_all
    # Register modules
    @registry.register(:high, @high_priority)
    @registry.register(:medium, @medium_priority)
    @registry.register(:low, @low_priority)
    
    # Disable one module
    @medium_priority.disable
    
    # Update all modules
    @event_bus.update_all(0.016)
    
    # Enabled modules should be updated
    assert @high_priority.updated
    assert @low_priority.updated
    
    # Disabled module should not be updated
    refute @medium_priority.updated
  end
  
  def test_shutdown_all
    # Register modules
    @registry.register(:high, @high_priority)
    @registry.register(:medium, @medium_priority)
    
    # Shutdown all modules
    @event_bus.shutdown_all
    
    # All modules should be shut down, regardless of enabled state
    assert @high_priority.shutdown_called
    assert @medium_priority.shutdown_called
  end
  
  def test_reset_all
    # Register modules
    @registry.register(:high, @high_priority)
    @registry.register(:medium, @medium_priority)
    
    # Reset all modules
    @event_bus.reset_all
    
    # All modules should be reset, regardless of enabled state
    assert @high_priority.reset_called
    assert @medium_priority.reset_called
  end
  
  def test_event_processing_order
    # Create modules with specific processing behavior
    order_module1 = Class.new(ModuleBase) do
      attr_reader :order
      
      def initialize(options = {})
        super
        @order = []
      end
      
      def handle_event(event)
        @order << 1
        event
      end
    end.new(priority: 10)
    
    order_module2 = Class.new(ModuleBase) do
      attr_reader :order
      
      def initialize(options = {})
        super
        @order = []
      end
      
      def handle_event(event)
        @order << 2
        event
      end
    end.new(priority: 5)
    
    # Register modules
    @registry.register(:first, order_module1)
    @registry.register(:second, order_module2)
    
    # Process event
    @event_bus.process_event(@event)
    
    # Verify processing order by priority (highest first)
    assert_equal [1], order_module1.order
    assert_equal [2], order_module2.order
  end
end
