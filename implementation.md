# Swift to Python

Goal: To go from an iOS app to keyboard inputs.

### **Implementation Order**

#### 1. **Transport Layer: `ESPUDPLink.swift`**
   - **Why First?**
     - This layer is the foundation for communication with the drone. Without a functioning UDP link, no commands can be sent or received.
   - **What to Implement?**
     - Establish a UDP socket connection.
     - Implement basic methods for sending (`sendto`) and receiving (`recvfrom`) packets.
#### 2. **Protocol Layer: `CrtpDriver.swift`**
   - **Why Next?**
     - The `CrtpDriver` abstracts the communication protocol and interacts directly with `ESPUDPLink`. It provides the interface that higher layers use for sending data.
   - **What to Implement?**
     - Define methods for connecting and disconnecting the drone.
     - Create an interface for sending packets (e.g., thrust, roll, pitch, yaw) via the UDP link.
#### 3. **Application Layer: `CrazyFlie.swift`**
   - **Why After?**
     - This is the high-level controller that manages state and assembles command packets. It depends on `CrtpDriver` for communication.
   - **What to Implement?**
     - Create state management for the connection (`idle`, `connected`, etc.).
     - Define methods to generate and send control packets (e.g., thrust adjustments).
     - Implement a loop or event system to handle updates (keyboard inputs in this case).
#### 4. **Joystick Data Processing: `CrazyFlieModes.swift`**
   - **Why Here?**
     - The joystick data must be processed and scaled correctly to fit drone control parameters (e.g., roll, pitch, yaw, thrust).
   - **What to Implement?**
     - Implement data providers (e.g., `CrazyFlieDataProvider`) to handle normalized inputs.
     - Add scaling logic in `SimpleCrazyFlieCommander` for thrust and other parameters.
#### 5. **User Input Handling: Keyboard Integration**
   - **Why Last?**
     - The application layer (`CrazyFlie`) needs to be ready to handle user input and convert it into commands for the drone.
   - **What to Implement?**
     - Capture keyboard inputs using a library like `pynput` or `curses`.
     - Map keyboard keys to drone commands (e.g., `W` for thrust increase, `A` for roll left).
     - Pass these inputs to `CrazyFlie` for processing and transmission.
