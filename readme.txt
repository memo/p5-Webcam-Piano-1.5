/***********************************************************************
 * Use the webcam to play a virtual piano. Adjustable gridsize, harmonics, scale etc.
 * See http://msavisuals.com/webcam_piano_20 for demo
 * (though that is a more advanced version written in C++, concept is the same)
 * 
 * Note that this app doesn't actually produce sound,
 * it just sends note on/off data with velocity as OSC:
 * /msa/note [float:pitch] [float:velocity] [int:uniqueindex] [bool:on]
 * pitch: 0...1; // midi note number mapped from 0...127 to 0...1
 * velocity: 0...1; // midi velocity mapped from 0...127 to 0...1
 * uniqueindex: this is a unique number (could be midi note number), its only needed for osculator
 * on: 0 or 1 (noteon or noteoff)
 *
 * If you want to use midi, you can use maxmsp, pd etc. to map the osc to midi
 * OR on mac you can use http://www.osculator.net/
 * thats what the webcam piano 1.5.oscd is for
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

// Includes Super Fast Blur v1.1
// by Mario Klingemann 
// <http://incubator.quasimondo.com>
// ==================================================
 ***********************************************************************/