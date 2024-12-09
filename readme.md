ESP-Drone iOS client
======================

***The original `readme.md` can be found here: [ESP-Drone-iOS:README](https://github.com/EspressifApps/ESP-Drone-iOS).***

---

The relationship between `CrazyFlie.swift`, `CrtpDriver.swift`, and `ESPUDPLink.swift` is a **layered architecture** 
where each file/module has distinct responsibilities and interacts with the others to manage communication with the drone. 
Here's how ***I think*** they relate:

---

## **Overview of the Files**

#### **1. `CrazyFlie.swift`**
   - **Role**: High-level controller for managing the drone's state and behavior.
   - **Responsibilities**:
     - Tracks the connection state (`CrazyFlieState`).
     - Provides flight command logic (`sendFlightData`).
     - Manages timers for periodic updates.
     - Delegates communication to a `CrtpDriver` implementation (e.g., `ESPUDPLink`).
   - **Depends On**:
     - `CrtpDriver`: Defines the low-level communication interface.
     - `ESPUDPLink`: Implements the `CrtpDriver` protocol for UDP communication.
   - This is the "brains" of the operation.
   - Responsible for orchestrating communication, managing states, and processing user input.

---

#### **2. `CrtpDriver.swift`**
   - **Role**: Protocol defining the communication interface with the drone.
   - **Responsibilities**:
     - Abstracts communication operations:
       - `connect`: Establish connection to the drone.
       - `disconnect`: End connection.
       - `sendPacket`: Send data packets.
       - `onStateUpdated`: Handle state changes.
     - Provides a consistent API for various transport mechanisms (e.g., UDP, BLE).
   - **Depends On**:
     - Itself: Acts as a protocol that other classes (e.g., `ESPUDPLink`) must conform to.
   - Acts as a contract/interface between `CrazyFlie` and the transport layer.
   - Ensures `CrazyFlie` doesn't depend on specific transport implementations (e.g., UDP vs. BLE).

---

#### **3. `ESPUDPLink.swift`**
   - **Role**: Low-level communication driver for UDP-based transport.
   - **Responsibilities**:
     - Implements `CrtpDriver` to handle UDP communication.
     - Manages sockets for sending/receiving packets.
     - Tracks and updates the connection state (`idle`, `connected`).
   - **Depends On**:
     - `CrtpDriver`: Implements its methods to provide the actual transport logic.
     - Swift networking libraries (e.g., `GCDAsyncUdpSocket`).
   - Handles the nuts and bolts of sending and receiving data over the network.
   - Ensures packets are formatted, sent, and received correctly over UDP.

---

### **How They Work Together**

#### **Relationship Flow**
1. **`CrazyFlie.swift`** (High-Level Controller):
   - Uses `CrtpDriver` to interact with the drone.
   - Tracks connection state and delegates data transmission to the driver.
   - Processes high-level logic (e.g., flight commands) and passes prepared data to `CrtpDriver`.

2. **`CrtpDriver.swift`** (Protocol Definition):
   - Defines the contract for communication between `CrazyFlie` and any transport implementation.
   - Ensures `CrazyFlie` can work with any driver (UDP, BLE, etc.) without depending on implementation details.

3. **`ESPUDPLink.swift`** (UDP Transport Implementation):
   - Implements `CrtpDriver` to handle UDP-specific communication.
   - Opens a socket, sends packets, and receives data from the drone.
   - Updates the connection state and notifies `CrazyFlie` of changes via callbacks.

---

### **Concrete Example**

#### **1. Connecting to the Drone**
   - **`CrazyFlie.connect`**:
     - Calls `crtpDriver.connect(nil, callback:)` to establish the connection.
   - **`ESPUDPLink.connect`**:
     - Opens a UDP socket and starts listening for packets.
     - Calls the callback to notify success or failure.
   - **`CrazyFlie.onStateUpdated`**:
     - Receives state updates from `ESPUDPLink` and updates its internal state.

#### **2. Sending Flight Commands**
   - **`CrazyFlie.startTimer`**:
     - Sets up a periodic timer to send flight data every 0.05 seconds.
   - **`CrazyFlie.updateData`**:
     - Retrieves `roll`, `pitch`, `thrust`, and `yaw` values from the commander.
     - Passes the data to `sendFlightData`.
   - **`CrazyFlie.sendFlightData`**:
     - Prepares a `Data` packet and calls `crtpDriver.sendPacket`.
   - **`ESPUDPLink.sendPacket`**:
     - Sends the packet to the drone's UDP port.

#### **3. Disconnecting**
   - **`CrazyFlie.disconnect`**:
     - Stops the timer and calls `crtpDriver.disconnect`.
   - **`ESPUDPLink.disconnect`**:
     - Closes the UDP socket and cleans up resources.

---

### **Layered Structure**

| **Layer**            | **Component(s)**    | **Responsibility**                                  | **Details**                                                                                                        |
|-----------------------|---------------------|----------------------------------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Application Layer** | `CrazyFlie`         | High-level control, state management, and commands | Manages the drone connection and flight logic. Interacts with user input (e.g., joystick) and delegates transport. |
| **Protocol Layer**    | `CrtpDriver`        | Communication abstraction/interface                | Defines a generic interface for the transport layer (`connect`, `disconnect`, `sendPacket`). Ensures modularity.   |
| **Transport Layer**   | `ESPUDPLink`        | UDP-specific transport implementation              | Implements `CrtpDriver` for UDP. Handles network communication, sending/receiving packets over the drone's Wi-Fi.  |
| **Physical Layer**    | Wi-Fi (ESP-Drone)   | Physical medium for communication                  | Provides the actual connection between the app and the drone via ESP-Drone's Wi-Fi access point.                   |

---

### **Why This Design is Effective**

1. **Separation of Concerns**:
   - Each layer focuses on a specific task (e.g., control, protocol, transport).
2. **Extensibility**:
   - New transport mechanisms (e.g., BLE) can be added by implementing `CrtpDriver`.
3. **Reusability**:
   - The `CrazyFlie` logic remains unchanged regardless of the transport mechanism.
4. **Testability**:
   - You can test `CrazyFlie` independently by mocking `CrtpDriver`.

---

### **Visualization**

```plaintext
CrazyFlie
  └── Uses
       └── CrtpDriver (Protocol)
             └── Implemented By
                   └── ESPUDPLink
                         └── Communicates Via
                               └── UDP (192.168.43.42:2390)
```

---

### **In Summary**
- `CrazyFlie.swift`: High-level flight controller.
- `CrtpDriver.swift`: Protocol that defines the communication contract.
- `ESPUDPLink.swift`: UDP-based implementation of `CrtpDriver`.

## Data flow example: Increase thrust

When you increase the thrust, the data flow from the application (e.g., the joystick input) to the drone can be visualized as follows:

---

### **Data Flow for Thrust Increase**

1. **User Interaction (Input)**
   - The user interacts with the joystick (e.g., moves the thrust slider up).
   - The `BCJoystickViewModel` detects this change and updates its state.
2. **Application Layer (`CrazyFlie`)**
   - The `CrazyFlie` object retrieves the updated joystick values (thrust, pitch, roll, yaw) via the `BCJoystickViewModel`.
   - It prepares a `CommanderPacket` that encapsulates these values in a format the drone can understand.
3. **Protocol Layer (`CrtpDriver`)**
   - The `CrazyFlie` passes the `CommanderPacket` to the `sendPacket` method of the `CrtpDriver` interface.
   - The `CrtpDriver` abstracts the details of how the packet is sent, allowing flexibility (e.g., using UDP, BLE, etc.).
4. **Transport Layer (`ESPUDPLink`)**
   - The `ESPUDPLink` implements the `CrtpDriver` interface and sends the packet over UDP to the drone's Wi-Fi IP (`192.168.43.42`) and port (`2390`).
   - The packet is wrapped in a UDP datagram and sent to the drone.
5. **Physical Layer (Wi-Fi)**
   - The data is transmitted via the Wi-Fi connection to the drone's ESP32-based system.
6. **Drone Firmware**
   - The drone firmware receives the packet on its specified port (`2390`).
   - It decodes the `CommanderPacket` to extract thrust, pitch, roll, and yaw values.
   - The firmware adjusts the motor speeds accordingly to reflect the increased thrust.
7. **Drone Behavior**
   - The drone reacts physically to the command: it increases thrust, which might cause it to ascend or hover at a higher altitude depending on the overall control inputs.

---

### **Detailed Flow Visualization**

```plaintext
User Input (Joystick) --> BCJoystickViewModel (Thrust Value Updated)
    --> CrazyFlie (Prepare CommanderPacket) 
        --> CrtpDriver (Abstract Protocol Layer)
            --> ESPUDPLink (Send UDP Packet) 
                --> Wi-Fi (Physical Transmission)
                    --> Drone (Receive, Decode, Execute)
                        --> Drone Motors (Adjust Thrust)
```

---

### **Key Components in Action**

- **Joystick (`BCJoystickViewModel`)**: Captures and reports user input (e.g., thrust, roll, pitch).
- **`CrazyFlie`**: Prepares and sends a `CommanderPacket` based on joystick inputs.
- **`CrtpDriver`**: Provides a generic way to send packets (implemented by `ESPUDPLink`).
- **`ESPUDPLink`**: Handles UDP-specific details, like addressing and packet delivery.
- **Drone Firmware**: Executes commands to adjust motor speeds and perform maneuvers.

## `CommandPacket.h` and `CommandPacket.m`

These two files (`CommandPacket.h` and `CommandPacket.m`) play a **critical role** in defining and creating the data 
packets used for communicating flight commands (such as thrust, pitch, roll, and yaw) from the application to the drone.

---

### **Purpose of `CommanderPacket` Structure**
The `CommanderPacket` is a compact data structure representing a flight control command. It contains:

- **`header` (1 byte)**: Indicates the type of command (e.g., a flight command). For example, in `CrazyFlie.swift`, this is set to `0x30` (`CrazyFlieHeader.commander`).
- **`roll`, `pitch`, `yaw` (4 bytes each)**: Floating-point values for angular control.
- **`thrust` (2 bytes)**: A 16-bit unsigned integer representing the thrust level.

---

### **Key Responsibilities**

1. **`CommanderPacket` (Struct)**
   - Represents a single control command with all necessary data.
   - Is marked as `packed` to ensure no padding is added between fields, maintaining a predictable size.
2. **`CommandPacketCreator` (Objective-C Class)**
   - Converts a `CommanderPacket` structure into a `NSData` object, which can be transmitted via the communication stack.
   - This encapsulation ensures that the packet is in a format that is easy to send over UDP.

---

### **Data Flow Role**

1. **`CrazyFlie.swift`**
   - Prepares a `CommanderPacket` with user-provided values (e.g., thrust, pitch, roll, yaw).
   - Calls `CommandPacketCreator.data(from:)` to convert the struct into `NSData`.
2. **`CommandPacketCreator`**
   - Packs the `CommanderPacket` into a raw binary format (`NSData`).
   - The `NSData` object represents the exact bytes that will be sent to the drone.
3. **`ESPUDPLink`**
   - Transmits the raw `NSData` over UDP to the drone.
4. **Drone Firmware**
   - Receives the raw binary packet, unpacks it into a `CommanderPacket` (or equivalent structure), and applies the commands to control the motors and other systems.

---

### **Packet Format in Binary**

Each `CommanderPacket` generates a binary packet of fixed size:

- **1 byte**: `header`
- **12 bytes**: `roll` (4 bytes), `pitch` (4 bytes), `yaw` (4 bytes)
- **2 bytes**: `thrust`

**Total Size:** 15 bytes.

#### Example (Default Packet)
For the default data package:

```plaintext
header    roll      pitch     yaw       thrust
30000000  00000000  80000000  00000000  0000
```

---

### **How the Pieces Fit Together**

1. **Joystick Input**: User moves the joystick, which updates the `roll`, `pitch`, `yaw`, or `thrust`.
2. **`CrazyFlie`**:
   - Creates a `CommanderPacket` with the updated values.
   - Converts it to `NSData` using `CommandPacketCreator`.
3. **`ESPUDPLink`**: Sends the `NSData` over UDP to the drone.
4. **Drone Firmware**:
   - Parses the binary packet back into a `CommanderPacket`.
   - Uses the values to adjust motor speeds and orientations.

---

### **Detailed Flow Visualization**

```plaintext
User Input (Joystick) 
    --> BCJoystickViewModel (Processes Input for Roll, Pitch, Yaw, and Thrust) 
        --> CrazyFlie (Creates CommanderPacket with Updated Control Values)
            --> CommandPacketCreator (Converts CommanderPacket to NSData) 
                --> CrtpDriver (Abstract Protocol Layer)
                    --> ESPUDPLink (Transmits UDP Packet) 
                        --> Wi-Fi (Physical Transmission Layer) 
                            --> Drone (Receives and Decodes Packet)
                                --> Drone Firmware (Applies Commands)
                                    --> Drone Motors (Adjust Thrust, Roll, Pitch, and Yaw)
```

---

### **Notes**
- **`BCJoystickViewModel`**: Processes joystick movements and updates activation states.
- **`CrazyFlie`**: Bridges user control inputs to drone-specific commands.
- **`CommandPacketCreator`**: Encodes control commands for UDP transmission.
- **`ESPUDPLink`**: Handles transport layer operations for the drone.
- **Drone Firmware**: Unpacks the packet and applies control values to adjust motor behavior dynamically.

---

### **Summary**
The `CommandPacket.h` and `.m` files are the **bridge** between the high-level flight control logic in `CrazyFlie.swift` 
and the low-level communication protocols handled by `ESPUDPLink`. They ensure that control commands are accurately 
packaged and sent to the drone for execution.
