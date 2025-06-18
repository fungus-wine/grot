require 'test_helper'
require 'grot/keyboard/keyboard_manager'

class TestKeyboardManager < Minitest::Test
  include Grot::Keyboard
  
  # Test module implementation
  class TestModule < ModuleBase
    attr_reader :events, :manager, :shutdown_called, :reset_called
    
    def initialize(options = {})
      super
      @events = []
      @shutdown_called = false
      @reset_called = false
    end
    
    def set_manager(manager)
      @manager = manager
      super
    end
    
    def handle_event(event)
      @events << event
      event
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
    attr_reader :events
    
    def initialize(options = {})
      super
      @events = []
    end
    
    def handle_event(event)
      @events << event
      nil # Consume the event
    end
  end
  
  def setup
    # Create a manager with auto_load disabled
    @manager = KeyboardManager.new(auto_load_modules: false)
    
    # Create test modules
    @test_module = TestModule.new
    @consuming_module = ConsumingModule.new
  end
  
  def test_initialization
    assert_instance_of KeyboardManager, @manager
    
    # Test that we can initialize with auto-loading
    auto_manager = KeyboardManager.new(auto_load_modules: true)
    
    # Verify the registry and key_state are initialized
    assert_instance_of ModuleRegistry, auto_manager.instance_variable_get(:@registry)
    assert auto_manager.key_state, "Key state module should be available"
  end
  
  def test_add_module
    # Add module and verify
    result = @manager.add_module(:test, @test_module)
    
    # Should return the module
    assert_equal @test_module, result
    
    # Module should be registered - we'll use get_module to verify
    assert_equal @test_module, @manager.get_module(:test)
    
    # Manager should be set
    assert_equal @manager, @test_module.manager
  end
  
  def test_remove_module
    @manager.add_module(:test, @test_module)
    
    # Remove module and verify
    result = @manager.remove_module(:test)
    
    # Should return the module
    assert_equal @test_module, result
    
    # Module should be unregistered
    assert_nil @manager.get_module(:test)
  end
  
  def test_button_events
    @manager.add_module(:test, @test_module)
    
    # Send button down event
    @manager.handle_button_down(Gosu::KB_A)
    
    # Verify module received the event
    assert_equal 1, @test_module.events.size
    assert @test_module.events[0].key_down?
    assert_equal Gosu::KB_A, @test_module.events[0].key_code
    
    # Send button up event
    @manager.handle_button_up(Gosu::KB_A)
    
    # Verify module received the event
    assert_equal 2, @test_module.events.size
    assert @test_module.events[1].key_up?
    assert_equal Gosu::KB_A, @test_module.events[1].key_code
  end
  
  def test_button_events_with_modifiers
    @manager.add_module(:test, @test_module)
    
    # Send button down event with modifiers
    @manager.handle_button_down(Gosu::KB_A, { shift: true, control: true })
    
    # Verify module received the event with modifiers
    assert_equal 1, @test_module.events.size
    assert @test_module.events[0].modifier?(:shift)
    assert @test_module.events[0].modifier?(:control)
  end
  
  def test_event_consumption
    @manager.add_module(:consuming, @consuming_module)
    @manager.add_module(:test, @test_module)
    
    # Send button down event
    @manager.handle_button_down(Gosu::KB_A)
    
    # Consuming module should receive the event
    assert_equal 1, @consuming_module.events.size
    
    # Test module should not receive the event (consumed)
    assert_equal 0, @test_module.events.size
  end
  
  def test_update
    @manager.add_module(:test, @test_module)
    
    # Basic update test (just ensure it doesn't error)
    assert_silent { @manager.update(0.016) }
    
    # Update with no delta (should calculate itself)
    assert_silent { @manager.update }
  end
  
  def test_shutdown_and_reset
    @manager.add_module(:test, @test_module)
    
    # Check that these methods start as false
    refute @test_module.shutdown_called
    refute @test_module.reset_called
    
    # Call the manager methods
    @manager.shutdown
    @manager.reset
    
    # Verify the test module received the calls
    assert @test_module.shutdown_called
    assert @test_module.reset_called
  end
  
  def test_key_state_methods
    # Ensure key_state is available
    key_state = @manager.key_state
    
    # Test the key state query methods
    assert_respond_to @manager, :key_pressed?
    assert_respond_to @manager, :key_down?
    assert_respond_to @manager, :key_released?
    assert_respond_to @manager, :key_up?
    assert_respond_to @manager, :key_press_duration
    
    # If key_state is nil (which might happen with auto_load disabled),
    # the query methods should still work but return default values
    if key_state.nil?
      refute @manager.key_pressed?(Gosu::KB_A)
      refute @manager.key_down?(Gosu::KB_A)
      refute @manager.key_released?(Gosu::KB_A)
      assert @manager.key_up?(Gosu::KB_A)
      assert_equal 0.0, @manager.key_press_duration(Gosu::KB_A)
    end
  end
end
