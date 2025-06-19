require 'test_helper'

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
    assert_equal 'arduino-cli compile test.ino --fqbn arduino:avr:uno --verbose', cmd
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
  
  def test_build_command_non_cli
    @command_registry.expects(:get_command).with('custom').returns({
      action: ->(app) { true }
    })
    
    cmd = @builder.build_command('custom', {})
    assert_equal '', cmd
  end

end