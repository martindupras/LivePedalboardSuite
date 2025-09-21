
# System Specification: Modular Guitar-Controlled Audio Pedalboard with Hierarchical Command Navigation

## 1. System Overview

This system is a modular, software-based audio pedalboard designed for live performance and experimentation. It is controlled by a hexaphonic (six-string) guitar, where each string is mapped to a separate MIDI channel. The performer navigates a hierarchical command tree by playing specific frets on each string, allowing for rapid, hands-free selection and execution of audio processing commands. The system is designed for flexibility, robust state management, and clear feedback to the performer.

## 2. Core Concepts

### 2.1. Audio Pedalboard Engine

- **Signal Chains:**  
  The audio engine maintains two parallel signal chains (A and B), each consisting of a sequence of audio processors (effects) and a source. These chains are dynamically reconfigurable.
- **Processors:**  
  Each processor is a modular audio effect (e.g., delay, chorus, reverb, drive) that can be inserted, bypassed, or removed from a chain. All processors are designed to operate on a configurable number of channels (typically stereo).
- **Chain Switching:**  
  The performer can crossfade between the two chains, ensuring smooth transitions. Only one chain is audible at a time, except during deliberate crossfades.
- **Exclusivity:**  
  The system enforces that only the “current” chain is audible, muting the “next” chain at its source except during crossfades.

### 2.2. Hierarchical Command Navigation

- **Command Tree:**  
  All available commands (such as adding effects, switching chains, or changing sources) are organized in a hierarchical tree structure. Each node represents a command or a category of commands.
- **Navigation by Guitar:**  
  The performer navigates the tree by playing specific frets on each string. Each string corresponds to a level in the tree; the fret number selects a branch at that level.
- **Command Queue:**  
  As the performer navigates, the selected path is recorded as a sequence of tokens (e.g., `/audio/time-based/delay`). When navigation is complete (either at a leaf node or by explicit user action), the resulting command path is queued for execution.

### 2.3. Execution and Feedback

- **Command Execution:**  
  When the performer triggers execution (e.g., by pressing a footswitch or reaching a leaf node), the queued command is sent to the audio engine for processing.
- **Partial Commands:**  
  The system allows for both complete (leaf node) and partial (intermediate node) command paths to be executed, enabling both generic and specific actions.
- **User Feedback:**  
  The system provides real-time feedback on the current navigation state, available choices, queued commands, and execution status via a display (console or GUI).

## 3. System Architecture

### 3.1. Audio Engine

- Maintains two independent signal chains (A/B), each as an ordered list of processors and a source.
- Supports dynamic mutation of chains: add, remove, swap, bypass processors; set sources.
- Enforces channel count and audio-rate consistency throughout the chain.
- Provides robust methods for resetting, rebuilding, and crossfading chains.

### 3.2. Command Navigation and Queue

- Maintains a hierarchical tree of commands, each node with a name, identifier, fret mapping, and optional payload.
- Navigation is performed by mapping incoming MIDI notes (from each guitar string/channel) to tree branches.
- Tracks the current navigation path and supports resetting or restarting navigation at any time.
- Maintains a queue of commands to be executed, supporting enqueue, dequeue, clear, and export operations.

### 3.3. MIDI and Device Management

- Detects and manages multiple MIDI input devices (guitar, foot controller, launchpad, etc.).
- Binds specific handlers to each device, mapping incoming MIDI messages to navigation, mode switching, or command execution.
- Supports flexible mode switching (e.g., navigation, queueing, sending, play, record) via foot controller or other devices.

### 3.4. Display and Feedback

- Provides a user interface (console or GUI) that displays:
  - Current navigation mode and state
  - Available choices at each navigation step
  - Current command queue
  - Last executed command
  - Status messages and errors
- Updates the display in real time as navigation and execution progress.

## 4. Operational Workflow

1. **System Initialization**
   - Audio engine initializes both signal chains with default processors and sources.
   - Command tree is loaded from a configuration file or built programmatically.
   - MIDI devices are detected and handlers are bound.

2. **Navigation**
   - Performer enters navigation mode (e.g., via foot controller).
   - Each string/fret played advances one level in the command tree.
   - At each step, available choices are displayed.
   - Navigation can be completed by reaching a leaf node or by explicit user action.

3. **Queueing and Execution**
   - Upon completion, the selected command path is added to the command queue.
   - Performer can review, modify, or clear the queue.
   - When ready, the performer triggers execution (e.g., via foot controller).
   - The queued command is sent to the audio engine for processing.

4. **Audio Processing**
   - The audio engine interprets the command path and mutates the signal chain(s) accordingly.
   - If a chain switch is requested, a crossfade is performed.
   - Exclusivity is enforced: only the current chain is audible.

5. **Feedback**
   - The display updates to reflect the new state, available commands, and any errors or status changes.

## 5. Design Principles

- **Modularity:**  
  All components (audio processors, command nodes, device handlers) are modular and extensible.
- **Robustness:**  
  The system is designed to recover gracefully from errors, with clear state management and reset capabilities.
- **Real-Time Safety:**  
  All time-sensitive operations (audio, MIDI) are handled in a thread-safe manner, with UI updates deferred as needed.
- **User-Centric Feedback:**  
  The performer receives immediate, clear feedback at every step, supporting both novice and expert workflows.
- **Testability:**  
  The system supports headless (non-GUI) operation and automated acceptance tests using generated audio only.

## 6. Extensibility and Future Directions

- **Additional Processors:**  
  New audio effects can be added by registering new processor modules.
- **Custom Command Trees:**  
  The command hierarchy can be reconfigured or extended to support new workflows.
- **Advanced Displays:**  
  The user interface can be enhanced with richer visualizations, touch support, or remote control.
- **Integration with Other Instruments:**  
  The navigation and command system can be adapted for other MIDI controllers or input devices.

## 7. Example Use Case

1. Performer powers on the system; both audio chains are initialized with default settings.
2. Performer enters navigation mode and plays a sequence of frets on the guitar, selecting a path such as “audio → time-based → delay”.
3. The system displays available sub-commands (e.g., “multi-tap”, “ping-pong”) or allows execution of the generic delay command.
4. Performer confirms the selection; the command is queued.
5. Performer triggers execution; the delay effect is added to the next chain, and a crossfade is performed to make it active.
6. The display updates to show the new chain configuration and confirms successful execution.

## 8. Summary

This system enables expressive, hands-free control of a modular audio pedalboard using a guitar as a navigation device. Its hierarchical command structure, robust audio engine, and real-time feedback make it suitable for live performance, experimentation, and further extension.
