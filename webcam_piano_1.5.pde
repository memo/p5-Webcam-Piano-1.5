/***********************************************************************
 * 
 * Copyright (c) 2008, Memo Akten, www.memo.tv
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * 	
 ***********************************************************************/

import oscP5.*;
import netP5.*;
import processing.video.*;
import controlP5.*;


/**************************** CONSTS **********************************/
final int CONTROL_ID_GRIDSIZE = 1;

final int oscTargetPort         = 8000;
final String oscTargetIP        = "127.0.0.1";
final String oscTargetAddress   = "/msa/note";

final float padSpacing          = 0.05;               // spacing of squares 
final float vidMult             = 0.3125;                // ratio of camera resolution to output res
final float vidMultInv          = 1.0/vidMult;        // inverse 
final int fps                   = 15;

final int SCALE_CHROMATIC       = 0;
final int SCALE_DIMINISHED      = 1;
final int SCALE_PENTATONIC      = 2;
final int SCALE_PENTATONIC_CHR  = 3;
final int SCALE_MAJOR           = 4;
final int SCALE_MINOR           = 5;
final int SCALE_HICAZ           = 6;
final int SCALES_COUNT          = 7;
Scale scales[] = new Scale[SCALES_COUNT];

/**************************** VARS **********************************/
OscP5 oscP5;
NetAddress address;

int numPixels;                       // total number of pixels in camera feed
int[] prevGrey;                      // array of grey values for previous frame 
Capture video;                       // video capture device

int padCount;                        // total number of pads
CamPianoPad[] pads;                  // array of pads

PImage imgDiff;                      // image storing frame difference
PImage imgCam;                       // image storing camera feed (flipped or not)


/**************************** APP PARAMETERS (ADJUSTABLE THROUGH THE UI) ***********************************/
float triggerThreshold = 0.2;        // trigger note if movement is above this
int rootNote = 36;                   // midi note number for pad at bottom left
float decayAmount = 0.5;             // how long to hold a triggered note before switching it off
float velocityMult = 20;             // multipler for movement amount -> midi velocity
int blurAmount = 2;                  // how much to blur camera feed (reduces noise)
int numPadX = 8;                     // number of pads horizontally
int numPadY = 6;                     // number of pads vertically
int currentScaleNum = SCALE_PENTATONIC;   // musical scale to use
boolean flipHorizontal = true;       // flip horizontal or not
boolean showDifference = false;      // show frame difference or not

/**************************** SETUP ***********************************/
void setup() {
    size(1024, 768); 
  hint(DISABLE_DEPTH_TEST);

    video = new Capture(this, (int) (width * vidMult), (int) (height * vidMult), fps);
    numPixels = video.width * video.height;
    prevGrey = new int[numPixels];
    imgDiff = createImage(video.width, video.height, RGB);  // this should be 8-bit greyscale, but no option in processing!
    imgCam = createImage(video.width, video.height, RGB);  // this should be 8-bit greyscale, but no option in processing!

    initScales();
    initOSC();
    initUI();
    initPads();

    frameRate(fps);
   
}

void initScales() {
    scales[SCALE_CHROMATIC] = new Scale(12, "Chromatic",              new int[] { 
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11                         } 
    );
    scales[SCALE_DIMINISHED] = new Scale(4, "Diminished",             new int[] { 
        0, 3, 6, 9                         } 
    );
    scales[SCALE_PENTATONIC] = new Scale(5, "Pentatonic",               new int[] { 
        0, 3, 5, 7, 10                         } 
    );
    scales[SCALE_PENTATONIC_CHR] = new Scale(7, "Pentatonic + chromatics", new int[] { 
        0, 3, 5, 6, 7, 10, 11                         } 
    );
    scales[SCALE_MAJOR] = new Scale(7, "Major",                   new int[] { 
        0, 2, 4, 5, 7, 9, 11                         } 
    );
    scales[SCALE_MINOR] = new Scale(7, "Minor",                   new int[] { 
        0, 2, 3, 5, 7, 8, 10                         }  
    );
    scales[SCALE_HICAZ] = new Scale(7, "Zirguleli Hicaz",        new int[] {  
        0, 1, 4, 5, 7, 8, 11                         }  
    );
}


/**************************** INIT OSC INFO *********************************/
void initOSC() {
    oscP5 = new OscP5(this, oscTargetPort);
    address = new NetAddress(oscTargetIP, oscTargetPort);
}


/**************************** CREATE TABS, SLIDERS AND UI COMPONENTS ***********************************/
void initUI() {
    int sliderWidth = (int) (width * 0.5);
    int sliderHeight = 15;
    int y;
    int yinc = 20;
    ControlP5 controlP5 = new ControlP5(this);
    controlP5.tab("default").setLabel(" HIDE ");
    y = yinc;
    controlP5.addSlider("numPadX", 1, 40, numPadX, 20, y += yinc, sliderWidth, sliderHeight).setTab("Main Options");
    controlP5.addSlider("numPadY", 1, 40, numPadY, 20, y += yinc, sliderWidth, sliderHeight).setTab("Main Options");
    controlP5.addSlider("triggerThreshold", 0, 2, triggerThreshold, 20, y += yinc, sliderWidth, sliderHeight).setTab("Main Options");
    controlP5.addSlider("decayAmount", 0, 1, decayAmount, 20, y += yinc, sliderWidth, sliderHeight).setTab("Main Options");
    controlP5.addSlider("blurAmount", 0, 20, blurAmount, 20, y += yinc, sliderWidth, sliderHeight).setTab("Main Options");
    controlP5.addSlider("velocityMult", 1, 100, velocityMult, 20, y += yinc, sliderWidth, sliderHeight).setTab("Main Options");
    controlP5.addSlider("rootNote", 0, 96, rootNote, 20, y += yinc, sliderWidth, sliderHeight).setTab("Main Options");
    controlP5.addSlider("currentScaleNum", 0, SCALES_COUNT-1, currentScaleNum, 20, y += yinc, sliderWidth, sliderHeight).setTab("Main Options");

    y = yinc;
    controlP5.addToggle("flipHorizontal", 20, y += yinc, sliderWidth /2 -10 , sliderHeight * 2).setTab("Display Options");
    controlP5.addToggle("showDifference", 20 + sliderWidth /2 + 10, y, sliderWidth /2 - 10, sliderHeight * 2).setTab("Display Options");

    controlP5.controller("numPadX").setId(CONTROL_ID_GRIDSIZE);
    controlP5.controller("numPadY").setId(CONTROL_ID_GRIDSIZE);  
}



/**************************** ALLOCATE MEMORY FOR GRID VARS ***********************************/
void initPads() {
    padCount = numPadX * numPadY;
    float padSizeX = video.width * 1.0 / numPadX;
    float padSizeY = video.height * 1.0 / numPadY;
    float paddingMult = (1 - 2 * padSpacing);

    pads = new CamPianoPad[padCount];
    for(int i=0; i<padCount; i++) {
        int padX = i % numPadX;
        int padY = floor(i / numPadX);
        float posX = padSizeX * padX + padSizeX * padSpacing;
        float posY = video.height - padSizeY * (padY + 1) + padSizeY * padSpacing; // flip verticall so lower notes are at the bottom
        pads[i] = new CamPianoPad(i, posX, posY, padSizeX *paddingMult, padSizeY * paddingMult);
    }

}


/**************************** UPDATE ***********************************/
void draw() {
  background(0);
//    if (video.available()) {
        differenceCamFrames();
        drawCam();
        updateAndDrawAllPads();
//    }
}


/**************************** VISION ***********************************/
void differenceCamFrames() {
    video.read(); // Read the new frame from the camera
    video.loadPixels();
    superFastBlur(video, blurAmount);

    imgDiff.loadPixels();
    imgCam.loadPixels();

    for (int i=0; i<numPixels; i++) {
        int posX = i % video.width;
        int posY = floor(i / video.width);

        if(flipHorizontal) posX = video.width - posX - 1;

        color curColor = video.pixels[i];
        int curR = (curColor >> 16) & 0xFF;
        int curG = (curColor >> 8) & 0xFF;
        int curB = curColor & 0xFF;
        // average RGB components (there are better ways of calculating intensity from RGB, but this will suffice for these purposes)
        int curGrey = (curR + curG + curB) / 3; 
        int diff = abs(curGrey - prevGrey[i]);
        imgDiff.pixels[posY * video.width + posX] = diff + (diff<<8) + (diff<<16);
        imgCam.pixels[posY * video.width + posX] = video.pixels[i];

        prevGrey[i] = curGrey;
    }

    imgDiff.updatePixels();    // always update this, needed for triggering
}



void drawCam() {
    if(showDifference) image(imgDiff, 0, 0, width, height);
    else {
        imgCam.updatePixels();
        image(imgCam, 0, 0, width, height);
    }
}


void updateAndDrawAllPads() {
    for(int i=0; i<padCount; i++) {
        pads[i].checkMotion(imgDiff.pixels, video.width);
        pads[i].sendSignal(scales[currentScaleNum]);
        pads[i].draw(vidMultInv);
    }
}


/**************************** CALLBACK FOR CONTROLS ***********************************/
void controlEvent(ControlEvent theEvent) {
    mousePressed = false;
    switch(theEvent.controller().id()) {
    case CONTROL_ID_GRIDSIZE: 
        initPads(); 
        break;  
    }
}
