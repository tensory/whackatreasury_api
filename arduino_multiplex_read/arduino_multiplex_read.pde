/* Whack-a-Treasury 
  by Ari Lacenski */
char sigPin = 2;
char outputPin = 7;
char ledPin = 13;
int bitMasks[6] = {
  B00000000,
  B00000001,
  B00000010,
  B00000011,
  B00000100,
  B00000101
};

void setup() {
  for (int pinNum = 8; pinNum < 12; pinNum++) {
    pinMode(pinNum, OUTPUT);
    digitalWrite(pinNum, LOW);
  }
  pinMode(sigPin, OUTPUT);
  pinMode(outputPin, OUTPUT);
  pinMode(ledPin, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  for (int analogIn = 0; analogIn < 6; analogIn++) {
    int val = readChannel(analogIn); // value of sampled pin
    if (val > -1) {
      Serial.print(val, BYTE); // write pin number
    }
    
    if (Serial.available() > 0) {
      int selected = Serial.read();  
      Serial.println(selected);
      if (selected >= -1 && selected < 6) { // if input between 0-5 inc0
        // select relevant pins on D-set
        PORTD = selected << 3;
        digitalWrite(outputPin, HIGH);
        digitalWrite(ledPin, HIGH);
          delay(50);
          digitalWrite(ledPin, LOW);
          delay(50);
      } else if (selected == 9) { // WINNING
        for(int i=0; i<6; i++) {
          PORTD = i << 3; 
          digitalWrite(outputPin, HIGH);
          delay(50);
          digitalWrite(outputPin, LOW);
          delay(50);
        }
      } else {
        digitalWrite(outputPin, LOW);
      }
    }
  } // end if serial
}

int readChannel(int analogPin) {
  PORTB = bitMasks[analogPin]; // set pin
  // read value
  int val = analogRead(sigPin);
  if (val > 300) {
    return analogPin;
  } else {
    return -1;
  }
}
