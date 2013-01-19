/* 
 * A sound analyzer. Uses FFT algorithm to transform the signal in the time domain (sample buffer)
 * into a signal in the frequency domain (spectrum). Here, frequency and amplitude are returned.
 * BeatDetect analyzes an audio stream for beats (rhythmic onsets). This returns beats per minute.
 *
 * John Capogna, Brett Peterson, Maria Paula Saba
 * ITP, 2012
 */

import ddf.minim.*;
import ddf.minim.analysis.*;
import processing.serial.*;

Serial myport;
int lastRead = 2;

int platSpeed, armSpeed, armLen;

float startMillis = 0; // current time at playing

Boolean drawing = false;
Boolean donePlaying = false;

Minim minim;
AudioInput input;
FFT fft;
BeatDetect beat;
Boolean recording = false;
Boolean live = true; // Used to indicate whether or not we'll call spectrum() during the draw
AudioRecorder rec; // To record from mic
AudioPlayer recorded; // The recorded file
AudioMetaData metaData; // MetaData class for recorded audio

int beginTimer = 0;
float maxAmp = 0; // Maximum amplitude seen this sketch (Volume)
int maxPitch = 0; // Frequency band of the loudest frequency (~ Pitch)
int clipLen = 0;

byte[] vals = new byte[3];
Boolean received = false;

PFont font;

void setup() {
  size(900, 800);
  
  println(Serial.list());

  String portName = Serial.list()[4];
  myport = new Serial(this, portName, 9600);

  minim = new Minim(this);

  // Font stuff
  font = loadFont("Edmondsans-Bold-48.vlw");
  textFont(font, 20);


  // Record from internal mic
  input = minim.getLineIn(minim.STEREO, 512);

  // perform an FFT on the input that was previously saved.
  fft = new FFT(input.bufferSize(), input.sampleRate());

  // load the recorded audio clip. Placed here to avoid null pointer in draw
  recorded = minim.loadFile("test.wav", 512);
}

void draw() {
  background(0);


 
    // If the recorded clip isn't currently playing, show a live view of the spectrum
    if (!recorded.isPlaying()) {
      spectrum(input.mix);
      //beatsPerMinute();
    } 
    // If the recorded clip is playing, show the live view of the spectrum and analyze
    // It's done this way because the recorded clip must be playing when the fft is run.
    else {

      // Get the values of the freq bands
      float[] bands = spectrum(recorded.mix);

      // Run the analysis on the bands
      analyze(bands);

      // Print out the max values for pitch and volume, and the length of the clip
      //println("loudest pitch: "+maxPitch+" volume of pitch: "+maxAmp+" Length of clip: "+clipLen);
    }
    textAlign(CENTER);

    //Display text and symbol for whether or not recording
    if (recording) {
      fill(100);
      rect(width/2-20, height/2-20, 40, 40);
      text("Recording...Release button to stop", width/2, height/2-30);
    } 
    else if(donePlaying){
      fill(255, 0, 0);
      ellipse(width/2, height/2, 40, 40);
      text("Analyzing sound", width/2, height/2-30);      
    }
    else{
      fill(255, 0, 0);
      ellipse(width/2, height/2, 40, 40);
      text("Press red button to record", width/2, height/2-30); 
    
    }

  // DONE ANALYZING SOUND //
  // map values, send to Arduino
  if (donePlaying && millis() - clipLen > startMillis) {
    platSpeed = maxMin(0, 255, int(map(maxAmp, 5, 150, 0, 255)));
    armLen = maxMin(0, 255, int(map(clipLen, 0, 10000, 0, 255)));
    armSpeed = maxMin(0, 255, int(map(maxPitch, 1, 25, 0, 255)));
    
   
    drawing = true;
    donePlaying = false;
    println("platSpeed: "+platSpeed+" armLen: "+armLen+" armSpeed: "+armSpeed);

    vals[0] = byte(platSpeed);
    vals[1] = byte(armLen);
    vals[2] = byte(armSpeed);
    

    while (!received){
      myport.write(vals);
      println("sending...");
    }
  }
}

// Hold the red button to start recording
void serialEvent (Serial myport) {

  int serialInt = myport.read();
  println(serialInt);

  if (serialInt != 51){
    if (serialInt != lastRead) {
    
      if (!recording) {
        // Create a new audio recorder
        rec = minim.createRecorder(input, "test.wav", true);
        rec.beginRecord();     // Start recording
      } 
      else {

        rec.endRecord();    // Stop recording
        rec.save();    // Save recording

        // Load the recorded file into memory
        recorded = minim.loadFile("test.wav", 512);

        // Zero out the maxAmp and maxPitch for the next recording
        maxAmp = 0;
        maxPitch = 0;

        // Get the clip length
        clipLen = recorded.getMetaData().length();

        // Playback the recorded file. The clip must be playing when the FFT is run 
        recorded.play();

        // Start playing timer
        startMillis = millis();

        // perform a new FFT on the input that was previously saved.
        fft = new FFT(recorded.bufferSize(), recorded.sampleRate());

        // Toggle Done Playing switch
        donePlaying = true;
      }
    }
  }
  else {
    received = true;
  }
  recording = !recording; // Toggle state
  lastRead = serialInt;
}

void stop() {
  // always close Minim audio classes when you are finished with them
  input.close();
  // always stop Minim before exiting
  minim.stop();
  super.stop();
}

// Function to actually restrict the values to be within a max an min for each
int maxMin(int minimum, int maximum, int value){
  int val;

  // Check the max
  if (value > maximum){
    val = maximum;
  }
  // Check the min
  else if (value < minimum){
    val = minimum;
  }
  // Otherwise, just return the value
  else {
    val = value;
  }
  return val;
}

