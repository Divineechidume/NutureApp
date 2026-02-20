#include <ArduinoBLE.h>
BLEService countService("1101");
BLEUnsignedCharCharacteristic countLevelChar("2101", BLERead | BLENotify);

void setup() {
Serial.begin(9600);
while (!Serial);

pinMode(LED_BUILTIN, OUTPUT);
if (!BLE.begin()) 
{
Serial.println("starting BLE failed!");
while (1);
}

BLE.setLocalName("CountService");
BLE.setAdvertisedService(countService);
countService.addCharacteristic(countLevelChar);
BLE.addService(countService);

BLE.advertise();
Serial.println("Bluetooth device active, waiting for connections...");
}

void loop() 
{
BLEDevice central = BLE.central();

if (central) 
{
Serial.print("Connected to central: ");
Serial.println(central.address());
digitalWrite(LED_BUILTIN, HIGH);
int broadcast = 0;
while (central.connected()) {
      Serial.print("Broadcast: ");
      Serial.println(broadcast);
      countLevelChar.writeValue(broadcast);
      delay(500);
      broadcast += 1;

}
}
digitalWrite(LED_BUILTIN, LOW);
Serial.print("Disconnected from central: ");
Serial.println(central.address());
}