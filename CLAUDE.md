# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Grot is a Ruby gem that provides a command-line tool for Arduino development with arduino-cli integration. It offers serial monitoring, plotting, and Arduino board management capabilities with a Gosu-based GUI for interactive interfaces.

## Development Commands

### Testing
- `rake test` or `rake test:all` - Run all tests
- `rake coverage` - Run tests with code coverage (sets COVERAGE=true)
- `ENV['COVERAGE'] = 'true' rake test:all` - Alternative coverage command

### Build and Installation
- `bundle install` - Install dependencies
- `gem build grot.gemspec` - Build the gem
- `gem install grot-VERSION.gem` - Install locally

### Running the Application
- `./exe/grot` - Run the main executable
- `bundle exec grot COMMAND` - Run via bundler
- `ENV['DEBUG']=true ./exe/grot COMMAND` - Run with debug output

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
- `requires_config`, `requires_fqbn`, `requires_port` - Validation flags
- `action` - Lambda or string defining the command execution
- `spinner_*` - UI feedback configuration
- `pre_action`/`post_action` - Hooks for command lifecycle

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
- `MonitorInterface` and `PlotterInterface` extend base for specific UIs
- Component system with reusable UI elements
- Models handle serial communication and data parsing

### Key Dependencies
- `gosu` - GUI framework for interfaces
- `rubyserial` - Serial port communication
- `toml-rb` - Configuration file parsing
- `minitest` + `mocha` - Testing framework

### Configuration
- Default config file: `grot.toml` in current directory
- Config categories: board, keyboard, interface, theme
- Hierarchical defaults system with registry-based lookups

### Test Structure
- Tests use Minitest with Mocha for mocking
- Helper utilities in `test_helper.rb`
- Tests organized by module/component
- Coverage reports generated to `coverage/` directory