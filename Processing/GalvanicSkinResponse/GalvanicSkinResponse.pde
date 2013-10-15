/**
 * GSR sensor code from Tom Keene < tom@theanthillsocial.co.uk>
 *
 * Taken from – http://www.theanthillsocial.co.uk/sketch/163
 *
 * Originally from – http://cwwang.com/2008/04/13/gsr-reader/
 */

import processing.serial.*;
Serial myPort;  

int hPosition = 1;     // the horizontal position on the graph
float currentReading;
float lastReading;
int count=0;
int zeroLinePos=0;

float gsrAverage, prevGsrAverage;
float baseLine=0;
long lastFlatLine=0;
color graphColor=color(255, 255, 255);
int baselineTimer=10000;
int gsrValue;
int gsrZeroCount=0;
float gsrRange=0;
int downhillCount=0;
int uphillCount=0;
boolean downhill;
boolean peaked=false;
float peak, valley;

ArrayList<Integer> grsValues;
ArrayList<Integer> grsAverages;

void setup () {
  size(640, 480);

  grsValues = new ArrayList<Integer>();
  grsAverages = new ArrayList<Integer>();

  myPort = new Serial(this, Serial.list()[9], 9600);
  currentReading=0;
  lastReading=0;
  gsrAverage=0;
  background(0);

  smooth();
}

void draw () {
  //best delay setting for gsr readings
  delay(50);
  //image(myMovie, 0, 0);

  int gsrThreshold = 15;

  if ( gsrValue <gsrThreshold && gsrValue >- gsrThreshold ) {
    if ( gsrZeroCount > 10 ) {
      currentReading=0;//flatline
      gsrAverage=0;
      baseLine=0;
      lastFlatLine=millis();
      gsrZeroCount=0;
      // println("reset");
    }
    gsrZeroCount++;
  } else {
    currentReading=gsrValue-baseLine;
    gsrZeroCount=0;
  }

  if (millis()-lastFlatLine>baselineTimer) {
    baseLine=gsrAverage;
  }

  //graph colors
  if (gsrAverage>0 && gsrAverage<height/2.0*.25) graphColor=color(255, 255, 255); else if (gsrAverage>height/2.0*.25 && gsrAverage<height/2.0*.5) graphColor=color(255, 250, 100); else if (gsrAverage>height/2.0*.5 && gsrAverage<height/2.0*.75) graphColor=color(255, 250, 0); else if (gsrAverage>height/2.0*.75) graphColor=color(255, 100, 0);

  gsrRange=peak-valley;

  // at the edge of the screen, go back to the beginning:
  if (hPosition >= width) {
    hPosition = 0;

    // cover last drawing
    fill(0, 200);
    noStroke();
    rect(0, 0, width, height);
  } else 
  {
    hPosition += 2;
  }

  gsrAverage=smooth(currentReading, .97, gsrAverage);

  //draw stuff

  //spike
  noStroke();
  if (gsrRange>200) {
    fill(255);
    ellipse(10, 10, 20, 20);
  } else {
    fill(0);
    ellipse(10, 10, 20, 20);
  }

  //graph
  strokeWeight(2);
  stroke(graphColor);
  line(hPosition-1, height/2 - lastReading, hPosition, height/2 - currentReading);
  stroke(255, 0, 100);
  line(hPosition-1, height/2 - prevGsrAverage, hPosition, height/2 - gsrAverage);

  //draw peaks
  int thres=7;

  noFill();
  stroke(255, 0, 0);
  strokeWeight(2);

  if (currentReading-thres>lastReading&& peaked==true) {
    downhill=false;
    //println(downhillCount);
    uphillCount++;
    downhillCount=0;
    point(hPosition-1, height/2.0-lastReading);
    valley=lastReading;
    peaked=false;
  }
  if (currentReading+thres<lastReading && peaked==false) {
    //println(uphillCount);
    downhill=true;
    uphillCount=0;
    downhillCount++;
    point(hPosition-1, height/2.0-lastReading);
    peak=lastReading;
    peaked=true;
  }

  fill(0);
  noStroke();
  rect(0, height-40, 100, 40);

  fill(255);
  //  text("value = " + gsrValue, 0, height-10);

  prevGsrAverage = gsrAverage;
  lastReading = currentReading;

  // save the data
  grsValues.add(int(currentReading));
  grsAverages.add(int(gsrAverage));

  //send 'a' for more bytes
  myPort.write('a');
}

void serialEvent (Serial myPort) {
  int inByte=myPort.read();
  //0-255
  gsrValue=inByte;
  println(inByte);
}

void keyPressed() {

  if (keyCode == DOWN)
  {
    zeroLinePos += 3;
  }
  if (keyCode == UP)
  {
    zeroLinePos -= 3;
  }
  if (key == ' ')
  {
    background(0);
  }
  if (key == 's') 
  {
    println("save the data");
    String[] lines = new String[grsValues.size()];
    for (int i = 0; i < grsValues.size(); i++) {
      lines[i] = str(grsValues.get(i)) + "\t" + str(grsAverages.get(i));
    }
    saveStrings("data"+ millis() +".csv", lines);
    println(grsValues.size());
  }

  strokeWeight(1);
  stroke(255, 0, 0);
  line(0, zeroLinePos, 2, zeroLinePos);
}

int smooth(float data, float filterVal, float smoothedVal) {
  if (filterVal > 1) {      // check to make sure param's are within range
    filterVal = .99;
  } else if (filterVal <= 0) {
    filterVal = 0;
  }
  smoothedVal = (data * (1 - filterVal)) + (smoothedVal  *  filterVal);
  return (int)smoothedVal;
}

