ArrayList<Particle> particles = new ArrayList<Particle>();
ArrayList<FlowParti> flowPartis = new ArrayList<FlowParti>();
int maxParticles = 5000; 
int lastMoveTime = millis();

import oscP5.*;
import netP5.*;

OscP5 oscP5;
ArrayList<PVector> receivedPositions;
Object lock;



color[] backgroundColors = {
  
  color(26,29,26),
  color(30,36,28),
  color(39,39,27),
  color(44,34,28),
  color(45,33,38),
  color(36,31,45),
  color(31,35,51),
  color(26,37,45),
  color(24,30,32),
  
 
};
color currentColor;
color targetColor;
float transitionDuration = 2.0; 
float transitionStartTime;

FlowField flowField;
int resolution = 20;
int numParticles = 550;
float particleSpeed = 1;
int fieldChangeInterval = 9000;
float particlePadding = 0;


import processing.serial.*;
Serial arduino;
int receivedPeopleCount;
float receivedSensorValue;

boolean generateFlowParticles = true; 
int flowParticleStartTime = 5; 

void setup() {
  size(1200, 600);
  smooth();
  transitionStartTime = millis() / 1000.0;
  arduino = new Serial(this, "COM7", 9600);
  arduino.bufferUntil('\n');
  
  oscP5 = new OscP5(this, 12345); 
  receivedPositions = new ArrayList<PVector>(); 
  lock = new Object();

  flowField = new FlowField(resolution, numParticles, particleSpeed, fieldChangeInterval, particlePadding);
}

void draw() {
   if (receivedPeopleCount >= 0 && receivedPeopleCount < backgroundColors.length) {
    int colorIndex = receivedPeopleCount;
    if(receivedPeopleCount<8){
    background(backgroundColors[colorIndex]);
    }else{
    background(26,29,26);
    }
  }
  
  
    while (arduino.available() > 0) {
    String data = arduino.readStringUntil('\n');
    if (data != null) {
      
      parseAndStoreData(data);
      
      println("Received People Count: " + receivedPeopleCount);
      println("Received Sensor Value: " + receivedSensorValue);
    }
  }
  
   synchronized (lock) {
    for (PVector position : receivedPositions) {
      float lerpX = position.x;
      float lerpY = position.y;

      
      particleMovement(lerpX, lerpY);
        if (generateFlowParticles) {
    
    if (millis() - flowParticleStartTime < 1000) {
      flowField.generateParticlesInArea(lerpX - 10, lerpY - 10, lerpX + 10, lerpY + 10, 2);
    } else {
      generateFlowParticles = false;
    }
  }
    }
  }
  

  flowField.update();
  flowField.display();
  connectDuplicateParticles();

  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.display();
    if (p.isDead()) {
      particles.remove(i);
    }
  }

  for (int i = flowPartis.size() - 1; i >= 0; i--) {
    FlowParti f = flowPartis.get(i);
    f.follow(flowField.flowField);
    f.update();
    f.display();
  }


}

void particleMovement(float lerpX, float lerpY) {
  if (particles.size() < maxParticles) { 
    if (millis() - lastMoveTime > 250) {
      particles.add(new Particle(new PVector(lerpX, lerpY)));
      lastMoveTime = millis();
    }
  }
  
  generateFlowParticles = true; 
  flowParticleStartTime = millis(); 
}

void connectDuplicateParticles() {
  stroke(255, 30); 
  strokeWeight(1); 
  for (int i = 0; i < particles.size(); i++) {
    Particle p1 = particles.get(i);

    for (int j = i + 1; j < particles.size(); j++) {
      Particle p2 = particles.get(j);

      line(p1.position.x, p1.position.y, p2.position.x, p2.position.y); 
    }
  }
}

class Particle {
  PVector position;
  PVector velocity;
  float lifespan;
  int lastMoveTime;
  PVector lastMovePosition;
  int timeCreated;
  boolean createdFromHover;
  float maxDistance = 30; 

  Particle(PVector position) {
    this.position = position.copy();
    this.velocity = new PVector(random(-0.03, 0.03), random(-0.03, 0.03));
    this.lifespan = 200.0;
    this.lastMoveTime = millis();
    this.lastMovePosition = position.copy();
    this.timeCreated = millis();
    this.createdFromHover = (dist(position.x, position.y, mouseX, mouseY) < 50);
  }

  void update() {
    if (createdFromHover && dist(position.x, position.y, mouseX, mouseY) < 50) { 
      if (millis() - lastMoveTime > 1000) { 
        PVector displacement = PVector.random2D().mult(1);
        position.add(displacement);
        lastMovePosition = position.copy();
        lastMoveTime = millis();
      }
      velocity = new PVector(0, 0); 
    } else {
      velocity.add(PVector.random2D().mult(0.1));
      velocity.limit(0.7);
    }
    position.add(velocity);
    lifespan -= 1.5;

    // Duplicate particle after two seconds
    if (createdFromHover && millis() - timeCreated > 2000) {
      Particle newParticle1 = new Particle(position);
      Particle newParticle2 = new Particle(position);
      newParticle1.velocity = velocity.copy().mult(0.02);
      newParticle2.velocity = velocity.copy().mult(0.02);
      newParticle1.maxDistance = maxDistance * 0.5;
      newParticle2.maxDistance = maxDistance * 0.5;
      particles.add(newParticle1);
      particles.add(newParticle2);
      particles.remove(this);
    }
  }

  void display() {
    noStroke();
    fill(255, lifespan);
    ellipse(position.x, position.y, 10, 10);
  }

  boolean isDead() {
    if (lifespan <= 0.0) {
      return true;
    } else {
      return false;
    }
  }
}

class FlowParti {
  PVector position;
  PVector velocity;
  PVector acceleration;
  float maxSpeed;
  float maxForce;
  
  FlowParti(float x, float y) {
    position = new PVector(x, y);
    velocity = new PVector(0, 0);
    acceleration = new PVector(0, 0);
    maxSpeed = random(1, 2);
    maxForce = 0.2;
  }
  
   void update() {
    velocity.add(acceleration);
    velocity.limit(maxSpeed);
    position.add(velocity);

   
    if (position.x < 0) {
      position.x = width;
    } else if (position.x > width) {
      position.x = 0;
    }

    if (position.y < 0) {
      position.y = height;
    } else if (position.y > height) {
      position.y = 0;
    }

    acceleration.mult(0);
  }

  
  void applyForce(PVector force) {
    acceleration.add(force);
  }
  
  void follow(PVector[][] flowField) {
    int x = floor(position.x / resolution);
    int y = floor(position.y / resolution);
    x = constrain(x, 0, flowField.length - 1);
    y = constrain(y, 0, flowField[0].length - 1);
    PVector desired = flowField[x][y].copy();
    desired.mult(particleSpeed);
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxForce);
    applyForce(steer);
  }
  
    void display() {
      stroke(114,104,68);
      float len = 10;
      float angle = velocity.heading();
      float x1 = position.x - len / 2 * cos(angle);
      float y1 = position.y - len / 2 * sin(angle);
      float x2 = position.x + len / 2 * cos(angle);
      float y2 = position.y + len / 2 * sin(angle);

   
      line(x1, y1, x2, y2);
    }

}

class FlowField {
  int resolution;
  int cols, rows;
  PVector[][] flowField;
  ArrayList<Particle> particles;
  int fieldChangeInterval;
  float particlePadding;
  float particleSpeed;
  int lastChangeTime;

  FlowField(int resolution, int numParticles, float particleSpeed, int fieldChangeInterval, float particlePadding) {
    this.resolution = resolution;
    cols = width / resolution;
    rows = height / resolution;
    flowField = new PVector[cols][rows];
    particles = new ArrayList<Particle>();
    this.fieldChangeInterval = fieldChangeInterval;
    this.particlePadding = particlePadding;
    this.particleSpeed = particleSpeed;
    lastChangeTime = millis();

    generateFlowField();

    for (int i = 0; i < numParticles; i++) {
      particles.add(new Particle(random(width), random(height)));
    }
  }

  void generateFlowField() {
    float xoff = 0;
    for (int i = 0; i < cols; i++) {
      float yoff = 0;
      for (int j = 0; j < rows; j++) {
        float theta = map(noise(xoff, yoff, frameCount * 0.01), 0, 1, 0, TWO_PI);
        flowField[i][j] = PVector.fromAngle(theta);
        yoff += 0.1;
      }
      xoff += 0.1;
    }
  }

  void update() {
    if (millis() - lastChangeTime >= fieldChangeInterval) {
      generateFlowField();
      lastChangeTime = millis();
    }

    for (Particle p : particles) {
      p.follow(flowField);
      p.update();
      p.checkEdges();
    }
  }

  void display() {
    for (Particle p : particles) {
      p.display();
    }
  }

  void generateParticlesInArea(float minX, float minY, float maxX, float maxY, int numParticles) {
    for (int i = 0; i < numParticles; i++) {
      float x = random(minX, maxX);
      float y = random(minY, maxY);
      boolean validParticle = true;

      for (Particle p : particles) {
        if (dist(x, y, p.position.x, p.position.y) < particlePadding) {
          validParticle = false;
          break;
        }
      }

      if (validParticle) {
        particles.add(new Particle(x, y));
      }
    }
  }

  class Particle {
    PVector position;
    PVector velocity;
    PVector acceleration;
    float maxSpeed;
    float maxForce;

    Particle(float x, float y) {
      position = new PVector(x, y);
      velocity = new PVector(0, 0);
      acceleration = new PVector(0, 0);
      maxSpeed = random(2, 4);
      maxForce = 0.1;
    }

    void update() {
      velocity.add(acceleration);
      velocity.limit(maxSpeed);
      position.add(velocity);
      acceleration.mult(0);
    }

    void applyForce(PVector force) {
      acceleration.add(force);
    }

    void follow(PVector[][] flowField) {
      int x = floor(position.x / resolution);
      int y = floor(position.y / resolution);
      x = constrain(x, 0, flowField.length - 1);
      y = constrain(y, 0, flowField[0].length - 1);
      PVector desired = flowField[x][y].copy();
      desired.mult(particleSpeed);
      PVector steer = PVector.sub(desired, velocity);
      steer.limit(maxForce);
      applyForce(steer);
    }

    void checkEdges() {
      if (position.x < 0) position.x = width;
      if (position.x > width) position.x = 0;
      if (position.y < 0) position.y = height;
      if (position.y > height) position.y = 0;
    }

    void display() {
      float len = 10;
      float angle = velocity.heading();
      float x1 = position.x - len / 2 * cos(angle);
      float y1 = position.y - len / 2 * sin(angle);
      float x2 = position.x + len / 2 * cos(angle);
      float y2 = position.y + len / 2 * sin(angle);

      stroke(255,receivedSensorValue/10);  // Alpha
      line(x1, y1, x2, y2);
    }
  }
}


void parseAndStoreData(String data) {
  String[] values = split(data.trim(), ',');
  for (int i = 0; i < values.length; i++) {
    String[] parts = split(values[i], ':');
    if (parts.length == 2) {
      String key = parts[0];
      String value = parts[1];
      if (key.equals("peopleCount")) {
        receivedPeopleCount = int(value);
      } else if (key.equals("sensorValue")) {
        receivedSensorValue = float(value);
      }
    }
  }
}

void oscEvent(OscMessage message) {
  if (message.checkAddrPattern("/ellipse/position")) {
    
    synchronized (lock) {
      receivedPositions.clear(); 

      for (int i = 0; i < message.arguments().length - 1; i += 2) {
        float x = message.get(i).floatValue();
        float y = message.get(i + 1).floatValue();
        receivedPositions.add(new PVector(x, y));
      }
    }
  }
}
