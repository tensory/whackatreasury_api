/* Whack-a-Treasury 
  by Ari Lacenski */
int sigPin = 2;
int outputPin = 7;
int selectedPad = 0;
int bitMasks[6] = {
  B00000000,
  B00000001,
  B00000010,
  B00000011,
  B00000100,
  B00000101
};
int lightPins[4] = {3,4,5,6};
void setup() {
  for (int pinNum = 2; pinNum < 12; pinNum++) {
    pinMode(pinNum, OUTPUT);
    digitalWrite(pinNum, LOW);
  }
  digitalWrite(outputPin, LOW);
  Serial.begin(9600);
}

void loop() {
  for (int analogIn = 0; analogIn < 6; analogIn++) {
    int val = readChannel(analogIn); // value of sampled pin
    if (val > -1) {
      Serial.print(val, BYTE); // write pin number
    }
  } // code works up to here
  
  if (Serial.available() > 0) {
    selectedPad = Serial.read();
    if (selectedPad >= 0 && selectedPad < 6) {
      muxSetLights(selectedPad);
      digitalWrite(outputPin, HIGH);
    } else if (selectedPad == 9) {
      for(int i = 0; i < 6; i++) {
        muxSetLights(i+1);
        digitalWrite(outputPin, HIGH);
        delay(75);
        digitalWrite(outputPin, LOW);
        delay(75);   
      }
    } else {
      digitalWrite(outputPin, LOW);
    }
  }
}

int readChannel(int analogPin) {
  PORTB = bitMasks[analogPin]; // set pin
  // read value
  int val = analogRead(sigPin);
  
  if (val > 250) {
    return analogPin;
  } else {
    return -1;
  }
}

void muxSetLights(int lightPin) {
  for (int thisPin = 0; thisPin < 4; thisPin++) {
    int pinState = bitRead(lightPin, thisPin);
    digitalWrite(lightPins[thisPin], pinState);
  }
}


