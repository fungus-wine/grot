require 'test_helper'

class TestCommandHandlers < Minitest::Test
  # Helper method to capture stdout in tests
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
  
  def test_version_command
    app = mock('app')
    
    output = capture_stdout do
      result = Grot::Commands::Handlers.version_command(app)
      assert_equal 0, result
    end
    
    assert_includes output, "Grot version #{Grot::VERSION}"
  end
  
  def test_init_command_new_file
    config_file = 'test_config.toml'
    app = mock('app')
    app.expects(:options).returns({config_file: config_file})
    
    Grot::Config::ConfigManager.expects(:create_default_config).with(config_file)
    
    File.expects(:exist?).with(config_file).returns(false)
    
    output = capture_stdout do
      result = Grot::Commands::Handlers.init_command(app)
      assert_equal 0, result
    end
    
    assert_includes output, "Creating new configuration file"
  end
  
  def test_init_command_existing_file_overwrite
    config_file = 'test_config.toml'
    app = mock('app')
    app.expects(:options).returns({config_file: config_file})
    
    Grot::Config::ConfigManager.expects(:create_default_config).with(config_file)
    
    File.expects(:exist?).with(config_file).returns(true)
    
  
    Grot::Commands::Handlers.stubs(:gets).returns("y\n")
    
    output = capture_stdout do
      result = Grot::Commands::Handlers.init_command(app)
      assert_equal 0, result
    end
    
    assert_includes output, "already exists"
  end
  
  def test_ports_command
    port_handler = mock('port_handler')
    app = mock('app')
    app.expects(:port_handler).returns(port_handler)
    
    port_handler.expects(:list_available_ports)
    
    output = capture_stdout do
      result = Grot::Commands::Handlers.ports_command(app)
      assert_equal 0, result
    end
    
    assert_includes output, "Available Ports"
  end
  
  def test_boards_command
    app = mock('app')
    
    output = capture_stdout do
      result = Grot::Commands::Handlers.boards_command(app)
      assert_equal 0, result
    end
    
    assert_includes output, "Supported boards"
  end
  
  def test_dump_command_with_config
    config_file = 'test_config.toml'
    port_handler = mock('port_handler')
    app = mock('app')
    app.expects(:options).returns({config_file: config_file})
    app.expects(:port_handler).returns(port_handler)
    
    config = {:cli_path => 'test.ino'}
    
    File.expects(:exist?).with(config_file).returns(true)
    Grot::Config::ConfigManager.expects(:load_config).with(config_file).returns(config)
    port_handler.expects(:list_available_ports)
    
    output = capture_stdout do
      result = Grot::Commands::Handlers.dump_command(app)
      assert_equal 0, result
    end
    
    assert_includes output, "Configuration"
    assert_includes output, "Available Ports"
  end
  
  def test_dump_command_without_config
    config_file = 'test_config.toml'
    port_handler = mock('port_handler')
    app = mock('app')
    app.expects(:options).returns({config_file: config_file})
    app.expects(:port_handler).returns(port_handler)
    
    File.expects(:exist?).with(config_file).returns(false)
    port_handler.expects(:list_available_ports)
    
    output = capture_stdout do
      result = Grot::Commands::Handlers.dump_command(app)
      assert_equal 0, result
    end
    
    assert_includes output, "Config file not found"
    assert_includes output, "Available Ports"
  end
  
  def test_clean_command
    app = mock('app')
    config = {basic: {cli_path: "arduino-cli"}} 
    
    Open3.expects(:capture3).with('arduino-cli cache clean')
      .returns(['Output', '', mock(success?: true, exitstatus: 0)])
    
    app.expects(:instance_variable_set)
    
    output = capture_stdout do
      result = Grot::Commands::Handlers.clean_command(app, config)
      assert_equal 0, result
    end
    
    assert_includes output, "Output"
  end
end