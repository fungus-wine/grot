require 'test_helper'

class TestBoardRegistry < Minitest::Test
  def test_get_board_info
    # Test with a standard Arduino Uno
    uno_info = Grot::Boards::BoardRegistry.get_board_info('arduino:avr:uno')
    assert_kind_of Hash, uno_info
    assert_equal 'Arduino Uno', uno_info[:name]

    # Test with an ESP32 board
    esp32_info = Grot::Boards::BoardRegistry.get_board_info('esp32:esp32:esp32s3')
    assert_kind_of Hash, esp32_info
    assert_equal 'ESP32S3 Dev Module', esp32_info[:name]

    # Test with a GIGA board
    giga_info = Grot::Boards::BoardRegistry.get_board_info('arduino:mbed_giga:giga')
    assert_kind_of Hash, giga_info
    assert_equal 'Arduino Giga R1', giga_info[:name]
  end

  def test_get_board_info_unknown_board
    assert_nil Grot::Boards::BoardRegistry.get_board_info('unknown:board:type')
  end

  def test_supported
    assert Grot::Boards::BoardRegistry.supported?('arduino:avr:uno')
    assert Grot::Boards::BoardRegistry.supported?('esp32:esp32:esp32s3')
    refute Grot::Boards::BoardRegistry.supported?('unknown:board:type')
  end

  def test_teensy_boards_registered
    teensy41 = Grot::Boards::BoardRegistry.get_board_info('teensy:avr:teensy41')
    assert_kind_of Hash, teensy41
    assert_equal 'Teensy 4.1', teensy41[:name]
    assert_equal :teensy_loader_cli, teensy41[:loader]
    assert_equal 'TEENSY41', teensy41[:mcu]

    assert Grot::Boards::BoardRegistry.supported?('teensy:avr:teensy40')
    assert Grot::Boards::BoardRegistry.supported?('teensy:avr:teensyMM')
    assert Grot::Boards::BoardRegistry.supported?('teensy:avr:teensy36')
    assert Grot::Boards::BoardRegistry.supported?('teensy:avr:teensy35')
    assert Grot::Boards::BoardRegistry.supported?('teensy:avr:teensy31')
    assert Grot::Boards::BoardRegistry.supported?('teensy:avr:teensyLC')
  end

  def test_loader_for_teensy
    assert_equal :teensy_loader_cli, Grot::Boards::BoardRegistry.loader_for('teensy:avr:teensy41')
    assert_equal :teensy_loader_cli, Grot::Boards::BoardRegistry.loader_for('teensy:avr:teensyLC')
  end

  def test_loader_for_non_teensy
    assert_nil Grot::Boards::BoardRegistry.loader_for('arduino:avr:uno')
    assert_nil Grot::Boards::BoardRegistry.loader_for('unknown:board:type')
  end

  def test_fqbn_options_for
    # GIGA board has fqbn_options
    options = Grot::Boards::BoardRegistry.fqbn_options_for('arduino:mbed_giga:giga')
    assert_kind_of Hash, options
    assert_includes options, :giga_options
    assert_equal({ target_core: 'target_core', split: 'split' }, options[:giga_options])

    # Standard board has no fqbn_options
    options = Grot::Boards::BoardRegistry.fqbn_options_for('arduino:avr:uno')
    assert_equal({}, options)

    # Unknown board has no fqbn_options
    options = Grot::Boards::BoardRegistry.fqbn_options_for('unknown:board:type')
    assert_equal({}, options)
  end
end
