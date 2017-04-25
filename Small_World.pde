Game game;
PImage[] tile_sprites;

float transX, transY;
boolean dynamic_tx, dynamic_ty;
float cx, cy; 
int N;
float L;

float typo_threshhold = 0.82;

int frameStep = 300;

char moment = 'g';

void setup(){
  size( 800, 600, FX2D );
  textSize(14);
  frameRate(60);
  //surface.setResizable(true);
  cx = width/2.0f;
  cy = height/2.0f;
  
  game = new Game();
}
//{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|{{{|:|

public void draw(){
  switch( moment ){
    case 'g':
      game.exe();
      break;
  }
}