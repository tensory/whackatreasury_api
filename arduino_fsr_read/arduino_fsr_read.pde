/* test FSR sketch */

int size = 6;
int pins[] = {A0, A1, A2, A3, A4, A5};
int threshold = 500;

int fsrReading; 
void setup() {
  for (int i = 0; i < size; i++) {
    pinMode(pins[i], INPUT);
  }
  Serial.begin(9600);
}

void loop() {
  for (int i = 0; i < max; i++) {
   fsrReading = analogRead(pins[i]);
   if (fsrReading > threshold) {
     Serial.print(i, BYTE);   
   }
  }
  delay(100);
}
