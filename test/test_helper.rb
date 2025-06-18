require 'bundler/setup'
$LOAD_PATH.unshift File.expand_path("..", __FILE__)  # Adds test/
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)  # Adds lib/
require 'grot'
require 'minitest/autorun'
require 'mocha'
require 'mocha/minitest'

# Helper method for capturing stdout in tests
def capture_stdout
  original_stdout = $stdout
  $stdout = StringIO.new
  yield
  $stdout.string
ensure
  $stdout = original_stdout
end