/* test FSR sketch */

char size = 6;
//int pins[] = {A0, A1, A2, A3, A4, A5};
int pin0 = A0;
int pin1 = A1;
int pin2 = A2;
int pin3 = A3;
int pin4 = A4;
int pin5 = A5;
char threshold = 500;
char inPin; 


int fsrReading; 
void setup() {
  pinMode(pin0, INPUT);
  pinMode(pin1, INPUT);
  pinMode(pin2, INPUT);
  pinMode(pin3, INPUT);
  pinMode(pin4, INPUT);
  pinMode(pin5, INPUT);
  
  Serial.begin(9600);
}

void loop() {
  // Read current position from Processing
  // In order for this to work,  
  //inPin = Serial.read();
  
  
  // Read analog values from analog pins
  for (int i = 0; i < size; i++) {
    /*
    if (i == inPin)
    
    
   fsrReading = analogRead(pins[i]);
  */ 
   fsrReading = 501;
   if (fsrReading > threshold) {
     Serial.print(i, BYTEM);
   }
  }
  
  delay(100);
}
