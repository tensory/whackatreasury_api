/* test FSR sketch */

char size = 6;
int pins[] = {A0, A1, A2, A3, A4, A5};
char threshold = 500;
char inPin; 


int fsrReading; 
void setup() {
  for (char i = 0; i < size; i++) {
    pinMode(pins[i], INPUT);
  }
  Serial.begin(9600);
}

void loop() {
  // Read current position from Processing
  // In order for this to work,  
  inPin = Serial.read();
  
  /*
  // Read analog values from analog pins
  for (char i = 0; i < size; i++) {
    /*
    if (i == inPin)
    
    
   fsrReading = analogRead(pins[i]);
   if (fsrReading > threshold) {
     Serial.print(i, BYTE);   
   }
  }
  */
  
  delay(100);
}
