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

  # validate_command tests

  def test_validate_command_valid_config
    app = mock('app')
    app.expects(:options).returns({ config_file: '.grotconfig' })

    fqbn = 'arduino:avr:uno'
    config = {
      basic: { cli_path: 'arduino-cli', fqbn: fqbn, port: '/dev/ttyACM0' },
      interface: { baud_rate: 9600 }
    }

    output = capture_stdout do
      result = Grot::Commands::Handlers.validate_command(app, config)
      assert_equal 0, result
    end

    assert_includes output, "Configuration is valid!"
  end

  def test_validate_command_unknown_fqbn_returns_error
    app = mock('app')
    app.expects(:options).returns({ config_file: '.grotconfig' })

    config = {
      basic: { cli_path: 'arduino-cli', fqbn: 'bogus:bogus:bogus' },
      interface: { baud_rate: 9600 }
    }

    output = capture_stdout do
      result = Grot::Commands::Handlers.validate_command(app, config)
      assert_equal 1, result
    end

    assert_includes output, "bogus:bogus:bogus"
  end

  def test_validate_command_invalid_baud_rate_returns_error
    app = mock('app')
    app.expects(:options).returns({ config_file: '.grotconfig' })

    config = {
      basic: { cli_path: 'arduino-cli' },
      interface: { baud_rate: -1 }
    }

    output = capture_stdout do
      result = Grot::Commands::Handlers.validate_command(app, config)
      assert_equal 1, result
    end

    assert_includes output, "baud_rate"
  end

  def test_validate_command_unknown_section_warns
    app = mock('app')
    app.expects(:options).returns({ config_file: '.grotconfig' })

    fqbn = 'arduino:avr:uno'
    config = {
      basic: { cli_path: 'arduino-cli', fqbn: fqbn, port: '/dev/ttyACM0' },
      interface: { baud_rate: 9600 },
      unknown_section: { foo: 'bar' }
    }

    output = capture_stdout do
      result = Grot::Commands::Handlers.validate_command(app, config)
      assert_equal 0, result
    end

    assert_includes output, "unknown_section"
  end

  def test_validate_command_reports_all_errors
    app = mock('app')
    app.expects(:options).returns({ config_file: '.grotconfig' })

    config = {
      basic: { cli_path: 'arduino-cli' },
      interface: { baud_rate: -1 }
    }

    output = capture_stdout do
      result = Grot::Commands::Handlers.validate_command(app, config)
      assert_equal 1, result
    end

    assert_includes output, "baud_rate"
    assert_includes output, "basic.fqbn is not set"
  end

  def test_validate_command_missing_fqbn_returns_error
    app = mock('app')
    app.expects(:options).returns({ config_file: '.grotconfig' })

    config = {
      basic: { cli_path: 'arduino-cli', port: '/dev/ttyACM0' },
      interface: { baud_rate: 9600 }
    }

    output = capture_stdout do
      result = Grot::Commands::Handlers.validate_command(app, config)
      assert_equal 1, result
    end

    assert_includes output, "basic.fqbn is not set"
  end

  def test_validate_command_missing_port_returns_warning
    app = mock('app')
    app.expects(:options).returns({ config_file: '.grotconfig' })

    fqbn = 'arduino:avr:uno'
    config = {
      basic: { cli_path: 'arduino-cli', fqbn: fqbn },
      interface: { baud_rate: 9600 }
    }

    output = capture_stdout do
      result = Grot::Commands::Handlers.validate_command(app, config)
      assert_equal 0, result
    end

    assert_includes output, "basic.port is not set"
  end
end
