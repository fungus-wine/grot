# frozen_string_literal: true

require 'test_helper'
require 'tempfile'

class TestConfigManager < Minitest::Test
  def setup
    @temp_config_file = Tempfile.new(['test_config', '.toml'])
  end

  def teardown
    @temp_config_file.close
    @temp_config_file.unlink
  end

  def test_load_config_with_defaults
    # Test loading with no config file - should get defaults
    config = Grot::Config::ConfigManager.load_config(nil)

    # Verify defaults are loaded
    assert_equal 9600, config.dig(:interface, :baud_rate)
    assert_equal "arduino-cli", config.dig(:basic, :cli_path)
  end

  def test_load_config_with_toml_file
    # Write a test config file
    @temp_config_file.write(<<~TOML)
      [basic]
      cli_path = "/custom/arduino-cli"

      [interface]
      baud_rate = 115200

    TOML
    @temp_config_file.close

    # Load the config
    config = Grot::Config::ConfigManager.load_config(@temp_config_file.path)

    # Verify custom values override defaults
    assert_equal "/custom/arduino-cli", config.dig(:basic, :cli_path)
    assert_equal 115200, config.dig(:interface, :baud_rate)
  end

  def test_type_coercion
    # Write a config with string values that should be coerced
    @temp_config_file.write(<<~TOML)
      [interface]
      baud_rate = "57600"

      [giga_options]
      split = "75_25"
    TOML
    @temp_config_file.close

    config = Grot::Config::ConfigManager.load_config(@temp_config_file.path)

    # Verify types are coerced correctly
    assert_equal 57600, config.dig(:interface, :baud_rate)
    assert_instance_of Integer, config.dig(:interface, :baud_rate)

    assert_equal "75_25", config.dig(:giga_options, :split)
    assert_instance_of String, config.dig(:giga_options, :split)
  end

  def test_invalid_toml_file
    # Write invalid TOML
    @temp_config_file.write("invalid toml [[[")
    @temp_config_file.close

    error = assert_raises(RuntimeError) do
      Grot::Config::ConfigManager.load_config(@temp_config_file.path)
    end

    assert_match(/Failed to load config file/, error.message)
  end

  def test_invalid_type_coercion
    # Write a config with invalid integer value
    @temp_config_file.write(<<~TOML)
      [interface]
      baud_rate = "not_a_number"
    TOML
    @temp_config_file.close

    error = assert_raises(RuntimeError) do
      Grot::Config::ConfigManager.load_config(@temp_config_file.path)
    end

    assert_match(/interface.baud_rate must be an integer/, error.message)
  end

  def test_nonexistent_file
    # Should work fine with non-existent file (uses defaults)
    config = Grot::Config::ConfigManager.load_config("/path/that/does/not/exist.toml")

    # Should still get defaults
    assert_equal 9600, config.dig(:interface, :baud_rate)
  end

  def test_non_string_fqbn_raises_friendly_error
    @temp_config_file.write(<<~TOML)
      [basic]
      fqbn = 6
    TOML
    @temp_config_file.close

    error = assert_raises(RuntimeError) do
      Grot::Config::ConfigManager.load_config(@temp_config_file.path)
    end

    assert_match(/basic\.fqbn must be a string/, error.message)
    assert_match(/Integer/, error.message)
  end

  def test_non_string_port_raises_friendly_error
    @temp_config_file.write(<<~TOML)
      [basic]
      port = true
    TOML
    @temp_config_file.close

    error = assert_raises(RuntimeError) do
      Grot::Config::ConfigManager.load_config(@temp_config_file.path)
    end

    assert_match(/basic\.port must be a string/, error.message)
  end

  def test_deep_merge
    # Write a config that partially overrides nested structures
    @temp_config_file.write(<<~TOML)
      [giga_options]
      split = "75_25"
      # Should keep other giga_options defaults
    TOML
    @temp_config_file.close

    config = Grot::Config::ConfigManager.load_config(@temp_config_file.path)

    # Verify partial override works
    assert_equal "75_25", config.dig(:giga_options, :split)

    # Verify other defaults in same section are preserved
    assert_equal "cm7", config.dig(:giga_options, :target_core)
  end
end
