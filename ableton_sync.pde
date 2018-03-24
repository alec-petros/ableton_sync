import themidibus.*; //Import the library

MidiBus myBus; // The MidiBus
OPC opc;

int transp = 0;
int decay = 3;
int drumDecay = 15;
int[] note = new int[128];
int[] drum = new int[128];
float tempX = 0;
float tempY = 0;
int glideRate = 1;
int glideAlpha = 0;

void setup() {
  size(800, 300, P3D);
  frameRate(30);

  opc = new OPC(this, "fade.local", 7890);
  opc.ledStrip(0 * 31, 31, width * 0.5, height * 0/8 + height * 1/16, width / 32, 0, false);
  opc.ledStrip(1 * 31, 31, width * 0.5, height * 1/8 + height * 1/16, width / 32, 0, true);
  opc.ledStrip(2 * 31, 31, width * 0.5, height * 2/8 + height * 1/16, width / 32, 0, false);
  opc.ledStrip(3 * 31, 31, width * 0.5, height * 3/8 + height * 1/16, width / 32, 0, true);
  opc.ledStrip(4 * 31, 31, width * 0.5, height * 4/8 + height * 1/16, width / 32, 0, false);
  opc.ledStrip(5 * 31, 31, width * 0.5, height * 5/8 + height * 1/16, width / 32, 0, true);
  opc.ledStrip(6 * 31, 30, width * 0.5, height * 6/8 + height * 1/16, width / 32, 0, false);
  opc.ledStrip(7 * 31 - 1, 30, width * 0.5, height * 7/8 + height * 1/16, width / 32, 0, true);

  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.

  // Either you can
  //                   Parent In Out
  //                     |    |  |
  //myBus = new MidiBus(this, 0, 1); // Create a new MidiBus using the device index to select the Midi input and output devices respectively.

  // or you can ...
  //                   Parent         In                   Out
  //                     |            |                     |
  //myBus = new MidiBus(this, "IncomingDeviceName", "OutgoingDeviceName"); // Create a new MidiBus using the device names to select the Midi input and output devices respectively.

  // or for testing you could ...
  //                 Parent  In        Out
  //                   |     |          |
  myBus = new MidiBus(this, "Bus 1", "Bus 2"); // Create a new MidiBus with no input device and the default Java Sound Synthesizer as the output device.
}

void draw() {
  background(0);
  int channel = 0;
  pushMatrix();
  translate(width/2, height/2);

  int number = 0;
  int value = 90;

  transp = max(0, transp - decay);
  glideAlpha = max(0, glideAlpha -= decay);

  for (int i = 0; i < 128; i++) {
    note[i] = max(0, note[i] - decay);
    drum[i] = max(0, drum[i] - drumDecay);
    if (i < 64 && note[i] > 0) {
      fill((i * 2), 255, 255, note[i] * 3);
      noStroke();
      ellipse(map(i % 8, 0, 7, -width/3, width/3), map(i / 8, 0, 7, -height/3, height/3),80,80);
    }
    if (note[i] > 80 && i > 63) {
      glideAlpha = 80;
      for (int n = 0; n < glideRate; n++) {
        tempX = (tempX + map(i % 8, 0, 8, -width/3, width/3)) / 2;
        tempY = (tempY + map(i / 8, 7, 15, -height/3, height/3)) / 2;
      }
    }
    fill(255, 255, 255, glideAlpha);
    ellipse(tempX, tempY, 80, 80);
    if (i == 0) {
      fill(255, 255, 255, drum[i] * 2);
      rect(-width/2, height/2, width, -map(drum[i], 0, 128, 0, height/2));
    }
    if (i == 1) {
      fill(255, 255, 255, drum[i] * 2);
      rect(-width/2, -height/2, width, height);
    }
    if (i == 2) {
      note[i] -= drumDecay;
      fill(255, 255, 255, drum[i] * 2);
      ellipse(map(sin(frameCount), -1, 1, -width/2, width/2), 0, 100, 100);
    }
  }

  myBus.sendControllerChange(channel, number, value); // Send a controllerChange
  popMatrix();
  // filter(BLUR, 4);
}

void noteOn(int channel, int pitch, int velocity) {
  // Receive a noteOn
  // ellipse(0, 0, height, width);
  println();
  println("Note On:");
  println("--------");
  println("Channel:"+channel);
  println("Pitch:"+pitch);
  println("Velocity:"+velocity);
  if (channel == 0) {
    note[pitch] = velocity;
  }
  if (channel == 1) {
    drum[pitch] = velocity;
  }
  // transp = velocity;
}

// void noteOff(int channel, int pitch, int velocity) {
//   // Receive a noteOff
//   println();
//   println("Note Off:");
//   println("--------");
//   println("Channel:"+channel);
//   println("Pitch:"+pitch);
//   println("Velocity:"+velocity);
// }
//
// void controllerChange(int channel, int number, int value) {
//   // Receive a controllerChange
//   println();
//   println("Controller Change:");
//   println("--------");
//   println("Channel:"+channel);
//   println("Number:"+number);
//   println("Value:"+value);
// }

void delay(int time) {
  int current = millis();
  while (millis () < current+time) Thread.yield();
}
