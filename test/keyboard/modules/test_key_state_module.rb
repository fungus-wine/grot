require 'test_helper'
require 'grot/keyboard/modules/key_state_module'
require 'grot/keyboard/key_event'

class TestKeyState < Minitest::Test
  include Grot::Keyboard
  
  def setup
    # Create a KeyState module instance
    @key_state = Modules::KeyState.new
    
    # Create test key events for a space key press/release
    @key_down_event = KeyEvent.new(
      KeyEvent::KEY_DOWN, 
      Gosu::KB_SPACE,
      {},  # Empty modifiers
      10.0 # Fixed timestamp for testing
    )
    
    @key_up_event = KeyEvent.new(
      KeyEvent::KEY_UP,
      Gosu::KB_SPACE,
      {},
      11.0
    )
  end

  def test_basic_key_flow
    # Initial state: key should be up
    assert @key_state.up?(Gosu::KB_SPACE), "Key should start as up"
    
    # Process key down event
    @key_state.handle_event(@key_down_event)
    assert @key_state.pressed?(Gosu::KB_SPACE), "Key should be pressed after down event"
    
    # After an update, the pressed key transitions to down state
    @key_state.on_update(0.016)
    assert @key_state.down?(Gosu::KB_SPACE), "Key should be down after update"
    
    # Process key up event
    @key_state.handle_event(@key_up_event)
    assert @key_state.released?(Gosu::KB_SPACE), "Key should be released after up event"
    
    # After another update, the released key should be cleared
    @key_state.on_update(0.016)
    assert @key_state.up?(Gosu::KB_SPACE), "Key should be up after released is cleared"
  end

  def test_press_duration
    # Mock Time.now to return predictable values for testing duration
    Time.stubs(:now).returns(Time.at(10.0))
    
    # Initially duration should be 0
    assert_equal 0.0, @key_state.press_duration(Gosu::KB_SPACE), "Press duration should start at 0"
    
    # Process key down event
    @key_state.handle_event(@key_down_event)
    
    # Update once to transition to "down" state
    @key_state.on_update(0.016)
    
    # Move time forward
    Time.stubs(:now).returns(Time.at(10.5))
    
    # Check duration - should be ~0.5 seconds
    duration = @key_state.press_duration(Gosu::KB_SPACE)
    assert_in_delta 0.5, duration, 0.01, "Press duration should be about 0.5 after time passes"
    
    # Release the key
    @key_state.handle_event(@key_up_event)
    @key_state.on_update(0.016)
    
    # Duration should be 0 after key is up
    assert_equal 0.0, @key_state.press_duration(Gosu::KB_SPACE), "Press duration should be 0 when key is up"
  end

  def test_keys_in_state
    # Press several keys
    keys = [Gosu::KB_A, Gosu::KB_B, Gosu::KB_C]
    
    keys.each do |key|
      event = KeyEvent.new(KeyEvent::KEY_DOWN, key)
      @key_state.handle_event(event)
    end
    
    # All keys should be in pressed state
    pressed_keys = @key_state.keys_in_state(:pressed)
    assert_equal keys.size, pressed_keys.size, "All keys should be in pressed state"
    keys.each { |key| assert_includes pressed_keys, key }
    
    # Update to transition to down state
    @key_state.on_update(0.016)
    
    # Now all keys should be in down state
    down_keys = @key_state.keys_in_state(:down)
    assert_equal keys.size, down_keys.size, "All keys should be in down state after update"
    keys.each { |key| assert_includes down_keys, key }
    
    # Release one key
    release_event = KeyEvent.new(KeyEvent::KEY_UP, keys.first)
    @key_state.handle_event(release_event)
    
    # That key should be in released state
    released_keys = @key_state.keys_in_state(:released)
    assert_equal 1, released_keys.size, "One key should be in released state"
    assert_includes released_keys, keys.first
  end

  def test_reset
    # Press a key
    @key_state.handle_event(@key_down_event)
    @key_state.on_update(0.016)
    
    # Verify key is down
    assert @key_state.down?(Gosu::KB_SPACE), "Key should be down before reset"
    
    # Reset and verify all keys are cleared
    @key_state.on_reset
    assert @key_state.up?(Gosu::KB_SPACE), "Key should be up after reset"
    assert_empty @key_state.active_keys, "No keys should be active after reset"
  end
  
  def test_active_keys
    # Initially no active keys
    assert_empty @key_state.active_keys, "Should start with no active keys"
    
    # Press keys
    keys = [Gosu::KB_A, Gosu::KB_B, Gosu::KB_C]
    keys.each do |key|
      event = KeyEvent.new(KeyEvent::KEY_DOWN, key)
      @key_state.handle_event(event)
    end
    
    # Check active keys
    active = @key_state.active_keys
    assert_equal keys.size, active.size, "All pressed keys should be active"
    keys.each { |key| assert_includes active, key }
  end
end
