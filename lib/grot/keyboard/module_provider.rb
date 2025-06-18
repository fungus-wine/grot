module Grot
  module Keyboard
    module ModuleProvider
      @providers = {}
      
      def self.register(name, klass, priority = 0, &config_block)
        @providers[name] = {
          class: klass,
          priority: priority,
          config_block: config_block || ->(_config) { {} }
        }
      end
      
      def self.all
        @providers
      end
    end
  end
end