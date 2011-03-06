
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

/******************* MANAGES A SINGLE 'PAD' **************************/

public class CamPianoPad {
  int posX, posY;              // top left position of pad in camera image coordinates
  int sizeX, sizeY;            // size of pad in camera image coordinates
  int index;                   // index of this pad

  float normalizeMult;         // factor to normalize amount of movement
  float movement;
  float movementLastFrame;
  boolean wasOnLastFrame;

  float targetDrawValue;              // target number to determine drawing alpha
  float currentDrawValue;              // actual used draw value, this lerps to the above

    CamPianoPad(int _index, float _posX, float _posY, float _sizeX, float _sizeY) {
    init(_index, _posX, _posY, _sizeX, _sizeY);
  }

  void init(int _index, float _posX, float _posY, float _sizeX, float _sizeY) {
    index = (int)_index;
    posX = (int)_posX;
    posY = (int)_posY;
    sizeX = (int)_sizeX;
    sizeY = (int)_sizeY;

    normalizeMult = 1.0/(sizeX * sizeY * 255.0);
    movement = 0;
    movementLastFrame = 0;
    wasOnLastFrame = false;
    targetDrawValue = 0;
    currentDrawValue = 0;

    println(" New pad created " + index + ", " + posX + ", " + posY + ", " + sizeX + ", " + sizeY);

  }

  void checkMotion(color []differencedPixels, int camWidth) {    // pass in pointer to differenced cam data
    movement = 0;
    for(int y=0; y<sizeY; y++) {
      for(int x=0; x<sizeX; x++) {
        int camPosX = posX + x;
        int camPosY = posY + y;
        int camIndex = camPosY * camWidth + camPosX;

        movement += differencedPixels[camIndex] & 0xFF;  // only get lower 8 bits
      }
    }
    movement *= normalizeMult;            // normalize movement amount based on number of pixels in the pad
    movement = max(movement, movementLastFrame * decayAmount);
    movementLastFrame = movement;
  }


  void sendSignal(Scale currentScale) {
    boolean bNowOn = (movement > triggerThreshold * 0.1);
    //    if(bNowOn) targetDrawValue = movement * 1500 + 150;
    //    else targetDrawValue = 10;
//    if(bNowOn) targetDrawValue = 1;
//    else targetDrawValue = 0;

    if(bNowOn != wasOnLastFrame) {
      //      println("Memo is sending " + bNowOn + " for " + index);   
      int octave = floor(index / currentScale.noteCount);    // this is which octave we are in
      int noteInOctave = index % currentScale.noteCount;    // this is the note number relative to the octave

      int midiNoteNum = rootNote + octave * 12 + currentScale.intervals[noteInOctave];
      float midiNoteNumScaled = midiNoteNum / 127.0;

      OscMessage oscMessage = new OscMessage(oscTargetAddress);
      oscMessage.add(midiNoteNumScaled);
      oscMessage.add(movement * velocityMult);
      oscMessage.add(index);
      oscMessage.add(bNowOn);
      oscP5.send(oscMessage, address);
      
      targetDrawValue = 1 - targetDrawValue;
    }

    wasOnLastFrame = bNowOn;
  }


  void draw(float scaleFactor) {
    noStroke();
    if(targetDrawValue > currentDrawValue) currentDrawValue += (targetDrawValue - currentDrawValue) * 0.5;
    else currentDrawValue += (targetDrawValue - currentDrawValue) * 0.2;
    fill(255, 50 + 255 * currentDrawValue);
//    fill(255);
    pushMatrix();
    float sx = sizeX * scaleFactor;
    float sy = sizeY * scaleFactor;
    translate(posX * scaleFactor + sx/2, posY * scaleFactor + sy/2);
//    rotateX(radians(currentDrawValue * 180) );
    rect(-sx/2, -sy/2, sx, sy);
    popMatrix();
  }

}

