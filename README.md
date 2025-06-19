# Grot

A Ruby gem providing a command-line tool for Arduino development with arduino-cli integration. Grot offers serial monitoring, plotting, and Arduino board management capabilities with Gosu-based GUI interfaces.

## Features

### Serial Monitor
- **Real-time text display** with UTF-8 support and scrolling
- **Logging system** with sequential log files (monitor_1.log, monitor_2.log)
- **Bookmarks** for easy log navigation (press B key)
- **Status bar** showing connection, logging, and data rate
- **Command input** to send data to Arduino
- **Arduino IDE compatibility** for data formats and encoding

### Serial Plotter
- **Real-time plotting** of multiple data series
- **Auto-scaling** with configurable buffer sizes
- **Interactive legend** with series visibility control
- **Status bar** with connection and data rate monitoring

### Board Management
- **Board-specific strategies** for different Arduino models
- **Configuration validation** and board-specific build properties
- **Support** for Arduino GIGA R1 WiFi and ESP32-S3 boards

## Installation

```bash
gem install grot
```

## Usage

```bash
# Initialize configuration
grot init

# Monitor serial data
grot monitor

# Plot serial data
grot plotter

# Build Arduino sketch
grot build

# Upload to board
grot load

# List available ports
grot ports
```

## Configuration

Grot uses a `grot.toml` configuration file:

```toml
[basic]
cli_path = "arduino-cli"
port = "/dev/ttyUSB0"
fqbn = "arduino:avr:uno"
sketch_path = "sketch.ino"

[interface]
baud_rate = 9600

[monitor]
auto_start_logging = false
log_directory = "./log"

[plotter]
buffer_size = 500
```

## Keyboard Shortcuts

### Monitor
- **Space** - Pause/resume data collection
- **T** - Toggle timestamps
- **L** - Start/stop logging
- **B** - Insert bookmark
- **C** - Clear monitor
- **H** - Show help
- **Tab** - Activate command input

### Plotter
- **Space** - Pause/resume data collection
- **L** - Toggle legend
- **H** - Show help
- **1-9** - Toggle series visibility
- **Tab** - Activate command input

## Development

```bash
# Install dependencies
bundle install

# Run tests
rake test

# Build gem
gem build grot.gemspec
```

## Architecture

Grot follows a modular architecture with:

- **Command registry** pattern for extensible commands
- **Board strategy** pattern for device-specific handling
- **Component-based UI** with reusable interface elements
- **Modular keyboard** system with event bus architecture

## Requirements

- Ruby 2.7+
- arduino-cli
- Serial port access

## License

[Add your license here]