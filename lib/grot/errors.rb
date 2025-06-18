# frozen_string_literal: true

module Grot
  module Errors
    class GrotError < StandardError; end
    class ConfigurationError < GrotError; end
    class BoardStrategyError < GrotError; end
    class SerialPortError < GrotError; end
    class CommandExecutionError < GrotError; end
    class CommandError < GrotError; end
  end
end