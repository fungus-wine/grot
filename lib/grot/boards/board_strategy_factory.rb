# frozen_string_literal: true

require "grot/boards/board_registry"
require "grot/boards/strategies/base_board_strategy"
require "grot/boards/strategies/default_board_strategy"
require "grot/boards/strategies/giga_board_strategy"
require "grot/boards/strategies/esp32_s3_board_strategy"

module Grot
  module Boards
    # Factory for creating board-specific strategies
    class BoardStrategyFactory
      # Map of strategy names to strategy classes
      STRATEGY_MAP = {
        'default' => Strategies::DefaultBoardStrategy,
        'giga' => Strategies::GigaBoardStrategy,
        'esp32_s3' => Strategies::ESP32S3BoardStrategy
      }.freeze
      
      def self.create_strategy(config)
        # Get board info from registry
        fqbn = config[:fqbn]
        strategy_name = BoardRegistry.strategy_for(fqbn)
        
        # Look up and instantiate the corresponding strategy class
        strategy_class = STRATEGY_MAP[strategy_name]
        
        if strategy_class
          strategy_class.new(config)
        else
          # Fallback to default if no matching strategy is found
          Strategies::DefaultBoardStrategy.new(config)
        end
      end
      
      # Get all available strategy classes
      def self.all_strategies
        STRATEGY_MAP.values.map { |klass| klass.new({}) }.uniq
      end
    end
  end
end