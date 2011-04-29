import processing.serial.*;

Serial myPort;  // The serial port

void setup() {
  myPort = new Serial(this, Serial.list()[2], 9600);
  println(Serial.list());
}

void draw() {
  while (myPort.available() > 0) {
    int inByte = myPort.read();
    println(inByte);
  }  
}
