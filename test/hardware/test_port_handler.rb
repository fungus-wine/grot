require 'test_helper'

class TestPortHandler < Minitest::Test
  def setup
    @port_handler = Grot::Ports::PortHandler.new
  end
  
  def test_validate_port
    File.expects(:exist?).with('/dev/ttyUSB0').returns(true)
    
    assert_equal '/dev/ttyUSB0', @port_handler.validate_port('/dev/ttyUSB0')
  end
  
  def test_validate_nonexistent_port
    File.expects(:exist?).with('/dev/nonexistent').returns(false)
    
    assert_raises(Grot::Errors::SerialPortError) do
      @port_handler.validate_port('/dev/nonexistent')
    end
  end
  
  def test_validate_nil_port
    assert_nil @port_handler.validate_port(nil)
  end
  
def test_list_available_ports_with_ports
  @port_handler.expects(:find_available_ports).returns(['/dev/ttyUSB0', '/dev/ttyACM0'])
  
  # Exact matching with the description text included
  @port_handler.expects(:puts).with("/dev/ttyUSB0 (Possibly Arduino/USB device)")
  @port_handler.expects(:puts).with("/dev/ttyACM0 (Possibly Arduino/USB device)")
  
  @port_handler.list_available_ports
end
  
  def test_list_available_ports_without_ports
    @port_handler.expects(:find_available_ports).returns([])
    @port_handler.expects(:puts).with(includes("No serial ports found"))
    
    @port_handler.list_available_ports
  end
  
  def test_detect_best_port_arduino_like
    @port_handler.expects(:find_available_ports).returns([
      '/dev/tty.random',
      '/dev/tty.usbmodemArduino'
    ])
    
    assert_equal '/dev/tty.usbmodemArduino', @port_handler.detect_best_port
  end
  
  def test_detect_best_port_fallback
    @port_handler.expects(:find_available_ports).returns([
      '/dev/tty.random1',
      '/dev/tty.random2'
    ])
    
    assert_equal '/dev/tty.random1', @port_handler.detect_best_port
  end
  
  def test_detect_best_port_no_ports
    @port_handler.expects(:find_available_ports).returns([])
    assert_nil @port_handler.detect_best_port
  end
end