require 'test_helper'

class TestAppCommandExecution < Minitest::Test
  def setup
    @app = Grot::App.new
    
    # Save original ARGV
    @original_argv = ARGV.dup
    
    # Clear ARGV to avoid test conflicts
    ARGV.clear
    
    # Mock the CLI parser to avoid command-line parsing issues
    Grot::CLI::CLIParser.any_instance.expects(:parse).at_least(0)
  end
  
  def teardown
    # Restore original ARGV after tests
    ARGV.replace(@original_argv)
  end
  
  def test_run_with_no_command
    @app.options[:command] = nil
    @app.expects(:puts).at_least(0)
    @app.expects(:show_no_command_error)
    
    assert_equal 1, @app.run
  end
  
  def test_run_with_unknown_command
    @app.options[:command] = 'unknown_command'
    @app.expects(:puts).at_least(0)
    @app.expects(:error).with("Error: Unknown command: unknown_command")
    
    assert_equal 1, @app.run
  end
  
  def test_run_with_valid_command
    command_definition = {
      description: 'Test command',
      requires_config: false,
      action: ->(_app) { 0 }
    }
    
    @app.options[:command] = 'test_command'
    Grot::Commands::CommandRegistry.expects(:get_command)
      .with('test_command').returns(command_definition)
    
    assert_equal 0, @app.run
  end
  
  def test_run_with_config_command_success
    command_definition = {
      description: 'Test command with config',
      requires_config: true,
      action: ->(_app, _config) { 0 }
    }
    
    @app.options[:command] = 'config_command'
    @app.options[:config_file] = 'test_config.toml'
    
    Grot::Commands::CommandRegistry.expects(:get_command)
      .with('config_command').returns(command_definition)
    
    File.expects(:exist?).with('test_config.toml').returns(true)
    Grot::Config::ConfigManager.expects(:load_config)
      .with('test_config.toml').returns({:cli_path => 'arduino-cli'})
    
    assert_equal 0, @app.run
  end
  
  def test_run_with_config_command_no_config
    command_definition = {
      description: 'Test command with config',
      requires_config: true,
      action: ->(_app, _config) { 0 }
    }
    
    @app.options[:command] = 'config_command'
    @app.options[:config_file] = 'test_config.toml'
    
    Grot::Commands::CommandRegistry.expects(:get_command)
      .with('config_command').returns(command_definition)
    
    File.expects(:exist?).with('test_config.toml').returns(false)
    @app.expects(:error).at_least(0)
    
    assert_equal 1, @app.run
  end
  
  def test_run_with_error_command
    command_definition = {
      description: 'Error command',
      requires_config: false,
      action: ->(_app) { raise Grot::Errors::CommandError, "Test error" }
    }
    
    @app.options[:command] = 'error_command'
    Grot::Commands::CommandRegistry.expects(:get_command)
      .with('error_command').returns(command_definition)
      
    # Change this line to expect the exact string instead of a regex
    @app.expects(:error).with("Command error: Test error")
    
    assert_equal 1, @app.run
  end
  
  def test_execute_cli_command_with_real_time_output
    command_definition = {
      description: 'Real-time output command',
      real_time_output: true
    }
    
    Grot::Commands::CommandRegistry.expects(:get_command)
      .with('monitor').returns(command_definition)
    
    @app.expects(:execute_with_real_time_output).returns(0)
    @app.expects(:execute_with_spinner).never
    @app.expects(:execute_without_spinner).never
    @app.expects(:puts).at_least(0)
    @app.expects(:print).at_least(0)
    @app.expects(:colorize).returns("colored output").at_least(0)
    
    @app.send(:execute_cli_command, 'monitor', 'test command')
  end
  
  def test_execute_cli_command_with_spinner
    command_definition = {
      description: 'Spinner command',
      spinner_message: "Running test..."
    }
    
    # Set up the mock spinner
    spinner = mock('spinner')
    
    # Set up the expectations in correct order
    Grot::Commands::CommandRegistry.expects(:get_command)
      .with('spinner_command').returns(command_definition).at_least_once
      
    Grot::CLI::ProgressDisplay::Spinner.expects(:new)
      .with("Running test...").returns(spinner)
      
    spinner.expects(:start)
    
    # Mock Open3 and its return values
    mock_status = mock('status')
    # Allow success? to be called multiple times
    mock_status.stubs(:success?).returns(true)
    # Allow exitstatus to be called at least once
    mock_status.stubs(:exitstatus).returns(0)
    
    Open3.expects(:capture3)
      .with('test command')
      .returns(['stdout', '', mock_status])
    
    spinner.expects(:stop).with(true)
    
    # Allow colorize and puts to be called any number of times
    @app.stubs(:colorize).returns("colored output")
    @app.stubs(:puts)
    
    @app.send(:execute_cli_command, 'spinner_command', 'test command')
  end

  def test_execute_cli_command_with_timeout
    command_definition = {
      description: 'Command that times out',
    }
    
    Grot::Commands::CommandRegistry.expects(:get_command)
      .with('timeout_command').returns(command_definition)
    
    @app.expects(:execute_without_spinner).raises(Timeout::Error, "Command timed out")
    
    assert_raises(Grot::Errors::CommandExecutionError) do
      @app.send(:execute_cli_command, 'timeout_command', 'test command')
    end
  end
  
def test_execute_cli_command_with_failed_command
  command_definition = {
    description: 'Failed command',
  }
  
  # Mock the command registry call
  Grot::Commands::CommandRegistry.expects(:get_command)
    .with('failed_command').returns(command_definition)
  
  # Instead of using expects on the mock_status, we'll use a stub
  # This allows the method to be called multiple times
  mock_status = stub('process_status', 
                    success?: false, 
                    exitstatus: 1)
  
  # Mock Open3.capture3 to return our stubbed status
  Open3.expects(:capture3).with('test command')
    .returns(['', 'error', mock_status])
  
  # Expect the error message to be called exactly once
  @app.expects(:error).with("Command failed with exit status: 1").once
  
  # Allow these to be called any number of times
  @app.stubs(:puts)
  @app.stubs(:colorize).returns("colored output")
  
  # Call the method under test
  status = @app.send(:execute_cli_command, 'failed_command', 'test command')
  
  # Verify the return value
  assert_equal 1, status
end

end