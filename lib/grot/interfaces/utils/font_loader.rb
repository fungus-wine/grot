# frozen_string_literal: true

require 'gosu'

module Grot
  module Interfaces
    module Utils
      class FontLoader
        DEFAULT_FONT_NAME = 'InconsolataNerdFont-Regular'
        DEFAULT_FONT_SIZE = 16
        
        BUNDLED_FONTS = {
          'InconsolataNerdFont-Regular' => 'InconsolataNerdFont-Regular.ttf',
          'InconsolataNerdFont-Bold' => 'InconsolataNerdFont-Bold.ttf'
        }.freeze

        class << self
          def load_font(name = nil, size = DEFAULT_FONT_SIZE)
            font_name = name || DEFAULT_FONT_NAME
            
            if BUNDLED_FONTS.key?(font_name)
              font_path = bundled_font_path(font_name)
              Gosu::Font.new(size, name: font_path)
            else
              Gosu::Font.new(size, name: font_name)
            end
          end

          def bundled_font_path(font_name)
            gem_root = File.expand_path('../../../..', __dir__)
            font_file = BUNDLED_FONTS[font_name]
            File.join(gem_root, 'lib', 'grot', 'assets', 'fonts', font_file)
          end
        end
      end
    end
  end
end