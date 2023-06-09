import processing.video.*;
import java.util.ArrayList;
import oscP5.*;
import netP5.*;

Capture video;
PImage prev;

float threshold = 25;
float minObjectSize = 100;
float clusterThreshold = 50;
ArrayList<PVector> objectPositions;
ArrayList<PVector> clusteredPositions;
int averagingFrames = 10;
ArrayList<PVector> averagedPositions;
int timeoutFrames = 30;
int framesWithoutObject = 0;

OscP5 oscP5;

void setup() {
  size(640, 360);
  String[] cameras = Capture.list();
  printArray(cameras);
  video = new Capture(this, 640, 360, 30);
  video.start();
  prev = createImage(640, 360, RGB);
  objectPositions = new ArrayList<PVector>();
  clusteredPositions = new ArrayList<PVector>();
  averagedPositions = new ArrayList<PVector>();

  oscP5 = new OscP5(this, 12000);
}

void captureEvent(Capture video) {
  prev.copy(video, 0, 0, video.width, video.height, 0, 0, prev.width, prev.height);
  prev.updatePixels();
  video.read();
}

void draw() {
  updateVideoFrame();
  detectObjects();
  clusterPositions();
  averagePositions();
  displayObjects();
  sendPositionsViaOSC();
  printObjectCounts();
}

void updateVideoFrame() {
  video.loadPixels();
  prev.loadPixels();
  image(video, width, 0, -width, height);
}

void detectObjects() {
  objectPositions.clear();
  loadPixels();

  for (int x = 0; x < video.width; x++) {
    for (int y = 0; y < video.height; y++) {
      int loc = x + y * video.width;
      color currentColor = video.pixels[loc];
      float r1 = red(currentColor);
      float g1 = green(currentColor);
      float b1 = blue(currentColor);
      color prevColor = prev.pixels[loc];
      float r2 = red(prevColor);
      float g2 = green(prevColor);
      float b2 = blue(prevColor);

      float d = distSq(r1, g1, b1, r2, g2, b2);

      if (d > threshold * threshold) {
        pixels[loc] = color(255);
        if (countPixels(loc) > minObjectSize) {
          objectPositions.add(new PVector(x, y));
        }
      } else {
        pixels[loc] = color(0);
      }
    }
  }

  updatePixels();
}

int countPixels(int loc) {
  int count = 0;
  int startX = loc % video.width;
  int startY = loc / video.width;
  int objColor = color(255);
  boolean[] visited = new boolean[video.width * video.height];

  ArrayList<Integer> stack = new ArrayList<Integer>();
  stack.add(loc);

  while (!stack.isEmpty()) {
    int pixel = stack.remove(stack.size() - 1);
    int x = pixel % video.width;
    int y = pixel / video.width;

    if (x >= 0 && x < video.width && y >= 0 && y < video.height && !visited[pixel] && pixels[pixel] == objColor) {
      visited[pixel] = true;
      count++;

      stack.add(pixel - 1);
      stack.add(pixel + 1);
      stack.add(pixel - video.width);
      stack.add(pixel + video.width);
    }
  }

  return count;
}

float distSq(float x1, float y1, float z1, float x2, float y2, float z2) {
  float d = (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1) + (z2 - z1) * (z2 - z1);
  return d;
}

void clusterPositions() {
  clusteredPositions.clear();

  for (PVector position : objectPositions) {
    boolean addedToCluster = false;

    for (PVector cluster : clusteredPositions) {
      float dist = dist(position.x, position.y, cluster.x, cluster.y);
      if (dist < clusterThreshold) {
        cluster.x = (cluster.x + position.x) / 2;
        cluster.y = (cluster.y + position.y) / 2;
        addedToCluster = true;
        break;
      }
    }

    if (!addedToCluster) {
      clusteredPositions.add(new PVector(position.x, position.y));
    }
  }
}

void averagePositions() {
  if (objectPositions.size() > 0) {
    framesWithoutObject = 0;

    if (averagedPositions.size() < averagingFrames) {
      averagedPositions.add(objectPositions.get(0).copy());
    } else {
      averagedPositions.remove(0);
      averagedPositions.add(objectPositions.get(0).copy());
    }
  } else {
    framesWithoutObject++;

    if (framesWithoutObject >= timeoutFrames) {
      averagedPositions.clear();
    }
  }
}

void displayObjects() {
  for (PVector position : averagedPositions) {
    float lerpX = position.x;
    float lerpY = position.y;

    fill(255, 0, 255);
    strokeWeight(2.0);
    stroke(0);
    ellipse(lerpX, lerpY, 36, 36);
  }
}

void sendPositionsViaOSC() {
  OscMessage message = new OscMessage("/ellipse/position");

  for (PVector position : averagedPositions) {
    message.add(position.x);
    message.add(position.y);
  }

  oscP5.send(message, new NetAddress("127.0.0.1", 12345));
}

void printObjectCounts() {
  println("Detected objects: " + objectPositions.size());
  println("Clustered objects: " + clusteredPositions.size());
}
