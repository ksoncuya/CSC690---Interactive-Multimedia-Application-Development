/*
 Name: Project 3.0x 
 Copyright: 
 Author: Kevin Soncuya
 Date: 9/19/14
 Modified: 10/30/14
 Description: Simple Image Browser that allows a user to navigate a small image library.
 Update 1: Added animation
 Update 2: Auditory Icons and Annotations
 Update 3: Add 'facebook style' tags and remote controller 
 Environment: Processing 
 */

import ddf.minim.*;
import controlP5.*;
import oscP5.*;
import netP5.*;

PImage[] images; //images array
//record the mouse pressed marks 
int[] v1x = new int[0]; //x-coordinate of the vertex
int[] v1y = new int[0]; //y-coordinate of the vertex
int[] v2x = new int[0]; 
int[] v2y = new int[0];
int xInit = 0;  // x coordinate for TOP LEFT
int yInit = 0;  // y coordinate for TOP LEFT 
int xFinal = 0; // x coordinate for BOTTOM RIGHT 
int yFinal = 0; // y coordinate for BOTTOM RIGHT
int xMid; // x midpoint of box
int yMid; // y midpoint of box
int tagId; //tag index in the file 

int currIndex = 0; //index of current image
int numOfImages;  //total number of images
int leftMost = 0; //index of leftMost value
int offset = 5; //offset for selected image 
int maxWidth = 135; 
int maxHeight = 100; 
int mode;  //mode for switch case
int leftBorder = 0;  //leftBorder value
int rightBorder = 650; //rightBorder value  
int increment = 0;  //transition stopper for mode 1 
int iterate = 0;  //loop counter for image iteration
int oldValue = 0;  //old value of counter of how many times you transition left/right
int putBack = 0; //puts selector in the correct position for mouse click
int moveRightCounter = 0;  //counter for how many times you transition right
int moveLeftCounter = 0;  //counter for how many times you transition left
int display = 100; //put tags in the correct location 
int cI = 0; //current Index for big image
int saveIndex = 0; //stores the currIndex and make it equal to big image index
int count = 0; //increases as mouse creates a bigger rect 
int rectX1; //initial dragging point x
int rectY1; //initial dragging point y
int rectX2; //final releasing point using mouseX
int rectY2; //final releasing point using mouseY
int eX = 0; //mouse X of ellipse for remote controller
int eY = 0;  //mouse Y of ellipse
int eW = 10; //width of ellipse
int eH = 10; //height of ellipse

float xText = 270;  //x position of text box
float xButton = 480; //x position of save button
float t = 0; //velocity rate for mode 0 images
float s = 0; //velocity rate for mode 1 images
float sizeX = 0; //width of rect created
float sizeY = 0; //height of rect created

boolean moveRight;  //true if transition right for mode 1 
boolean moveLeft;  //true if transition left for mode 1 
boolean drawMode0 = true;  //true if mode 0 is chosen 
boolean drawMode1; //true if mode 1 is chosen 
boolean drawOnce = true; //boolean to draw the text field box and button
boolean drawRect; //true if button is clicked then ables user to create a box

PFont font = createFont("Arial", 14); //(font type, size)
String text; //string value for the user's input
String[] tags;  //string array of text inputs that will be saved as tags IN A FILE 
String tagsDisplay[]; //tags array to be displayed ON SCREEN

ArrayList<String> tagList = new ArrayList<String>(); 
ArrayList<Integer> xList = new ArrayList<Integer>();
ArrayList<Integer> yList = new ArrayList<Integer>();
ArrayList<Integer> idList = new ArrayList<Integer>();

Minim minim; 
AudioPlayer bass;
AudioPlayer dr; 
AudioPlayer gs;
AudioPlayer scream;
AudioPlayer gigity;
ControlP5 cp5;
OscP5 oscP5;
NetAddress myRemoteLocation;
PrintWriter createFile;

void setup() {
  size(800, 600); 
  stroke(180);
  strokeWeight(3);
  noFill();

  String path = sketchPath + "/data"; 
  File[] files = listFiles(path);
  numOfImages = files.length; //set numOfImages to total number of files 
  images = new PImage[numOfImages]; 

  if (drawMode0) {
    for (int i = 0; i < files.length;i++) {
      images[i] = loadImage(files[i].getName());
      int aspectRatio  = images[i].width / images[i].height;  //aspect ratio
      if (images[i].width > images[i].height) { //if image width is bigger than image height
        images[i].resize(maxWidth, maxHeight * (1 / aspectRatio)); // resize the image with original width and shorten it out
      } 
      else {
        images[i].resize(maxHeight*(aspectRatio), maxHeight);  //else keep the height and make the cut the width
      }
    }
  }

  //if mode = 1
  //resize images bigger
  if (drawMode1) {
    for (int i = 0; i < files.length;i++) {
      images[i] = loadImage(files[i].getName());
      int aspectRatio  = images[i].width / images[i].height;  //aspect ratio
      if (images[i].width > images[i].height) { //if image width is bigger than image height
        images[i].resize(600, 400 * (1 / aspectRatio)); // resize the image with original width and shorten it out
      } 
      else {
        images[i].resize(600*(aspectRatio), 400);  //else keep the height and make the cut the width
      }
    }
    getTagsInBox();
  } 

  minim = new Minim(this);
  dr = minim.loadFile("Drumroll.wav");  //load drum roll file
  minim = new Minim(this);
  bass = minim.loadFile("bass kick.wav");  //load bass kick file
  minim = new Minim(this);
  gs = minim.loadFile("gunshot.wav");  //load gunshot file
  minim = new Minim(this);
  scream = minim.loadFile("scream.wav");  //load scream file
  minim = new Minim(this);
  gigity = minim.loadFile("gigity.mp3"); //load gigity sound file

    if (drawOnce) {
    //Instaniate a controP5 object for button 
    cp5  =  new  ControlP5(this);  
    //x moves as you translate
    cp5.addButton("tag_box_in_image").setPosition(xText-100, 10).setSize(90, 40); //create button for tag box in image
    cp5.addTextfield("insert tag").setPosition(xText, 10).setSize(200, 40).setFont(font) .setColor(color(255, 255, 255));
    cp5.addButton("save").setPosition(xButton, 10).setSize(50, 40);
    cp5.addButton("clear").setPosition(xButton+60, 10).setSize(50, 40);
    drawOnce = false;
  }

  //code for remote controller
  oscP5 = new OscP5(this, 12000);
  myRemoteLocation = new NetAddress("127.0.0.1", 12001);
}   

//stores the text input when user hits RETURN
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isAssignableFrom(Textfield.class)) {
    text = cp5.get(Textfield.class, "insert tag").getText();
    tags = split(text, ' '); 
    println("text" + text);
    //println("tags" + tags);
  }
}

//saves text input to the designated file
void save() {
  println("The following texts: |" +tags+ "| is stored in your file.");
  String filePath = sketchPath("image_"+cI+"_tags.txt");
  File file = new File(filePath);

  if (!file.exists()) {
    createFile = createWriter("image_"+cI+"_tags.txt");
  }
  else {
    tags = loadStrings(sketchPath("image_"+cI+"_tags.txt"));  //load the file
    tags = append(tags, tagId+" "+xMid+" "+yMid+" "+text);  //append the string array values in the file
    //tags = append(tags, text);
    saveStrings("image_"+currIndex+"_tags.txt", tags); //saves to the designated file with image number
    //    tagSaved = true;
  }
  tagId++;
}

//function to clear all the tags in a file
void clear() {
  String filePath = sketchPath("image_"+cI+"_tags.txt");
  File file = new File(filePath);

  String dummy = " ";
  String[] empty = split(dummy, " ");
  saveStrings("image_"+cI+"_tags.txt", empty);
}  

//function that gets called to create tag box
void tag_box_in_image() {
  drawMode0 = false;
  drawMode1 = true;    
  drawRect = true;
  cI = saveIndex;  //place saveIndex value into cI
  setup();
  mode = 1;
  gs.play();
  dr.rewind();
}  

void Rect() {
  sizeX = rectX2 - rectX1; //ending width of rect
  sizeY = rectY2 - rectY1; //ending height of rect

  //draw vertices to make rectangle 
  for (int i = 0; i < count; i++) {
    beginShape();
    vertex(v1x[i], v1y[i]); //top left coordinates of the rect
    vertex(v2x[i], v1y[i]); //top right coordinates of the rect
    vertex(v2x[i], v2y[i]); //bottom right coordinates of the rect
    vertex(v1x[i], v2y[i]); //bottom left coodinates of the rect
    xInit = v1x[i];
    yInit = v1y[i];
    xFinal = v2x[i];
    yFinal = v2y[i];

    xMid = ((xInit + xFinal) / 2); //calculate midpoint x
    yMid = ((yInit + yFinal) / 2); //calculate midpoint y

    endShape(CLOSE); //finishes creating rect
  }
  if (mousePressed && mouseButton == LEFT) {
    rect(rectX1, rectY1, sizeX, sizeY);
  }
}

//method to get tags to display during mode 1 
void getTags() {

  // both if blocks below are for currIndex of big image
  if (cI < 0 || cI <= -1) {
    cI = numOfImages + cI;
  }
  if (cI >= numOfImages) {
    cI = cI % numOfImages;
  }

  String filePath = sketchPath("image_"+cI+"_tags.txt");
  File file = new File(filePath);

  if (!file.exists()) {
    createFile = createWriter("image_"+cI+"_tags.txt");
  }
  else {  
    tagsDisplay = loadStrings(sketchPath("image_"+cI+"_tags.txt")); //get the tags to display when mouse is over the rectangle ON THE SCREEN 
    tags = loadStrings(sketchPath("image_"+cI+"_tags.txt")); //load the tags IN THE FILE

    String joinedTags = join(tags, ' '); //combine all tags in a string
    tagsDisplay = split(joinedTags, ' '); //then seperate tags by spacing 

    for (int i = 0; i < tagList.size(); i++) {
      textSize(14);
      text(tagList.get(i), display+(50*i), 525);
    }
  }
} 

void getTagsInBox() {
  String filePath = sketchPath("image_"+cI+"_tags.txt");
  File file = new File(filePath);

  if (!file.exists()) {
    createFile = createWriter("image_"+cI+"_tags.txt");
  }
  else {  

    tagsDisplay = loadStrings(sketchPath("image_"+cI+"_tags.txt")); //get the tags to display when mouse is over the rectangle ON THE SCREEN 
    tags = loadStrings(sketchPath("image_"+cI+"_tags.txt")); //load the tags IN THE FILE

    String joinedTags = join(tags, ' '); //combine all tags in a string
    tagsDisplay = split(joinedTags, ' '); //then seperate tags by spacing 

    if (!tagsDisplay[0].equals("") && !tagsDisplay[1].equals("")) {
      for (int i = 0; i < tagsDisplay.length; i+=4) {
        tagId = Integer.parseInt(tagsDisplay[i]);
        idList.add(tagId);
        //println(tagId);
      }  

      for (int i = 1; i < tagsDisplay.length; i+=4) {
        xMid = Integer.parseInt(tagsDisplay[i]);  
        xList.add(xMid);
        //println(xList);
      }  

      for (int i = 2; i < tagsDisplay.length; i+=4) {
        yMid = Integer.parseInt(tagsDisplay[i]);  
        yList.add(yMid);   
        //println(yList);
      }  

      for (int i = 3; i < tagsDisplay.length;  i+=4) { //iterate to the now separated strings and print the third string, which is the tag string value                                               
        tagList.add(tagsDisplay[i]);
      }
    }
  }
}  

void draw() {
  switch(mode) {
  case 0: 
    drawMode0(); 
    break;
  case 1: 
    drawMode1(); 
    break;
  case 2: 
    drawMoveRight(); 
    break;
  case 3: 
    drawMoveLeft(); 
    break;
  default: 
    background(0); 
    break;
  }

  println("Tag_Image_In_Box only works when user types a text then hit return THEN create a box");
  println("Have to hit DOWN then hit UP to display 'tag in a box on image'"); 
  println();
  println("Tags don't display correctly when transitioning LEFT/RIGHT while on mode 1");
  println("Tags repeat itself when user hits DOWN from mode 1");

}

void drawMode0() {

  background(0, 0, 255); //(R, G, B) 
  rect(offset, 225, 140, 140); //rect(x, y, width, height)                     
  imageMode(CENTER);

  int i = 0;
  for (i = i % numOfImages; i <= (leftMost+4); i++) {
    image(images[(i) % numOfImages], 75+160*i, height/2);
  }
  ellipse(eX, eY, eW, eH);

  update();
}    

void drawMode1() { 

  translate(s, 0);
  background(0, 0, 255); //(R, G, B) 
  imageMode(CENTER);

  //same as 5 thumbnail method
  //load up the next images 
  int x = 0;
  for (int i = currIndex; i <= iterate; i++) {  //change back to currIndex
    if (currIndex <= -1) {  //if index <= -1 
      currIndex = numOfImages + currIndex;  //add 16
    }  
    image(images[(currIndex+x) % numOfImages], 400+(800*x), height/2);  //change back to currIndex
    x++;
  }  

  int y = 0;
  int temp = 0;
  for (int j = currIndex % numOfImages; j <= iterate; j++) {
    temp = ((currIndex-y)-1) % numOfImages;                                 
    //since processing return negative numbers from moduling negative numbers
    if (temp <= -1) {  //if index <= -1 
      temp = numOfImages + temp;  //add 16
    }
    image(images[temp], -400-(800*y), height/2); 
    y++;
  }  

  text("TAGS: ", (display-40), 525); //draw a TAGS: to indicate where tags are on screen
  getTags(); //function is called to get tags

    if (moveRight) {
    s = s - 11.0;
    if (s <= increment) {   //s stops when it hits the marker
      s = s + 11.0;
      moveRight = false;
      gigity.rewind();
    }
  }

  if (moveLeft) {
    s = s + 11.0;
    if (s >= increment) {   //s stops when it hits the marker
      s = s - 11.0;
      moveLeft = false;
      gigity.rewind();
    }
  }

  //allows users to create a box to tag image
  if (drawRect) {
    Rect();
  }

  for (int i = 0; i < tagList.size(); i++) {
    if (mouseX < xList.get(i)+25 && mouseX > xList.get(i)-25 && 
      mouseY < yList.get(i)+25 && mouseY > yList.get(i)-25) {
      textSize(30);
      text(tagList.get(i), mouseX, mouseY);
    }
  }

  update();
}

void drawMoveRight() {

  background(0, 0, 255); //(R, G, B) 
  imageMode(CENTER);
  translate(t, 0);
  rect(offset, 225, 140, 140); //rect(x, y, width, height) 
  //y, width and height never changes 

  int i = 0;
  for (i = i % numOfImages; i < (leftMost+5) + iterate; i++) {
    image(images[(i) % numOfImages], 75+160*i, height/2);
  }    

  int j = 0;
  for (j = j % numOfImages; j < ((leftMost+5) + iterate); j++) {
    image(images[(numOfImages - 1) - j % numOfImages], 75-(160*(j+1)), height/2);
  }  

  t = t - 7.0;
  if (t <= leftBorder * -1) { //t stops when it hits the leftBorder
    t = t + 7.0;
    dr.rewind();
  }

  translate(xText, 0);
  xText = xText + 7.0;
  if (xText >= leftBorder) {   //x position stops at the marker
    xText = xText - 7.0;
  }

  update();
}  

void drawMoveLeft() {

  background(0, 0, 255); //(R, G, B) 
  imageMode(CENTER);
  translate(t, 0);
  rect(offset, 225, 140, 140); //rect(x, y, width, height) 
  //y, width and height never changes                           

  int i = 0;
  for (i = i % numOfImages; i < ((leftMost+5) + iterate); i++) {
    image(images[(i) % numOfImages], 75+160*i, height/2);
  }    

  int j = 0;
  for (j = j % numOfImages; j < ((leftMost+5) + iterate); j++) {
    image(images[(numOfImages - 1) - j % numOfImages], 75-(160*(j+1)), height/2);
  }  

  t = t + 7.0;
  if (t >= leftBorder*-1) { //stops when t hits the leftBorder
    t = t - 7.0;
    dr.rewind();
  }

  translate(xText, 0);
  xText = xText - 7.0;
  if (xText <= leftBorder) {   //x position stops at the marker
    xText = xText + 7.0;
  }

  update();
}  

void update() {

  if (drawMode0) {
    //if offset passes the right border, set offset back to 0
    if (offset > rightBorder) {
      leftBorder = leftBorder + 800;
      rightBorder = rightBorder + 800;
      leftMost += 5;    
      iterate += 5;  
      moveRightCounter++;
      putBack += 800;
      oldValue = moveRightCounter - 1;
      dr.play();
      mode = 2;
    }

    //if offset passed the left border, set offset back to 0
    else if (offset < leftBorder) {
      rightBorder = rightBorder - 800;
      leftBorder = leftBorder - 800; 
      leftMost -= 5;
      iterate += 5;
      moveLeftCounter++;
      putBack -= 800;
      oldValue = moveLeftCounter - 1;
      dr.play();
      mode = 3;
    }
  }

  //if leftMost is less than 0 
  //move from 0 [0] to F [15]  
  //numOfImages = 16 + -1 is 15 
  if (leftMost < 0) { 
    leftMost = (numOfImages) + leftMost;
  }

  //if leftMost exceeds the total number of images
  //leftMost modulus numOfImages
  //[18] % 16 = [2]
  if (leftMost >= (numOfImages)) {
    leftMost = leftMost % (numOfImages);
  }  

  //if selected image is less than [0]
  //add it to the total number of images to make it positive
  if (currIndex < 0) {
    currIndex = numOfImages + currIndex;
  }  

  //if selected image is greater than [15]
  //selected image [index] modulus numOfImages
  //index do not go over array size
  if (currIndex >= (numOfImages)) {
    currIndex = currIndex % (numOfImages);
  }
}  

void keyPressed() {

  if (key == CODED) {
    if (keyCode == RIGHT) {
      //move x offset coordinate to the right  
      offset = offset + 160; 

      if (drawMode1) {
        increment -= 800;
        moveRight = true;
        iterate++;  //loop counter
        display += 800; //display increment
        cI++;
        gigity.play();
      }    

      if (drawMode0) {
        currIndex++;
        saveIndex++; //increments like currIndex 
        iterate++;  //loop counter
        bass.play();
        bass.rewind();
      }
    }

    if (keyCode == LEFT) {
      //move x offset coordinate to the left  
      offset = offset - 160;  

      if (drawMode1) {
        increment += 800;
        moveLeft = true;
        iterate++;
        display -= 800;
        cI--;
        gigity.play();
      }  

      if (drawMode0) {
        currIndex--;
        saveIndex--;
        iterate += 10;  //loop counter
        bass.play();
        bass.rewind();
      }
    }  

    if (keyCode == UP) {
      //display image in the 800 x 600 window with borders of 50 pixels
      drawMode0 = false;
      drawMode1 = true;    
      cI = saveIndex;  //place saveIndex value into cI
      //      if(drawRect == false || drawMode1) {
      setup();
      //      }
      mode = 1;
      gs.play();
      dr.rewind();
    }

    if (keyCode == DOWN) {
      //display bar showing five consecutive images in the image list 
      drawMode0 = true;
      drawMode1 = false;   
      drawRect = false;  
      saveIndex = cI; //place cI value into saveIndex
      setup();
      mode = 0; 
      mode = 2; 
      mode = 3;
      scream.play();
    }
  }  

  if (key == '>') {
    //display the next five images  
    leftMost +=5; 
    currIndex += 5;
    offset = offset + 800;
  }  

  else if (key == '<') { 
    //display the five images back 
    leftMost -= 5; 
    currIndex -= 5;
    offset = offset - 800;

    if (leftMost < 0) {
      leftMost = (numOfImages) + leftMost;
    }
  }
}

//function is called once after every time a mouse button is pressed
void mousePressed() {
  v1x= append(v1x, mouseX);  //appends new p1x when creating more rect
  v1y= append(v1y, mouseY);  //appends new p1y when creating more rect
  rectX1 = mouseX;  //initial position x of rect using mouseX
  rectY1 = mouseY;  //initital position y of rect using mouseY
  mouseDragged();
}

//function is called every time a mouse button is released
void mouseReleased() {
  v2x= append(v2x, mouseX); //appends new p2x when creating more rect
  v2y= append(v2y, mouseY); //appends new p2y when creating more rect
  count++;
}

//function is called once every time the mouse moves while a mouse button is pressed
void mouseDragged() {
  rectX2 = mouseX;  //ending position x of rect using mouseX
  rectY2 = mouseY;  //ending position y of rect using mouseY
} 

void oscEvent(OscMessage theOscMessage) {
  if (theOscMessage.checkAddrPattern("/move") == true) {
    int xValue = theOscMessage.get(0).intValue();
    int yValue = theOscMessage.get(1).intValue();

    eX = xValue * 2;
    eY = yValue * 2;

    if (offset > rightBorder) {
      mode = 2;
    }
    else if (offset < leftBorder) {
      mode = 3;
    }
    else {
      mode = 0;
    }
  }    

  if (theOscMessage.checkAddrPattern("/right") == true) {
    offset = offset + 160;
    bass.play();
    bass.rewind();
  } 

  if (theOscMessage.checkAddrPattern("/left") == true) {
    offset = offset - 160;
    bass.play();
    bass.rewind();
  }  

  if (theOscMessage.checkAddrPattern("/up") == true) {
    drawMode0 = false;
    drawMode1 = true;    
    //setup();
    mode = 1;
    gs.play();
    gs.rewind();
    dr.rewind();
  }

  if (theOscMessage.checkAddrPattern("/down") == true) {
    drawMode0 = true;
    drawMode1 = false;     
    //setup();
    mode = 0; 
    mode = 2; 
    mode = 3;
    scream.play();
    scream.rewind();
  }

  if (theOscMessage.checkAddrPattern("/moveRight") == true) {
    leftMost +=5; 
    currIndex += 5;
    offset = offset + 800;
  } 

  if (theOscMessage.checkAddrPattern("/moveLeft") == true) {
    leftMost -=5; 
    currIndex -= 5;
    offset = offset - 800;
  }    

  if (theOscMessage.checkAddrPattern("/click0") == true) {
    drawMode0 = false;
    drawMode1 = true;
    currIndex = 0;
    offset = 5;  
    if (moveRightCounter > oldValue && moveRightCounter < (oldValue+2)) {  //check if moveRightCounter gets incremented 
      offset += putBack;
    } 
    if (moveLeftCounter > oldValue && moveLeftCounter < (oldValue+2)) {  //check if moveLeftCounter gets incremented
      offset += putBack;
    }  
    iterate++;
    //setup();
    mode = 1;
  }

  if (theOscMessage.checkAddrPattern("/click1") == true) {
    drawMode0 = false;
    drawMode1 = true;
    currIndex = 1;
    offset = 165;  
    if (moveRightCounter > oldValue && moveRightCounter < (oldValue+2)) {  //check if moveRightCounter gets incremented 
      offset += putBack;
    } 
    if (moveLeftCounter > oldValue && moveLeftCounter < (oldValue+2)) {  //check if moveLeftCounter gets incremented
      offset += putBack;
    }  
    iterate++;
    //setup();
    mode = 1;
  }

  if (theOscMessage.checkAddrPattern("/click2") == true) {
    drawMode0 = false;
    drawMode1 = true;
    currIndex = 2;
    offset = 325;  
    if (moveRightCounter > oldValue && moveRightCounter < (oldValue+2)) {  //check if moveRightCounter gets incremented 
      offset += putBack;
    } 
    if (moveLeftCounter > oldValue && moveLeftCounter < (oldValue+2)) {  //check if moveLeftCounter gets incremented
      offset += putBack;
    }  
    iterate++;
    //setup();
    mode = 1;
  }

  if (theOscMessage.checkAddrPattern("/click3") == true) {
    drawMode0 = false;
    drawMode1 = true;
    currIndex = 3;
    offset = 485;  
    if (moveRightCounter > oldValue && moveRightCounter < (oldValue+2)) {  //check if moveRightCounter gets incremented 
      offset += putBack;
    } 
    if (moveLeftCounter > oldValue && moveLeftCounter < (oldValue+2)) {  //check if moveLeftCounter gets incremented
      offset += putBack;
    }  
    iterate++;
    //setup();
    mode = 1;
  }

  if (theOscMessage.checkAddrPattern("/click4") == true) {
    drawMode0 = false;
    drawMode1 = true;
    currIndex = 4;
    offset = 645;  
    if (moveRightCounter > oldValue && moveRightCounter < (oldValue+2)) {  //check if moveRightCounter gets incremented 
      offset += putBack;
    } 
    if (moveLeftCounter > oldValue && moveLeftCounter < (oldValue+2)) {  //check if moveLeftCounter gets incremented
      offset += putBack;
    }  
    iterate++;
    //setup();
    mode = 1;
  }
}
/*( xLeft + 160  and xRight + 155 
 xLeft is always equal to the offset 
 currIndex increments as dimensions increase by mouseX (+160, +155); */

void mouseClicked() {

  if ((mouseX >= 5 && mouseX <= 145) && (mouseY >= 250 && mouseY <= 350)) {   // index [0]
    drawMode0 = false;
    drawMode1 = true;
    currIndex = 0;
    offset = 5;  
    if (moveRightCounter > oldValue && moveRightCounter < (oldValue+2)) {  //check if moveRightCounter gets incremented 
      offset += putBack;
    } 
    if (moveLeftCounter > oldValue && moveLeftCounter < (oldValue+2)) {  //check if moveLeftCounter gets incremented
      offset += putBack;
    }  
    iterate++;
    setup();
    mode = 1;
  }

  if ((mouseX >= 165 && mouseX <= 300) && (mouseY >= 250 && mouseY <= 350)) { // index [1]
    drawMode0 = false;
    drawMode1 = true;
    currIndex = 1;
    offset = 165; 
    if (moveRightCounter > oldValue && moveRightCounter < (oldValue+2)) {
      offset += putBack;
    }  
    if (moveLeftCounter > oldValue && moveLeftCounter < (oldValue+2)) {  //check if moveLeftCounter gets incremented
      offset += putBack;
    }  
    iterate += 2;
    setup();
    mode = 1;     
    gs.play();
  }

  if ((mouseX >= 325 && mouseX <= 455) && (mouseY >= 250 && mouseY <= 350)) { // index [2]
    drawMode0 = false;
    drawMode1 = true;
    currIndex = 2;
    offset = 325;  
    if (moveRightCounter > oldValue && moveRightCounter < (oldValue+2)) {
      offset += putBack;
    }  
    if (moveLeftCounter > oldValue && moveLeftCounter < (oldValue+2)) {  //check if moveLeftCounter gets incremented
      offset += putBack;
    }  
    iterate += 3;
    setup();
    mode = 1;     
    gs.play();
  }

  if ((mouseX >= 485 && mouseX <= 610) && (mouseY >= 250 && mouseY <= 350)) { // index [3]
    drawMode0 = false;
    drawMode1 = true;
    currIndex = 3;
    offset = 485; 
    if (moveRightCounter > oldValue && moveRightCounter < (oldValue+2)) {
      offset += putBack;
    }  
    if (moveLeftCounter > oldValue && moveLeftCounter < (oldValue+2)) {  //check if moveLeftCounter gets incremented
      offset += putBack;
    }  
    iterate += 4;
    setup();
    mode = 1;     
    gs.play();
  }

  if ((mouseX >= 645 && mouseX <= 765) && (mouseY >= 250 && mouseY <= 350)) { // index[4]
    drawMode0 = false;
    drawMode1 = true;
    currIndex = 4;
    offset = 645; 
    if (moveRightCounter > oldValue && moveRightCounter < (oldValue+2)) {
      offset += putBack;
    }  
    if (moveLeftCounter > oldValue && moveLeftCounter < (oldValue+2)) {  //check if moveLeftCounter gets incremented
      offset += putBack;
    }  
    iterate += 5;
    setup();
    mode = 1;   
    gs.play();
  }
}

/*
*Returns an array of abstract pathnames denoting the files in the directory denoted by this abstract pathname.
 *@param dir is the String names of the files
 *return an array of files 
 */
File[] listFiles(String dir) {
  File file = new File(dir);
  if (file.isDirectory()) { //if the file is in the directory
    File[] files = file.listFiles(); //add them in the array
    return files;
  } 
  else {
    return null; //if not in directory
  }
}

