/*
 * Grot Serial Plotter Test Sketch
 * 
 * This sketch generates data series with space-containing labels
 * formatted for the Grot serial plotter.
 */

void setup() {
  Serial.begin(9600);
}

void loop() {
  // Get the current time in seconds
  float time = millis() / 1000.0;
  
  // Generate waveforms
  float sine = 100 * sin(time);
  float cosine = 100 * cos(time);
  float triangle = 100 * (2 * abs(2 * (time/2 - floor(time/2 + 0.5))) - 1);
  
  // Format: The label comes before the colon, followed by the value
  // Labels can contain spaces, and each label-value pair is separated by a space
  Serial.print("Room Temp:");
  Serial.print(sine);
  Serial.print(" ");
  
  Serial.print("Outside Temp:");
  Serial.print(cosine);
  Serial.print(" ");
  
  Serial.print("Humidity %:");
  Serial.println(triangle);
  
  delay(5);  // 50 Hz update rate
}