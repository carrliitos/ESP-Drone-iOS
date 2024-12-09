# Command Generation Example: Thrust Increase/Decrease

The process of command generation from user input (e.g., moving the thrust slider) involves the following components:

## **Command Generation Workflow**

1. **User Input (BCJoystick)**:
   - The `BCJoystick` class detects user interaction with the on-screen joystick.
   - It tracks the movement of the joystick handle and calculates normalized `x` and `y` values.
   - These values are passed to the corresponding `BCJoystickViewModel` using methods like `touchesBegan`, `touchesMoved`, and `touchesEnded`.

2. **Processing by `BCJoystickViewModel`**:
   - The `BCJoystickViewModel` handles the logic for deadbanding and normalizing joystick inputs.
   - It applies transformations (e.g., adjusting for thrust-specific behaviors) and updates `x` and `y` values accordingly.
   - Once processed, it notifies observers like the `ViewModel`.

3. **Integration in `ViewModel`**:
   - The `ViewModel` receives joystick updates via its observer interface (`BCJoystickViewModelObserver`).
   - It maps joystick inputs to the appropriate control mode and sensitivity settings.
   - It creates a `CommanderPacket` structure using the processed values for roll, pitch, yaw, and thrust.

4. **CrazyFlie Modes and Command Processing**:
   - Using `CrazyFlieModes`, the `SimpleCrazyFlieCommander` processes joystick inputs into final control values:
     - Inputs for `pitch`, `roll`, `yaw`, and `thrust` are processed through scaling (linear or nonlinear) and boundary constraints.
     - Constants like `LINEAR_PR` and `LINEAR_THRUST` determine whether inputs use linear or nonlinear scaling.
     - Processed values are stored in `BoundsValue` structs for each parameter.

5. **Packet Creation (`CommandPacket`)**:
   - The `CommanderPacket` is packed into binary data using the `CommandPacketCreator`.
   - The resulting binary data represents a CRTP-compatible command packet.

6. **Transmission**:
   - The `CrazyFlie` instance sends the binary packet via its protocol (`CrtpDriver`) and transport layer (`ESPUDPLink`).
   - The `ESPUDPLink` sends the packet over UDP to the drone.

7. **Execution on the Drone**:
   - The drone decodes the received CRTP packet and applies the commanded thrust, roll, pitch, and yaw values to adjust motor speeds.

## **Key Components for Command Generation**

- **BCJoystick**: Captures raw user inputs from the UI.
- **BCJoystickViewModel**: Processes and normalizes joystick inputs.
- **CrazyFlieModes**: Handles input scaling and boundary constraints using `SimpleCrazyFlieCommander`.
- **ViewModel**: Coordinates settings and creates the command packet.
- **CommanderPacket**: Converts structured commands into binary CRTP data.
- **CrazyFlie & CrtpDriver**: Manages communication and sends data to the drone.
- **ESPUDPLink**: Implements UDP transport for sending packets.

## **Command Generation Workflow Visualization**

```plaintext
User Input (Joystick Movement) 
    --> BCJoystick (Detect Input & Calculate x/y Positions)
        --> BCJoystickViewModel (Normalize & Deadband x/y Positions)
            --> CrazyFlieModes (CrazyFlieDataProvider)
                --> SimpleCrazyFlieCommander (Process Input & Generate Command Values)
                    --> CommandPacket (Create CRTP Binary Packet)
                        --> CrazyFlie (Transmit Packet via CrtpDriver)
                            --> CrtpDriver (Abstract Protocol for Data Transmission)
                                --> ESPUDPLink (Send Packet over UDP)
                                    --> Drone (Decode CRTP Packet)
                                        --> Drone Motors (Adjust Thrust/Roll/Pitch/Yaw)
```

### **Explanation**

1. **User Input**: The user interacts with the joystick, moving it to specific positions.
2. **BCJoystick**: Converts raw touch positions into normalized `x` and `y` values.
3. **BCJoystickViewModel**: Applies deadband and further processing to refine the input.
4. **CrazyFlieModes**: Uses `SimpleCrazyFlieCommander` to process the joystick inputs based on settings and scaling factors.
5. **ViewModel**: Maps the processed joystick inputs to the corresponding fields (`roll`, `pitch`, `yaw`, `thrust`) in a `CommanderPacket`.
6. **CommandPacket**: Converts the structured `CommanderPacket` into a binary CRTP-compliant format.
7. **CrazyFlie**: Sends the packet using the `CrtpDriver`.
8. **CrtpDriver**: Abstracts the protocol and delegates transport to `ESPUDPLink`.
9. **ESPUDPLink**: Implements UDP-based transport and sends the CRTP packet to the drone.
10. **Drone**: Decodes the received CRTP packet and executes the commands by adjusting motor parameters.
