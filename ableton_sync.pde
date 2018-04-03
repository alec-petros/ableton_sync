import themidibus.*; //Import the library
import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioInput input;
FFT fft;
MidiBus myBus; // The MidiBus
OPC opc;

float transp = 0;
float decay = 0.1;
float drumDecay = 0.1;
float[] note = new float[128];
float[] drum = new float[128];
float[] cc = new float[256];
float tempX = 0;
float tempY = 0;
int glideRate = 1;
int glideAlpha = 0;

void setup() {
  size(800, 300, P3D);
  frameRate(30);

  minim = new Minim(this);
  input = minim.getLineIn(minim.MONO, 2048);
  fft = new FFT(input.bufferSize(), input.sampleRate());
  fft.logAverages(40, 1);

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
  myBus = new MidiBus(this, "Bus 1", "Bus 1"); // Create a new MidiBus with no input device and the default Java Sound Synthesizer as the output device.
}

void draw() {
  background(0);
  int channel = 0;
  pushMatrix();
  translate(width/2, height/2);

  int number = 0;
  int value = 90;

  fft.forward(input.mix);

  // FFT Analysis
  for(int i = 0; i < 8; i++)
  {
    println(fft.getAvg(i));
    strokeWeight(10);
    stroke(255);
    line(-width/2, height/8 * (7-i) - height/2 + height/16, map(fft.getAvg(i), 0, 120, 0, width/2) - width/2, height/8 * (7-i) - height/2 + height/16);
    line(width/2, height/8 * (7-i) - height/2 + height/16, map(fft.getAvg(i), 0, 120, 0, -width/2) + width/2, height/8 * (7-i) - height/2 + height/16);
  }
  // println("--");
  noStroke();
  // decay = cc[7];

  transp = max(0, transp - decay*255);
  glideAlpha = max(0, glideAlpha -= decay);

  for (int i = 0; i < 128; i++) {

    note[i] = max(0, note[i] - decay);
    drum[i] = max(0, drum[i] - drumDecay);
    if (i < 64 && note[i] > 0) {
      fill(cc[0]*255, cc[1]*255, cc[2]*255, note[i]*255);
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
      fill(255, 255, 255, drum[i] * 255);
      rect(-width/2, height/2, width, -drum[i]*height/2);
    }
    if (i == 1) {
      fill(255, 255, 255, drum[i] * 255);
      rect(-width/2, -height/2, width, height);
    }
    if (i == 2) {
      note[i] -= drumDecay;
      fill(255, 255, 255, drum[i] * 255);
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
  //println();
  //println("Note On:");
  //println("--------");
  //println("Channel:"+channel);
  //println("Pitch:"+pitch);
  //println("Velocity:"+velocity);
  if (channel == 0) {
    note[pitch] = map(velocity, 0, 127, 0, 1);
  }
  if (channel == 1) {
    drum[pitch] = map(velocity, 0, 127, 0, 1);
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
 void controllerChange(int channel, int number, int value) {
   // Receive a controllerChange
   //println();
   //println("Controller Change:");
   //println("--------");
   //println("Channel:"+channel);
   //println("Number:"+number);
   //println("Value:"+value);
   cc[number] = map(value, 0, 127, 0, 1);
 }

void delay(int time) {
  int current = millis();
  while (millis () < current+time) Thread.yield();
}
