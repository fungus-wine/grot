require 'test_helper'
require 'grot/keyboard/key_event'

class TestKeyEvent < Minitest::Test
  include Grot::Keyboard
  
  def setup
    # Create test events for different types
    @key_down_event = KeyEvent.new(KeyEvent::KEY_DOWN, 65) # 'A' key
    @key_up_event = KeyEvent.new(KeyEvent::KEY_UP, 65)
    @key_held_event = KeyEvent.new(KeyEvent::KEY_HELD, 65)
    
    # Create event with modifiers
    @modifier_event = KeyEvent.new(
      KeyEvent::KEY_DOWN, 
      65, 
      { shift: true, control: false, alt: true }
    )
    
    # Create event with custom timestamp
    @custom_time = Time.now.to_f - 5.0 # 5 seconds ago
    @timestamped_event = KeyEvent.new(KeyEvent::KEY_DOWN, 65, {}, @custom_time)
  end
  
  def test_initialization
    assert_equal KeyEvent::KEY_DOWN, @key_down_event.type
    assert_equal 65, @key_down_event.key_code
    assert_kind_of Hash, @key_down_event.modifiers
    assert_kind_of Float, @key_down_event.timestamp
  end
  
  def test_event_type_methods
    assert @key_down_event.key_down?
    refute @key_down_event.key_up?
    refute @key_down_event.key_held?
    
    assert @key_up_event.key_up?
    refute @key_up_event.key_down?
    
    assert @key_held_event.key_held?
    refute @key_held_event.key_down?
  end
  
  def test_modifier_detection
    assert @modifier_event.modifier?(:shift)
    refute @modifier_event.modifier?(:control)
    assert @modifier_event.modifier?(:alt)
    refute @modifier_event.modifier?(:meta)
  end
  
  def test_custom_timestamp
    assert_equal @custom_time, @timestamped_event.timestamp
  end
  
  def test_event_age
    # Create a reference time 1 second after the event
    reference_time = @timestamped_event.timestamp + 1.0
    
    # Age should be 1 second
    assert_in_delta 1.0, @timestamped_event.age(reference_time), 0.001
  end
  
  def test_to_string
    str = @key_down_event.to_s
    assert_kind_of String, str
    assert_includes str, "KeyEvent"
    assert_includes str, "key_down"
    assert_includes str, "65"
  end
end
