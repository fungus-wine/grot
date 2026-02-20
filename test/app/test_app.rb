require 'test_helper'

class TestApp < Minitest::Test
  def setup
    @app = Grot::App.new
  end
  
  def test_initialization
    assert_nil @app.options[:command]
    assert_equal @app.send(:default_config_filename), @app.options[:config_file]
    
    # Check that instance variables are set
    assert_instance_of Grot::CLI::CLIParser, @app.instance_variable_get(:@cli_parser)
    assert_instance_of Grot::Commands::CommandBuilder, @app.instance_variable_get(:@command_builder)
    assert_instance_of Grot::Ports::PortHandler, @app.instance_variable_get(:@port_handler)
  end
  
  def test_display_executed_command
    @app.expects(:command).with('Executed: test command')
    @app.display_executed_command('test command')
  end
  
  def test_execute_cli_command_with_real_time_output
    # Create command definition for real-time output
    command_definition = {
      description: 'Real-time output command',
      real_time_output: true
    }

    Grot::Commands::CommandRegistry.expects(:get_command)
      .with('load').returns(command_definition)

    @app.expects(:execute_with_real_time_output).with('test command')
    @app.expects(:puts).at_least(0)
    @app.expects(:print).at_least(0)
    @app.expects(:colorize).returns("colored output").at_least(0)

    @app.send(:execute_cli_command, 'load', 'test command')
  end

  def test_execute_cli_command_with_spinner
    # Create command definition with spinner_message
    command_definition = {
      description: 'Spinner command',
      spinner_message: 'Running test...'
    }
    
    Grot::Commands::CommandRegistry.expects(:get_command)
      .with('build').returns(command_definition)
    
    @app.expects(:execute_with_spinner).with('build', 'test command')
    @app.expects(:puts).at_least(0)
    @app.expects(:print).at_least(0)
    @app.expects(:colorize).returns("colored output").at_least(0)
    
    @app.send(:execute_cli_command, 'build', 'test command')
  end
  
  def test_execute_cli_command_with_standard_command
    # Create command definition for standard command
    command_definition = {
      description: 'Standard command'
    }
    
    Grot::Commands::CommandRegistry.expects(:get_command)
      .with('standard').returns(command_definition)
    
    @app.expects(:execute_without_spinner).with('test command')
    @app.expects(:puts).at_least(0)
    @app.expects(:print).at_least(0)
    @app.expects(:colorize).returns("colored output").at_least(0)
    
    @app.send(:execute_cli_command, 'standard', 'test command')
  end
  
  def test_execute_with_real_time_output
    stdout_stderr = mock('stdout_stderr')
    wait_thread = mock('wait_thread')
    process_status = mock('process_status')
    
    # Use stubs instead of expects for simpler testing
    stdout_stderr.stubs(:gets).returns("line 1", nil)
    wait_thread.stubs(:value).returns(process_status)
    process_status.stubs(:exitstatus).returns(0)
    
    Open3.expects(:popen2e).with('test command').yields(nil, stdout_stderr, wait_thread)
    
    # Match the actual implementation - colorize is called with line and :grey
    @app.expects(:colorize).with("line 1", :grey).returns("colored output").once
    @app.expects(:print).with("colored output").once
    @app.expects(:puts).at_least(0)
    
    @app.send(:execute_with_real_time_output, 'test command')
  end
  
  def test_execute_with_real_time_output_interrupt
    stdout_stderr = mock('stdout_stderr')
    stdout_stderr.expects(:gets).raises(Interrupt)
    
    Open3.expects(:popen2e).with('test command').yields(nil, stdout_stderr, nil)
    
    @app.expects(:puts).with("\nCommand interrupted")
    @app.expects(:colorize).returns("colored output").at_least(0)
    
    result = @app.send(:execute_with_real_time_output, 'test command')
    assert_equal 130, result
  end
  
  def test_execute_with_real_time_output_non_zero_exit
    stdout_stderr = mock('stdout_stderr')
    wait_thread = mock('wait_thread')
    process_status = mock('process_status')
    
    stdout_stderr.expects(:gets).returns(nil)
    wait_thread.expects(:value).returns(process_status)
    process_status.expects(:exitstatus).returns(1)
    
    Open3.expects(:popen2e).with('test command').yields(nil, stdout_stderr, wait_thread)
    
    @app.expects(:error).with("Command failed with exit status: 1")
    @app.expects(:colorize).returns("colored output").at_least(0)
    
    @app.send(:execute_with_real_time_output, 'test command')
  end
end