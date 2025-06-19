require 'test_helper'
require 'tempfile'

class TestConfigManager < Minitest::Test
  def setup
    @config_manager = Grot::Config::ConfigManager.new
    @temp_file = Tempfile.new(['grot_test_config', '.toml'])
  end
  
  def teardown
    @temp_file.close
    @temp_file.unlink
  end
  

  def test_load_config
    # Create a valid config file with the proper structure
    File.write(@temp_file.path, <<~TOML)
      [basic]
      sketch_path = "test.ino"
      cli_path = "arduino-cli"
      port = "/dev/ttyUSB0"
      fqbn = "arduino:avr:uno"
      
      [esp32_options]
      core_config = "dual"
      frequency = 240
    TOML
    
    # Step 1: Test the raw TOML parsing (with string keys)
    raw_config = TomlRB.load_file(@temp_file.path)
    
    # Test the raw config structure with string keys
    assert_equal 'test.ino', raw_config['basic']['sketch_path']
    assert_equal 'arduino-cli', raw_config['basic']['cli_path']
    assert_equal '/dev/ttyUSB0', raw_config['basic']['port']
    assert_equal 'arduino:avr:uno', raw_config['basic']['fqbn']
    assert_equal 'dual', raw_config['esp32_options']['core_config']
    assert_equal 240, raw_config['esp32_options']['frequency']
    
    # Step 2: Now test config_manager's load_config method, which should symbolize keys
    config = @config_manager.load_config(@temp_file.path)
    
    # Test the symbolized config structure
    assert_equal 'test.ino', config[:basic][:sketch_path]
    assert_equal 'arduino-cli', config[:basic][:cli_path]
    assert_equal '/dev/ttyUSB0', config[:basic][:port]
    assert_equal 'arduino:avr:uno', config[:basic][:fqbn]
    assert_equal 'dual', config[:esp32_options][:core_config]
    assert_equal 240, config[:esp32_options][:frequency]
  end
    
  def test_config_manager_validation
    # Create a complete config file with all required fields
    # Use a valid FQBN from the board registry
    File.write(@temp_file.path, <<~TOML)
      [basic]
      cli_path = "arduino-cli"
      sketch_path = "test.ino"
      port = "/dev/test"
      fqbn = "arduino:avr:uno"
      
      [esp32_options]
      core_config = "dual"
      frequency = 240
    TOML
    
    # Load the config through ConfigManager
    raw_config = TomlRB.load_file(@temp_file.path)
    
    # Test raw config structure with string keys
    assert_equal "test.ino", raw_config["basic"]["sketch_path"]
    assert_equal "arduino:avr:uno", raw_config["basic"]["fqbn"]
    assert_equal "dual", raw_config["esp32_options"]["core_config"]
    
    # Now load through config manager to get symbolized keys
    config = @config_manager.load_config(@temp_file.path)
    
    # Test the symbolized config structure
    assert_equal "test.ino", config[:basic][:sketch_path]
    assert_equal "arduino-cli", config[:basic][:cli_path]
    assert_equal "/dev/test", config[:basic][:port]
    assert_equal "arduino:avr:uno", config[:basic][:fqbn]
    assert_equal "dual", config[:esp32_options][:core_config]
    assert_equal 240, config[:esp32_options][:frequency]
  end

  def test_load_config_file_not_found
    assert_raises(Grot::Errors::ConfigurationError) do
      @config_manager.load_config('nonexistent_file.toml')
    end
  end
  
  def test_load_config_invalid_toml
    # Create an invalid config file
    File.write(@temp_file.path, <<~TOML)
      sketch_path = "test.ino
      cli_path = "arduino-cli"
    TOML
    
    assert_raises(Grot::Errors::ConfigurationError) do
      @config_manager.load_config(@temp_file.path)
    end
  end
  
  def test_config_merging
    # Define global and project configs as simple hashes for testing
    global_config = {
      basic: {
        cli_path: "global-arduino-cli",
        sketch_path: "global-sketch.ino" 
      }
    }
    
    project_config = {
      basic: {
        cli_path: "project-arduino-cli"
      }
    }
    
    # Use the deep_merge method (it's private, so we need to use send)
    merged_config = @config_manager.send(:deep_merge, global_config, project_config)
    
    # Test merging behavior
    assert_equal "project-arduino-cli", merged_config[:basic][:cli_path]
    assert_equal "global-sketch.ino", merged_config[:basic][:sketch_path]
  end

  def test_board_specific_config
    # Create a complete config with all required fields in the basic section
    File.write(@temp_file.path, <<~TOML)
      [basic]
      cli_path = "arduino-cli"
      sketch_path = "test.ino"
      port = "/dev/ttyS0"
      fqbn = "esp32:esp32:esp32s3"
      
      [esp32_options]
      core_config = "single-0"
      frequency = 160
    TOML
    
    # Load the config
    config = @config_manager.load_config(@temp_file.path)
    
    # BoardStrategyFactory expects fqbn at the top level, not under basic
    # Create a modified config with fqbn at the top level for the strategy factory
    config[:fqbn] = config[:basic][:fqbn]
    
    # Create a strategy with this config
    strategy = Grot::Boards::BoardStrategyFactory.create_strategy(config)
    
    # Verify it's the right type and has the right settings
    assert_instance_of Grot::Boards::Strategies::ESP32S3BoardStrategy, strategy
    assert_equal "single-0", config[:esp32_options][:core_config]
    assert_equal 160, config[:esp32_options][:frequency]
  end

  def test_default_fallbacks
    registry = Grot::Config::ConfigRegistry.instance
    
    # Test empty config falls back to registry default
    value = registry.get_value({}, :interface, :baud_rate, 99)
    assert_equal 9600, value  # Registry default is 9600
    
    # Test registry falls back to provided default
    value = registry.get_value({}, :nonexistent, :nonexistent, 42)
    assert_equal 42, value
  end

  def test_command_specific_validation
    config = {basic: {cli_path: "arduino-cli"}}
    
    # Command that requires sketch_path and fqbn
    command_def = {
      requires_config: true, 
      requires_sketch_path: true, 
      requires_fqbn: true
    }
    
    # Should raise error with missing required fields
    assert_raises(Grot::Errors::ConfigurationError) do
      @config_manager.validate_config(config, command_def)
    end
    
    # Add required fields and test again
    config[:basic][:sketch_path] = "test.ino"
    config[:basic][:fqbn] = "arduino:avr:uno"
    
    # Simply run the method - if no exception is raised, the test passes
    @config_manager.validate_config(config, command_def)
    # Add an assert to make the test have a verification
    assert true, "No exception was raised with complete config"
  end

end