# CLAUDE.md

## Project Overview

Grot is a Ruby gem that provides a command-line tool for Arduino development with arduino-cli integration.

## Development Commands

### Testing
- `rake test` or `rake test:all` - Run all tests
- `rake coverage` - Run tests with code coverage (sets COVERAGE=true)
- `ENV['COVERAGE'] = 'true' rake test:all` - Alternative coverage command

### Build and Installation
- `bundle install` - Install dependencies
- `gem build grot.gemspec` - Build the gem
- `gem install grot-VERSION.gem` - Install locally

## Architecture Overview

### Core Components

1. **App Class** (`lib/grot/app.rb`) - Main application entry point that orchestrates command execution
2. **Command System** - Registry-based command handling with pre/post actions and spinners
3. **Board Strategy Pattern** - Extensible board-specific handling via strategy classes
4. **Interface System** - Gosu-based GUI interfaces for monitor and plotter
5. **Keyboard Manager** - Modular keyboard input handling with event bus architecture
6. **Configuration System** - TOML-based configuration with defaults and validation

### Key Architectural Patterns

#### Command Registry Pattern
Commands are defined in `CommandRegistry::COMMANDS` hash with metadata:
- `requirements` - Array of validation requirements (config, fqbn, port, sketch_path)
- `action` - Lambda or string defining the command execution
- `spinner_message` - UI feedback configuration
- `pre_action`/`post_action` - Hooks for command lifecycle
- Board-specific behavior is implicit based on `:fqbn` requirement

#### Board Strategy Factory
- `BoardStrategyFactory` creates board-specific strategies
- Strategies inherit from `BaseBoardStrategy`
- Board mapping defined in `BoardRegistry`
- Supports: default, giga, esp32_s3 strategies

#### Modular Keyboard System
- `KeyboardManager` orchestrates input handling
- `ModuleRegistry` manages keyboard modules
- `EventBus` handles inter-module communication
- Modules: key_state, stuck_key_fixer, mac_adapter, buffer, debouncer

#### Interface Architecture
- `BaseInterface` provides common Gosu window functionality
- `MonitorInterface` - Serial monitor with text display, logging, and bookmarks
- `PlotterInterface` - Real-time data plotting with multiple series support
- `StatusBar` - Reusable status component showing connection, logging, and data rate
- `CommandBar` and `HelpDialog` - Shared UI components
- Models handle serial communication, data parsing, and buffer management

### Key Dependencies
- `gosu` - GUI framework for interfaces
- `rubyserial` - Serial port communication
- `toml-rb` - Configuration file parsing
- `minitest` + `mocha` - Testing framework

### Configuration
- Default config file: `.grotconfig` in current directory
- Global config file: `~/.config/grot/.grotconfig`
- Config categories: board, keyboard, interface, monitor, plotter, theme
- Monitor config: auto_start_logging, log_directory (default: "./log")
- Plotter config: buffer_size (default: 500)
- Hierarchical defaults system with registry-based lookups

### Serial Monitor Features
- **Real-time Text Display**: UTF-8 compatible text rendering with scrolling
- **Logging System**: Sequential log files (monitor_1.log, monitor_2.log) with timestamps
- **Bookmarks**: Insertable markers for easy log navigation (B key, cyan display)
- **Status Bar**: Real-time connection, logging, pause, and timestamp status
- **Keyboard Shortcuts**: Space (pause), T (timestamps), L (logging), C (clear), H (help)
- **Command Input**: Send commands to Arduino via Tab key activation
- **Arduino IDE Compatibility**: Full UTF-8, line ending, and data format support

### Test Structure
- Tests use Minitest with Mocha for mocking
- Helper utilities in `test_helper.rb`
- Tests organized by module/component
- Coverage reports generated to `coverage/` directory

# IMPORTANT: Never add Claude/Anthropic footers to commit messages
  Do not add any "Generated with Claude Code" or "Co-Authored-By: Claude" footers to any commits. Keep commit messages clean and concise without AI attribution.