
/*
Drawing machine code - Brett Peterson, John Capogna, Maria Paula Saba dos Reis

This sketch runs our drawing machine for Tom Igoe's Physical Computing class (Fall '12).
There is a spinning circuar platform powered by a stepper motor, above which runs a carriage similar
to a printer head which holds a motor to rotate a pen.

 Stepper code adapted from Stepper Motor Control by Tom Igoe
 gear motor code adapted from http://bildr.org/2012/04/tb6612fng-arduino/ 

Circuit notes:

TODO: INSERT LINK TO FRITZING DIAGRAM

-2 Stepper motors to control the rotation of the platform and the position of the drawing carriage
  -Stepper motors are controlled by dual H-Bridge (TODO: INSERT PART NUMBER)

-1 small gear motor to rotate the pen
  -Gear motor is controlled by an additional dual H-Bridge

- for buttons, 10k ohm voltage divider, button has one lead going to power,
  the other to the digital input and ground with resistor
 */

#include <Stepper.h>
#include <Bounce.h>


// STEPPER MOTOR SETUP  //
const int stepsPerRevolution = 64;  // steps per revolution.

// initialize the stepper library on pins 8 through 11: Arm movement motor
Stepper platStepper(stepsPerRevolution, 8,9,10,11);

// initialize the stepper library on pins 4 through 7: Platform rotation motor
Stepper armStepper(stepsPerRevolution, 4,5,6,7);    

int stepCount = 0;         // number of steps the motor has taken

// GEAR MOTOR SETUP   //
const int STBY = 2; // Standby

// Arm rotation motor
const int pwma = 3; //Speed control 
const int ain1 = 12; //Direction
const int ain2 = 13; //Direction

// Buttons
const int gb = A5; //green button pin
const int rb = A4; //blue button pin

Bounce bouncer = Bounce(rb,5);

// LEDs
const int recLED = A0; // recording light
const int readyLED = A1; // ready light
const int drawingLED = A2; // drawig light


// Variables from Sketch to draw
int platSpeed = 0;  // platform speed
int armLen = 0;    // arm length movement
int armRotation = 0; // arm rotation speed

boolean ready = false; // toggle for when the data has been received from the sketch, ready to draw
boolean drawPressed = false;
boolean drawing = false; // Is the machine currently drawing?

int lastState = 0; //used to check for button presses
long lastDebounce;
long debounceDelay = 50;


void setup() {
  // initialize the serial port:
  Serial.begin(9600);

  pinMode(STBY, OUTPUT);

  pinMode(pwma, OUTPUT);
  pinMode(ain1, OUTPUT);
  pinMode(ain2, OUTPUT);

  pinMode(gb, INPUT);
  pinMode(rb, INPUT);

  pinMode(recLED, OUTPUT);
  pinMode(readyLED, OUTPUT);
  pinMode(drawingLED, OUTPUT);

  // Set initial stepper speed
  armStepper.setSpeed(200);   
}

void loop() {

////////// RECORDING //////////

  // Check If the red button is pressed, send command to start recording
  if (bouncer.update()){ // if different from last time around, means pressed or released

    Serial.print(buttonState); // Send the recording command to the soundAnalyzer sketch
    lastState = buttonState;
  }
 
// turn on and off the recording LED when button is held
  if (buttonState == 1){
    digitalWrite(recLED, HIGH);
  }
  else {
   digitalWrite(recLED, LOW); 
  }

////////// RECEIVING DATA //////////

  if (!ready){
   while (Serial.available() > 3){    // check for the 3 vars in the buffer, don't read if not 3
      for (int i = 0; i < 3; i++){

        // assign the variables
        switch (i){
          case 0:
            platSpeed = maxMin(200, 400, int(Serial.read()));
            break;
          case 1:
            armLen = maxMin(1, 30, int(Serial.read()));
            break;
          case 2:
            armRotation = maxMin(100, 250, int(Serial.read()));
            break;
          // if something weird happens, set to 0  
          // default: 
          //   platSpeed = 0;
          //   armLen = 0;
          //   armRotation = 0;
        }
      }
      // Send the ACK that the machine received the message
      Serial.print("3");
      // turn on the ready light
      digitalWrite(readyLED, HIGH);
      ready = true;
    }
  } 

 // Check If the Green button is pressed set the drawPressed var to true
  int drawButtonState = digitalRead(gb);
  delay(5); // Debounce
  int drawButtonState2 = digitalRead(gb);

  if (drawButtonState == drawButtonState2 && drawButtonState == HIGH){
    drawPressed = true;
  }

////////// DRAWING //////////

  // If the green button is pressed and the data has been received, move arm into position
  if (ready && drawPressed) {

    // Move the arm into position
    armStepper.step(500);

    // Set the platform speed
    platStepper.setSpeed(platSpeed); 

    // Toggle ready and drawing state
    ready = false;
    drawPressed = false;
    drawing = true;    

    digitalWrite(readyLED, LOW); // Turn off the ready LED
  }

  // Once the arm is in place, start drawing!
  if (drawing){

    digitalWrite(drawingLED,HIGH); // Turn on the drawing LED
    platStepper.step(5); // rotate the platform
    move(1, armRotation);  // move arm motor

  } else {
    digitalWrite(drawingLED,LOW); // Turn off the drawing LED
    stop(); // Stop arm rotation
  }
}

// Move the arm rotation motor,
// Given the direction and speed
void move(int dir, int speeda){

  // write using PWM to affect speed
  analogWrite(pwma, speeda);

  // set direction for the arm motor
  if (dir == 1){
    digitalWrite(ain1, HIGH);
    digitalWrite(ain2, LOW);
  }
  else 
  {
    digitalWrite(ain1, LOW);
    digitalWrite(ain2, HIGH); 
  }
}

// Stop the arm rotation motor
void stop(){
  digitalWrite(ain1, LOW);
  digitalWrite(ain2, LOW);
  digitalWrite(pwma, LOW);  
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