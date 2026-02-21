# Nurture Band — Hardware Firmware

Firmware for the Nurture ankle wearable (foot band). Streams tilt angle over Bluetooth Low Energy for sleep tracking and rollover detection. The iOS app connects to the band and uses this data for real-time status and safety alerts (PRD §2, §4).

## Board

- **Arduino Nano 33 BLE Sense** (nRF52840, BMI270 accelerometer)

## BLE Protocol

| Property            | Value                          |
| ------------------- | ------------------------------ |
| Local name          | `Nuture`                       |
| Service UUID        | `1101`                         |
| Characteristic UUID | `2101` (Read, Notify)          |
| Angle value         | 0–180 degrees, sent as `uint8` |

The iOS app’s `BluetoothService` should filter scan results by service UUID `1101` when pairing.

## Libraries

- **ArduinoBLE** — BLE peripheral
- **Arduino_BMI270_BMM150** — IMU (accelerometer)

Install via Arduino IDE: **Sketch → Include Library → Manage Libraries** and search for each.

## Flashing

1. Open `nurture_band/nurture_band.ino` in Arduino IDE 2.x.
2. **Tools → Board** → Arduino Nano 33 BLE.
3. **Tools → Port** → Select the Nano’s serial port.
4. Click **Upload**.

## Prototypes

The `prototypes/` folder contains earlier sketches used during development:

- `bluetooth_broadcast/` — BLE-only test (counter broadcast)
- `SimpleAccelerometer/` — IMU-only test (angle + LED on flip)

Production firmware is in `nurture_band/`, which merges BLE and accelerometer behavior.
