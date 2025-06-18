require 'test_helper'

class TestBoardStrategyFactory < Minitest::Test
  def test_create_strategy_default
    config = {:fqbn => 'arduino:avr:uno'}
    strategy = Grot::Boards::BoardStrategyFactory.create_strategy(config)
    assert_instance_of Grot::Boards::Strategies::DefaultBoardStrategy, strategy
  end
  
  def test_create_strategy_esp32s3
    config = {:fqbn => 'esp32:esp32:esp32s3'}
    strategy = Grot::Boards::BoardStrategyFactory.create_strategy(config)
    assert_instance_of Grot::Boards::Strategies::ESP32S3BoardStrategy, strategy
  end
  
  def test_create_strategy_giga
    config = {:fqbn => 'arduino:mbed_giga:giga'}
    strategy = Grot::Boards::BoardStrategyFactory.create_strategy(config)
    assert_instance_of Grot::Boards::Strategies::GigaBoardStrategy, strategy
  end
  
  def test_create_strategy_unknown
    config = {:fqbn => 'unknown:board:type'}
    strategy = Grot::Boards::BoardStrategyFactory.create_strategy(config)
    assert_instance_of Grot::Boards::Strategies::DefaultBoardStrategy, strategy
  end
end