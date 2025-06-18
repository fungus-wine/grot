require 'test_helper'

class TestBoardRegistry < Minitest::Test
  def test_get_board_info
    # Test with a standard Arduino Uno
    uno_info = Grot::Boards::BoardRegistry.get_board_info('arduino:avr:uno')
    assert_kind_of Hash, uno_info
    assert_equal 'Arduino Uno', uno_info[:name]
    assert_equal 'default', uno_info[:strategy]
    
    # Test with an ESP32 board that should use a specific strategy
    esp32_info = Grot::Boards::BoardRegistry.get_board_info('esp32:esp32:esp32s3')
    assert_kind_of Hash, esp32_info
    assert_equal 'esp32_s3', esp32_info[:strategy]
    
    # Test with a GIGA board that should use a specific strategy
    giga_info = Grot::Boards::BoardRegistry.get_board_info('arduino:mbed_giga:giga')
    assert_kind_of Hash, giga_info
    assert_equal 'giga', giga_info[:strategy]
  end
  
  def test_get_board_info_unknown_board
    assert_nil Grot::Boards::BoardRegistry.get_board_info('unknown:board:type')
  end
  
  def test_supported
    assert Grot::Boards::BoardRegistry.supported?('arduino:avr:uno')
    assert Grot::Boards::BoardRegistry.supported?('esp32:esp32:esp32s3')
    refute Grot::Boards::BoardRegistry.supported?('unknown:board:type')
  end
  
  def test_strategy_for
    assert_equal 'default', Grot::Boards::BoardRegistry.strategy_for('arduino:avr:uno')
    assert_equal 'esp32_s3', Grot::Boards::BoardRegistry.strategy_for('esp32:esp32:esp32s3')
    assert_equal 'giga', Grot::Boards::BoardRegistry.strategy_for('arduino:mbed_giga:giga')
    assert_equal 'default', Grot::Boards::BoardRegistry.strategy_for('unknown:board:type')
  end
  
  def test_config_options_for
    # Test ESP32 board options
    options = Grot::Boards::BoardRegistry.config_options_for('esp32:esp32:esp32s3')
    assert_includes options, :core_config
    assert_equal 'dual', options[:core_config]
    assert_includes options, :frequency
    assert_equal '240', options[:frequency]
    
    # Test GIGA board options
    options = Grot::Boards::BoardRegistry.config_options_for('arduino:mbed_giga:giga')
    assert_includes options, :target_core
    assert_equal 'CM7', options[:target_core]
    assert_includes options, :flash_split
    assert_equal 1.0, options[:flash_split]
    
    # Test standard Arduino board (no special options)
    options = Grot::Boards::BoardRegistry.config_options_for('arduino:avr:uno')
    assert_equal({}, options)
  end
end