# Grot

Grot is a command line tool that wraps the `arduino-cli` library. It sports simple configuration driven commands, a serial monitor, and a serial plotter. The serial tools are both compatible with the Arduino IDE 2.x data formats.

Grot was born out of frustration with the overly simple Arduino IDE, a dislike of Visual Studio, and my old school Ruby roots (text editors and command lines!). In other words I wanted a simple command line tool with commands that I can actually remember, and I didn't want to give up the serial monitor and plotter.

## Project Status
This is a hobby project. Use at your own risk. I've used it myself for a little while, but there are surely some bugs.


## Installation

Grot uses the [gosu](https://github.com/gosu/gosu) library for the serial monitor and serial plotter. It has some specific dependencies that you'll want to make sure you have installed.

This gem is not on Rubygems as of now. You'll have to clone the repo, build the gem, and install it manually.

## Usage

```bash
# Initialize configuration - this will create a project `project-name.toml` file that you can edit with your project specifics. 
grot init

# Open the serial monitor
grot monitor

# Open the serial plotter
grot plotter

# Build Arduino sketch - details of the build are pulled from the toml config file
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

## Development Notes

### Board Support

Grot is a work in progress. Especially lacking is board support simply because I can't test boards I don't own. I've made some guesses about boards that will work, but I've not even tested all of the "supported" boards.

### Gosu and the Keyboard

It turns out that GUI support in ruby is pretty... bad. I settled on Gosu because it does the job reasonably well, but it's got some quirks. One of those is that the behavior of keyboards is rather poor. I've made an attempt at a fix for that - a pipeline of modules that modifies the keyboard events in a way that attempts to correct the various sources of bad behavior. It's horribly complicated, and probably not all necessary. It does work, though. Or at least it does on my Mac - the Linux module is still untested. The config file contains some parameters you can use to fine tune the modules, but it's very much a raw area of the code.

### AI

A lot of this code was written with the help of Claude Code. It's entirely possible that there is some AI jank lurking in spite of my best efforts to make decent software. 

That said, I don't much like writing tests and this is a hobby. The tests that do exist were entirely written by Claude with very little human oversight. AI tests are better than no tests, but if they look jacked up, they probably are. Take them with a grain of salt.

The Gosu views were also probably not as thoroughly reviewed as they should be. 
