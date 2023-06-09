#define TRIGGER_PIN_1 2
#define ECHO_PIN_1 3
#define TRIGGER_PIN_2 4
#define ECHO_PIN_2 5


int enterCount = 0;
int exitCount = 0;
int peopleCount = 0;
bool sensor1State = false;
bool sensor2State = false;
bool prevSensor1State = false;
bool prevSensor2State = false;
unsigned long sensorDeactivationTime = 0;
int sensorPin = A1;
float sensorValue;

void setup() {
  Serial.begin(9600);
  pinMode(TRIGGER_PIN_1, OUTPUT);
  pinMode(ECHO_PIN_1, INPUT);
  pinMode(TRIGGER_PIN_2, OUTPUT);
  pinMode(ECHO_PIN_2, INPUT);

  for (int i = 6; i < 13; i++) {
    pinMode(i, OUTPUT);
  }
}

void loop() {
  
  if (millis() - sensorDeactivationTime >= 3000) {
   
    digitalWrite(TRIGGER_PIN_1, LOW);
    digitalWrite(TRIGGER_PIN_2, LOW);
  }


  int distance1 = measureDistance(TRIGGER_PIN_1, ECHO_PIN_1);
  int distance2 = measureDistance(TRIGGER_PIN_2, ECHO_PIN_2);


  if (distance1 < 30) {
    sensor1State = true;
  } else {
    sensor1State = false;
  }

  if (distance2 < 30) {  
    sensor2State = true;
  } else {
    sensor2State = false;
  }

 
  if (sensor1State && !prevSensor1State && !prevSensor2State) {
    enterCount++;
    
    activateLEDs();
  
    digitalWrite(TRIGGER_PIN_2, HIGH);
    sensorDeactivationTime = millis();
  }

  if (sensor2State && !prevSensor2State && !prevSensor1State) {
    exitCount++;
    
    activateLEDs();
   
    digitalWrite(TRIGGER_PIN_1, HIGH);
    sensorDeactivationTime = millis();
  }

  prevSensor1State = sensor1State;
  prevSensor2State = sensor2State;



  peopleCount= enterCount - exitCount;

  if(peopleCount < 0){
    exitCount--;
    peopleCount = 0;
  }

  sensorValue = analogRead (sensorPin);


  
  Serial.print("peopleCount:");
  Serial.print(peopleCount);
  Serial.print(",sensorValue:");
  Serial.println(sensorValue);
  

  delay(500);
}

int measureDistance(int triggerPin, int echoPin) {
  digitalWrite(triggerPin, LOW);
  delayMicroseconds(2);
  digitalWrite(triggerPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(triggerPin, LOW);

  int duration = pulseIn(echoPin, HIGH);
  int distance = duration * 0.034 / 2; 
  return distance;
}

void activateLEDs() {

  int dilay= 100;
  
    digitalWrite(6, HIGH);
    delay(dilay);
    digitalWrite(8, HIGH);
    delay(dilay);
    digitalWrite(10, HIGH);
    delay(dilay);
    digitalWrite(12, HIGH);
    delay(dilay);
    digitalWrite(11, HIGH);
    digitalWrite(6, LOW);
    delay(dilay);
    digitalWrite(9, HIGH);
    digitalWrite(8, LOW);
    delay(dilay);
    digitalWrite(7, HIGH);
    digitalWrite(10, LOW);
    delay(dilay);
    digitalWrite(6, HIGH);
    digitalWrite(12, LOW);
    delay(dilay);
    digitalWrite(8, HIGH);
    digitalWrite(11, LOW);
    delay(dilay);
    digitalWrite(10, HIGH);
    digitalWrite(9, LOW);
    delay(dilay);
    digitalWrite(12, HIGH);
    digitalWrite(7, LOW);
    delay(dilay);
    digitalWrite(11, HIGH);
    digitalWrite(6, LOW);
    delay(dilay);
    digitalWrite(9, HIGH);
    digitalWrite(8, LOW);
    delay(dilay);
    digitalWrite(7, HIGH);
    digitalWrite(10, LOW);
    delay(dilay);
    digitalWrite(12, LOW);
    delay(dilay);
    digitalWrite(11, LOW);
    delay(dilay);
    digitalWrite(9, LOW);
    delay(dilay);
    digitalWrite(7, LOW);
    delay(dilay);
  

    


    delay(1000);
    
 
   

}
