///////////////////////////////////////////////////////////////////////////////////////////////////////
// My Drawbot, "Death to Sharpie"
// Jpeg to gcode simplified (kinda sorta works version, v3.2 (beta))
//
// Scott Cooper, Dullbits.com, <scottslongemailaddress@gmail.com>
//
// PDF Export added by Jan Krummrey, jan.krummrey.de
//
// Open creative GPL source commons with some BSD public GNU foundation stuff sprinkled in...
// If anything here is remotely useable, please give me a shout.
///////////////////////////////////////////////////////////////////////////////////////////////////////
import javax.swing.JFileChooser;
import javax.swing.filechooser.FileNameExtensionFilter;
// Constants set by user, or maybe your sister.
final float   paper_size_x = 32 * 25.4;
final float   paper_size_y = 40 * 25.4;
final float   image_size_x = 30 * 25.4;
final float   image_size_y = 35 * 25.4;
final float   paper_top_to_origin = 417;  //mm

// Super fun things to tweak.  Not candy unicorn type fun, but still...
int     squiggle_total = 300;     // Total times to pick up the pen
int     squiggle_length = 200;    // Too small will fry your servo
int     half_radius = 5;          // How grundgy
int     adjustbrightness = 4;     // How fast it moves from dark to light, over draw
float   sharpie_dry_out = 0.25;   // Simulate the death of sharpie, zero for super sharpie

final JFileChooser chooser = new JFileChooser();

//Every good program should have a shit pile of badly named globals.
String  pic_path = "";
int    screen_offset = 4;
float  screen_scale = 1.0;
int    steps_per_inch = 25;
int    x_old = 0;
int    y_old = 0;
PImage img;
int    darkest_x = 100;
int    darkest_y = 100;
float  darkest_value;
int    squiggle_count;
int    x_offset = 0;
int    y_offset = 0;
float  drawing_scale;
float  drawing_scale_x;
float  drawing_scale_y;
int    drawing_min_x =  9999999;
int    drawing_max_x = -9999999;
int    drawing_min_y =  9999999;
int    drawing_max_y = -9999999;
int    center_x;
int    center_y;
boolean is_pen_down;
boolean stop_drawing = false;
PrintWriter OUTPUT;       // instantiation of the JAVA PrintWriter object.

import processing.pdf.*;

// Menu additions
import controlP5.*;
ControlP5 cp5;
Accordion accordion;
color c = color(0, 160, 100);

///////////////////////////////////////////////////////////////////////////////////////////////////////
void setup() {
  size(900, 975, P2D);
  noSmooth();
  colorMode(HSB, 360, 100, 100, 100);
  background(0, 0, 100);  
  frameRate(120);
  gui();
  OUTPUT = createWriter("gcode.g");
  beginRecord(PDF, "output.pdf"); 
  pen_up();
  setup_squiggles();
  img.loadPixels();
 
}

///////////////////////////////////////////////////////////////////////////////////////////////////////
void draw() {
    noFill();
    scale(screen_scale);
    random_darkness_walk();
  
    if (squiggle_count >= squiggle_total) {
        endRecord();
        //grid();
        //dump_some_useless_stuff_and_close();
        stop_drawing = true;
        //noLoop();
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////
void setup_squiggles() {
  img = loadImage(pic_path);  // Load the image into the program  
  img.loadPixels();
  
  drawing_scale_x = image_size_x / img.width;
  drawing_scale_y = image_size_y / img.height;
  drawing_scale = min(drawing_scale_x, drawing_scale_y);

  println("Picture: " + pic_path);
  println("Image dimensions: " + img.width + " by " + img.height);
  println("adjustbrightness: " + adjustbrightness);
  println("squiggle_total: " + squiggle_total);
  println("squiggle_length: " + squiggle_length);
  println("Paper size: " + nf(paper_size_x,0,2) + " by " + nf(paper_size_y,0,2) + "      " + nf(paper_size_x/25.4,0,2) + " by " + nf(paper_size_y/25.4,0,2));
  println("Max image size: " + nf(image_size_x,0,2) + " by " + nf(image_size_y,0,2) + "      " + nf(image_size_x/25.4,0,2) + " by " + nf(image_size_y/25.4,0,2));
  println("Calc image size " + nf(img.width * drawing_scale,0,2) + " by " + nf(img.height * drawing_scale,0,2) + "      " + nf(img.width * drawing_scale/25.4,0,2) + " by " + nf(img.height * drawing_scale/25.4,0,2));
  println("Drawing scale: " + drawing_scale);

  // Used only for gcode, not screen.
  x_offset = int(-img.width * drawing_scale / 2.0);  
  y_offset = - int(paper_top_to_origin - (paper_size_y - (img.height * drawing_scale)) / 2.0);
  println("X offset: " + x_offset);  
  println("Y offset: " + y_offset);  

  // Used only for screen, not gcode.
  center_x = int(width  / 2 * (1 / screen_scale));
  center_y = int(height / 2 * (1 / screen_scale) - (steps_per_inch * screen_offset));
}

///////////////////////////////////////////////////////////////////////////////////////////////////////
void grid() {
  // This will give you a rough idea of the size of the printed image, in inches.
  // Some screen scales smaller than 1.0 will sometimes display every other line
  // It looks like a big logic bug, but it just can't display a one pixel line scaled down well.
  stroke(0, 50, 100, 30);
  for (int xy = -30*steps_per_inch; xy <= 30*steps_per_inch; xy+=steps_per_inch) {
    line(xy + center_x, 0, xy + center_x, 200000);
    line(0, xy + center_y, 200000, xy + center_y);
  }

  stroke(0, 100, 100, 50);
  line(center_x, 0, center_x, 200000);
  line(0, center_y, 200000, center_y);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////
void dump_some_useless_stuff_and_close() {
  println ("Extreams of X: " + drawing_min_x + " thru " + drawing_max_x);
  println ("Extreams of Y: " + drawing_min_y + " thru " + drawing_max_y);
  OUTPUT.flush();
  OUTPUT.close();
}

///////////////////////////////////////////////////////////////////////////////////////////////////////
void gui() {
  cp5 = new ControlP5(this);

  cp5.addTextlabel("squiggle_total_label")
                    .setText("Squiggle total")
                    .setPosition(10,15)
                    .setColorValue(0x00)
                    //.setFont(createFont("Georgia",20))
                    ;
  cp5.addNumberbox("squiggle_total_box")
     .setPosition(100,10)
     .setSize(40,19)
     .setRange(0,1000)
     .setScrollSensitivity(1)
     .setValue(300)
     ;
  cp5.addTextlabel("squiggle_length_label")
                    .setText("Squiggle length")
                    .setPosition(10,35)
                    .setColorValue(0x00)
                    //.setFont(createFont("Georgia",20))
                    ;
  cp5.addNumberbox("squiggle_length_box")
     .setPosition(100,30)
     .setSize(40,19)
     .setRange(0,1000)
     .setScrollSensitivity(1)
     .setValue(300)
     ;
  cp5.addTextlabel("half_radius_label")
                    .setText("Half radius")
                    .setPosition(10,55)
                    .setColorValue(0x00)
                    //.setFont(createFont("Georgia",20))
                    ;
  cp5.addNumberbox("half_box")
     .setPosition(100,50)
     .setSize(40,19)
     .setRange(2,20)
     .setScrollSensitivity(1.1)
     .setValue(half_radius)
     ;
  cp5.addTextlabel("brightness_label")
                    .setText("Brightness")
                    .setPosition(10,75)
                    .setColorValue(0x00)
                    //.setFont(createFont("Georgia",20))
                    ;
  cp5.addNumberbox("brightness_box")
     .setPosition(100,70)
     .setSize(40,19)
     .setRange(2,20)
     .setMultiplier(0.1)
     .setScrollSensitivity(1.1)
     .setValue(adjustbrightness)
     ;
  cp5.addTextlabel("sharpie_label")
                    .setText("Sharpie Dry Out")
                    .setPosition(10,95)
                    .setColorValue(0x00)
                    //.setFont(createFont("Georgia",20))
                    ;
  cp5.addNumberbox("sharpie_box")
     .setPosition(100,90)
     .setSize(40,19)
     .setRange(0,20)
     .setMultiplier(0.01)
     .setValue(0.25)
     ;
     
  cp5.addButton("Open")
     .setValue(0)
     .setPosition(100,130)
     .setSize(100,19)
     ;
  cp5.addButton("ReDraw")
     .setValue(0)
     .setPosition(100,110)
     .setSize(100,19)
     ;
}

public void ReDraw() {
  OUTPUT = createWriter("gcode.g");
  beginRecord(PDF, "output.pdf"); 
  pen_up();
  squiggle_count = 0;
  background(0, 0, 100);  
  setup_squiggles();
  stop_drawing = false;
}

public void Open(){
FileNameExtensionFilter filter = new FileNameExtensionFilter(
        "JPG & GIF Images", "jpg", "gif");
    chooser.setFileFilter(filter);
    int returnVal = chooser.showOpenDialog(Death_to_Sharpie_PDF_2.this);
    if(returnVal == JFileChooser.APPROVE_OPTION) {
            
            pic_path=chooser.getSelectedFile().getAbsolutePath();
    }
}

void squiggle_total_box(int new_amount) {
  squiggle_total = new_amount;
  println("a numberbox event. setting squiggle total to " + new_amount);
}

void squiggle_length_box(int new_amount) {
  squiggle_length = new_amount;
  println("a numberbox event. setting squiggle length to " + new_amount);
}

void half_box(int new_amount) {
  half_radius = new_amount;
  println("a numberbox event. setting half radius to " + new_amount);
}

void brightness_box(int new_amount) {
  adjustbrightness = new_amount;
  println("a numberbox event. setting brightness to " + new_amount);
}

void sharpie_box(float new_amount) {
  sharpie_dry_out = new_amount;
  println("a numberbox event. setting sharpie dry out to " + new_amount);
}

