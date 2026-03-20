# Grot

Grot is a command line tool that wraps the `arduino-cli` library. It sports simple configuration driven commands for building and uploading Arduino sketches.

Grot also uses `teensy_loader_cli` to support Teensy boards.

Grot was born out of frustration with the overly simple Arduino IDE, a dislike of Visual Studio, and my old school Ruby roots (text editors and command lines!). In other words I wanted a simple command line tool with commands that I can actually remember.

## Project Status
This is a hobby project. Use at your own risk. I've used it myself for a little while, but there are surely some bugs.


## Installation

This gem is not on Rubygems as of now. You'll have to clone the repo, build the gem, and install it manually.

## Usage

```bash
# Initialize configuration - this will create a project `.grotconfig` file that you can edit with your project specifics.
grot init

# Build Arduino sketch - details of the build are pulled from the config file
grot build

# Upload to board - details of the build are pulled from the toml config file
grot load

# List available ports on your system, and which ones are likely to be attached to your arduino
grot ports

# list of supported boards and their FQBNs 
grot boards

# help
grot -h
 
```

## Configuration

Grot uses a `.grotconfig` configuration file in your project's root directory. This file will override the global configuration that that you can optionally put at `~/.config/grot/.grotconfig`.

```toml
#example grot config file 

[basic]
cli_path = "arduino-cli"
port = "/dev/ttyUSB0" # not needed for Teensy
fqbn = "arduino:avr:uno"
sketch_path = "sketch.ino"

[interface]
baud_rate = 9600
```

## Development Notes

### Board Support

Grot is a work in progress. Especially lacking is board support simply because I can't test boards I don't own. I've made some guesses about boards that will work, but I've not even tested all of the "supported" boards. So far, I have used it successfully with:

-Arduino Uno
-Arduino GIGA R1 WiFi
-Teensy 4.1
-Adafruit QT Py ESP32-S3 (4M Flash 2M PSRAM)
-Adafruit Feather ESP32-S3 Revese TFT

### AI

A lot of this code was written with the help of Claude Code. It's entirely possible that there is some AI jank lurking in spite of my best efforts to make decent software. 

That said, I don't much like writing tests and this is a hobby. The tests that do exist were entirely written by Claude with very little human oversight. AI tests are better than no tests, but if they look jacked up, they probably are. Take them with a grain of salt.
