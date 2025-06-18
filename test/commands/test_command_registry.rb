require 'test_helper'

class TestCommandRegistry < Minitest::Test
  def test_get_command
    # Test with a command we know exists
    command = Grot::Commands::CommandRegistry.get_command('version')
    assert_kind_of Hash, command
    assert_includes command[:description], 'version'
    
    # Test with unknown command
    assert_nil Grot::Commands::CommandRegistry.get_command('nonexistent_command')
  end
  
  def test_list_commands
    commands = Grot::Commands::CommandRegistry.list_commands
    assert_kind_of Array, commands
    refute_empty commands
    
    first_command = commands.first
    assert_kind_of Array, first_command
    assert_equal 2, first_command.size
    assert_kind_of String, first_command[0]  # Command name
    assert_kind_of String, first_command[1]  # Description
  end
  
  def test_essential_commands_exist
    assert Grot::Commands::CommandRegistry.get_command('build')
  end
end