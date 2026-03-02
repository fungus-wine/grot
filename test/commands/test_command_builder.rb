require 'test_helper'
require 'tmpdir'
require 'fileutils'

class TestCommandBuilder < Minitest::Test
  def setup
    @builder = Grot::Commands::CommandBuilder.new
    @command_registry = Grot::Commands::CommandRegistry
  end
  
  def test_build_basic_command
    # Mock command definitions
    @command_registry.expects(:get_command).with('build').returns({
      action: 'compile',
      requirements: [:sketch_path, :fqbn],
      verbose: true
    })
    
    config = {
      :basic => {
        :cli_path => 'arduino-cli',
        :sketch_path => 'test.ino',
        :fqbn => 'arduino:avr:uno'
      }
    }
    
    cmd = @builder.build_command('build', config)
    assert_equal 'arduino-cli compile test.ino --fqbn arduino:avr:uno --verbose --export-binaries', cmd
  end
  
  def test_build_command_with_port
    @command_registry.expects(:get_command).with('monitor').returns({
      action: 'monitor',
      requirements: [:port],
      verbose: false
    })
    
    config = {
      :basic => {
        :cli_path => 'arduino-cli',
        :port => '/dev/ttyUSB0'
      }
    }
    
    cmd = @builder.build_command('monitor', config)
    assert_equal 'arduino-cli monitor --port /dev/ttyUSB0', cmd
  end
  
  def test_build_command_with_giga_fqbn_options
    @command_registry.expects(:get_command).with('build').returns({
      action: 'compile',
      requirements: [:sketch_path, :fqbn],
      verbose: false
    })

    config = {
      :basic => {
        :cli_path => 'arduino-cli',
        :sketch_path => '.',
        :fqbn => 'arduino:mbed_giga:giga'
      },
      :giga_options => {
        :target_core => 'cm7',
        :split => '50_50'
      }
    }

    cmd = @builder.build_command('build', config)
    assert_equal 'arduino-cli compile . --fqbn arduino:mbed_giga:giga:target_core=cm7,split=50_50 --export-binaries', cmd
  end

  def test_build_command_includes_export_binaries
    @command_registry.expects(:get_command).with('build').returns({
      action: 'compile',
      requirements: [:sketch_path, :fqbn],
      verbose: false
    })

    config = {
      basic: {
        cli_path: 'arduino-cli',
        sketch_path: '.',
        fqbn: 'arduino:avr:uno'
      }
    }

    cmd = @builder.build_command('build', config)
    assert_includes cmd, '--export-binaries'
  end

  def test_teensy_load_command
    @command_registry.expects(:get_command).with('load').returns({
      action: 'upload',
      requirements: [:sketch_path, :fqbn, :port],
      verbose: false
    })

    # Create a temp hex file to be found by glob
    Dir.mktmpdir do |sketch_dir|
      build_dir = File.join(sketch_dir, "build", "teensy.avr.teensy41")
      FileUtils.mkdir_p(build_dir)
      hex_file = File.join(build_dir, "sketch.ino.hex")
      File.write(hex_file, "fake hex")

      config = {
        basic: {
          cli_path: 'arduino-cli',
          sketch_path: sketch_dir,
          fqbn: 'teensy:avr:teensy41',
          port: '/dev/ttyACM0'
        },
        teensy: {
          loader_path: '/usr/local/bin/teensy_loader_cli'
        }
      }

      cmd = @builder.build_command('load', config)
      assert_includes cmd, '/usr/local/bin/teensy_loader_cli'
      assert_includes cmd, '--mcu=TEENSY41'
      assert_includes cmd, '-w -v'
      assert_includes cmd, hex_file
    end
  end

  def test_teensy_load_command_no_hex_file
    @command_registry.expects(:get_command).with('load').returns({
      action: 'upload',
      requirements: [:sketch_path, :fqbn, :port],
      verbose: false
    })

    Dir.mktmpdir do |sketch_dir|
      config = {
        basic: {
          cli_path: 'arduino-cli',
          sketch_path: sketch_dir,
          fqbn: 'teensy:avr:teensy41',
          port: '/dev/ttyACM0'
        },
        teensy: {
          loader_path: 'teensy_loader_cli'
        }
      }

      error = assert_raises(Grot::Errors::CommandExecutionError) do
        @builder.build_command('load', config)
      end
      assert_match(/No hex file found/, error.message)
    end
  end

  def test_non_teensy_load_uses_arduino_cli
    @command_registry.expects(:get_command).with('load').returns({
      action: 'upload',
      requirements: [:sketch_path, :fqbn, :port],
      verbose: false
    })

    config = {
      basic: {
        cli_path: 'arduino-cli',
        sketch_path: '.',
        fqbn: 'arduino:avr:uno',
        port: '/dev/ttyUSB0'
      }
    }

    cmd = @builder.build_command('load', config)
    assert_includes cmd, 'arduino-cli upload'
    refute_includes cmd, 'teensy_loader_cli'
  end

  def test_build_command_non_cli
    @command_registry.expects(:get_command).with('custom').returns({
      action: ->(app) { true }
    })
    
    cmd = @builder.build_command('custom', {})
    assert_equal '', cmd
  end

end