#include "Arduino_BMI270_BMM150.h"
#include <math.h>

float angle = 0.0;
float angleBuffer[5] = {0, 0, 0, 0, 0};
int bufferIndex = 0;

float runningAverage() {
  float sum = 0;
  for (int i = 0; i < 5; i++) {
    sum += angleBuffer[i];
  }
  return sum / 5.0;
}

void setup() {
  Serial.begin(9600);
  while (!Serial);
  pinMode(LED_BUILTIN, OUTPUT); 

  if (!IMU.begin()) {
    Serial.println("Failed to initialize IMU!");
    while (1);
  }

  Serial.println("Angle (degrees)");
}

void loop() {
  float x, y, z;

  if (IMU.accelerationAvailable()) {
    IMU.readAcceleration(x, y, z);

    float resultant = sqrt(x * x + y * y + z * z);
    angleBuffer[bufferIndex] = acos(z / resultant) * 180.0 / PI;
    bufferIndex = (bufferIndex + 1) % 5;
    angle = runningAverage();

    Serial.print("Angle:");
    Serial.println(angle);
    if (angle > 140) {
      Serial.println("!!! BOARD FLIPPED !!!");
      digitalWrite(LED_BUILTIN, HIGH);
      delay(100);
      digitalWrite(LED_BUILTIN, LOW);
    } else {
    }
    delay(100);
  }
}