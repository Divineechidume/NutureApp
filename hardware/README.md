# Nurture Band — Hardware Firmware

Firmware for the Nurture ankle wearable (foot band). Streams tilt angle over Bluetooth Low Energy for sleep tracking and rollover detection. The iOS app connects to the band and uses this data for real-time status and safety alerts (PRD §2, §4).

## Board

- **Arduino Nano 33 BLE Sense** (nRF52840, BMI270 accelerometer)

## BLE Protocol

| Property            | Value                          |
| ------------------- | ------------------------------ |
| Local name          | `Nurture`                       |
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

## Security

At MVP, the BLE link is **unencrypted**. The band advertises and streams angle data without authentication or encryption. This is acceptable for private beta; we plan to add LE Secure Connections and bonding before public launch.

### Attack Scenarios to Address Later

When we implement encryption and secure pairing, we need to mitigate:

1. **Eavesdropping** — Nearby devices can sniff angle and movement data, inferring sleep patterns and when the home is occupied. _Mitigation: Encrypted link (LE Secure Connections)._

2. **Impersonation / spoofed device** — A fake "Nurture" peripheral could pair with the parent's phone, sending false angle values. This could suppress real rollover alerts or trigger false alarms. _Mitigation: Authenticated pairing (passkey or numeric comparison), bonding._

3. **Replay attacks** — Captured BLE packets could be replayed to mask a real rollover with "safe" data, or trigger repeated false rollover alerts. _Mitigation: Encrypted link prevents meaningful replay._

4. **Unauthorized pairing** — Any phone in range can connect if it scans for our service UUID. Parent may be unable to connect; data could be read by others. _Mitigation: Bonding and whitelisting; only previously paired centrals can reconnect._

5. **Man-in-the-middle** — Without link encryption, data could be intercepted or altered in transit. _Mitigation: LE Secure Connections._

6. **Connection hijacking** — Unencrypted session could allow injection of fake angle values to suppress or trigger alerts. _Mitigation: Encrypted link and authentication._

MVP: read/notify only on the angle characteristic (no writes from phone to band).
