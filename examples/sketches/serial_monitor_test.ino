/*
 * Grot Serial Monitor Test Sketch
 * 
 * This sketch generates data for testing the Grot serial monitor
 * and listens for incoming messages, responding with a confirmation.
 */

// Timing variables
unsigned long lastSendTime = 0;
const unsigned long sendInterval = 1000; // 1 second

void setup() {
  Serial.begin(9600);
}

void loop() {
  // Generate and send test data at regular intervals
  unsigned long currentTime = millis();
  if (currentTime - lastSendTime >= sendInterval) {
    // Generate data
    float sine = 100 * sin(currentTime / 1000.0);
    float cosine = 100 * cos(currentTime / 1000.0);

    // Send to serial monitor
    Serial.print(sine);
    Serial.print(" ");
    Serial.println(cosine);
    
    lastSendTime = currentTime;
  }
  
  // Check if data is available to read
  if (Serial.available() > 0) {
    // Read the incoming message
    String receivedMessage = Serial.readStringUntil('\n');
    
    // Send confirmation message
    Serial.println("Message received by Arduino: " + receivedMessage);
  }
}