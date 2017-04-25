class Entity{
  PVector pos, ppos, facing, sprite;
  PVector[] corners;
  float speed;
  int current_I, current_J, stuck;//, next_I, next_J;
  ArrayList<PVector> path;
  boolean pathing, nexttime;
  
  float rad, dia;
  PImage walking[][];
  PImage idleing[][];
  int frame, frame_step, nMillis;
  float sprite_scale;
  
  Entity(){
    pos = new PVector(L/2f, L/2f);
    facing = new PVector();
    speed = 6;
    dia = 0.7*L;
    rad = dia/2f;
    corners = new PVector[4];
    refresh_corners();
  }
  
  void load_sprites( PImage walk, PImage idle, float sprite_scale, float xt, float yt ){
    walking = new PImage[5][4];
    idleing = new PImage[4][4];
    float w = walk.width / 5.0;
    float h = walk.height / 4.0;
    for(int i = 0; i < walking.length; i++){
      for(int j = 0; j < walking[0].length; j++){
        walking[i][j] = walk.get( round(i*w), round(j*h), round(w), round(h) );
      }
    }
    w = idle.width / 4.0;
    h = idle.height / 4.0;
    for(int i = 0; i < idleing.length; i++){
      for(int j = 0; j < idleing[0].length; j++){
        idleing[i][j] = idle.get( round(i*w), round(j*h), round(w), round(h) );
      }
    }
    frame = 0;
    frame_step = 100;// 5-> 46;
    int w_ = floor(idleing[0][0].width * sprite_scale);
    int h_ = floor(idleing[0][0].height * sprite_scale);
    for(int i = 0; i < walking.length; i++) for(int j = 0; j < walking[0].length; j++) walking[i][j].resize( w_, h_ );
    for(int i = 0; i < idleing.length; i++) for(int j = 0; j < idleing[0].length; j++) idleing[i][j].resize( w_, h_ );
    sprite = new PVector( w_ * xt, h_ * yt );
  }
  void refresh_corners(){
    corners[0] = new PVector( pos.x - rad, pos.y - rad );
    corners[1] = new PVector( pos.x + rad, pos.y - rad );
    corners[2] = new PVector( pos.x + rad, pos.y + rad );
    corners[3] = new PVector( pos.x - rad, pos.y + rad );
  }
  PVector[] movement( PVector dir ){
    if( dir.mag() > 0 ) facing = dir.get();
    else facing.setMag( 0.4 );
    dir.setMag( speed );
    PVector[] out = new PVector[4];
    out[0] = new PVector( corners[0].x + dir.x, corners[0].y + dir.y );
    out[1] = new PVector( corners[1].x + dir.x, corners[1].y + dir.y );
    out[2] = new PVector( corners[2].x + dir.x, corners[2].y + dir.y );
    out[3] = new PVector( corners[3].x + dir.x, corners[3].y + dir.y );
    return out;
  }
  void moveX( PVector dir ){
    pos.x += (dir.x);
    current_I = floor( pos.x / L );
    /* snapping
    if( pathing ){
      if( abs(dir.y) > abs(dir.x) ){
        if( abs( pos.x - ( (current_I+0.5)*L ) ) < speed ) pos.x = (current_I+0.5)*L;
      }
    }
    */
  }
  void moveY( PVector dir ){
    pos.y += (dir.y);
    current_J = floor( pos.y / L );
    /* snapping
    if( pathing ){
      if( abs(dir.x) > abs(dir.y) ){
        if( abs( pos.y - ( (current_J+0.5)*L ) ) < speed ) pos.y = (current_J+0.5)*L;
      }
    }
    */
  }
  void receive_path( float X, float Y, Map map ){
    
    ArrayList<Index> Ipath = A_Star( new Index( current_I, current_J ),
                                     new Index( floor( X / L ), floor( Y / L ) ),
                                     map );
    if( Ipath != null ){
      path = new ArrayList();
      
      for( int u = 0; u < Ipath.size(); ++u ) path.add( new PVector( (Ipath.get(u).i + 0.5)*L, (Ipath.get(u).j + 0.5)*L ) );
      
      //print( PVpath.size() );
      //*
      for( int u = 0; u < Ipath.size()-1; ++u ){
        for( int v = Ipath.size()-1; v >= u+1 ; --v ){
          ArrayList<PVector> line = Bresenham_plus( Ipath.get(u).i, Ipath.get(u).j, Ipath.get(v).i, Ipath.get(v).j );
          boolean clear = true;
          for( int z = 0; z < line.size(); ++z ){
            line.get(z).mult( L );
            if( map.map[ floor( line.get(z).x / L ) ][ floor( line.get(z).y / L ) ].solid ){
              clear = false;
              break;              
            }
          }
          if( clear ){
            for( int z = v-1; z > u; --z ){
              Ipath.remove( z );
              path.remove( z );
              --v;
            }
          }
        }
      }
      //*/
      //println(  " : "+ PVpath.size() );
      pathing = true;
      ppos = pos.get();
    }
  }
  void recalculate_path( Map map ){
    this.receive_path( path.get(0).x, path.get(0).y, map );
    println( "recalculating... " + frameCount );
  }
  PVector path_dir(Map map){
    if( dist( pos.x, pos.y, path.get(path.size()-1).x, path.get(path.size()-1).y ) <= speed ) nexttime = true;
    if( nexttime ){
      path.remove( path.size()-1 );
      if( path.size() == 0 ){
        pathing = false;
      }
      nexttime = false;
    }
    
    if( PVector.sub( pos, ppos ).mag() < speed*0.2 ) stuck++;
    else stuck = 0;
    
    if( stuck >= 6 ){
      recalculate_path( map );
      stuck = 0;
    }
    ppos = pos.get();

    if( pathing ){
      return PVector.sub( path.get(path.size()-1), pos ).normalize();
    }
    else return new PVector();
  }
  
  
  void display(){
    refresh_corners();
    
    int j = round(facing.heading() / HALF_PI);
    //println(facing.heading()/PI);
    if( j >= 4 ) j -= 4;
    if( j < 0 ) j += 4;
    if( facing.mag() > 0.5 ){
      //println(frame,j);
      image( walking[frame][j], pos.x - sprite.x, pos.y - sprite.y );
    }
    else{
      if( frame > 3 ) frame = 0;
      image( idleing[frame][j], pos.x - sprite.x, pos.y - sprite.y );
    }
    if( millis() >= nMillis ){
      if( frame == 4 ) frame = 0;
      else frame++;
      nMillis = millis() + frame_step;
    }
  }
}

//0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•|
//0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•0•|

class Map{
  Tile[][] map;
  ArrayList<Object> objects;
  
  Map( int I, int J ){
    map = new Tile[I][J];
    objects = new ArrayList();
  }

  int rows(){ return map.length; }
  int columns(){ return map[0].length; }
  float width(){ return map.length * L; }
  float height(){ return map[0].length * L; }
  
  void tick(){
    for( int j = objects.size()-1; j >= 0 ; --j ){
      if( objects.get(j).tick() ) objects.remove( j );
    }
  }
  void display(){
    int startX = constrain( floor(-transX/L), 0, map.length-1 );
    int stopX = constrain(startX + N + 2, 0, map.length );
    int startY = constrain( floor(-transY/L), 0, map[0].length-1 );
    int stopY = constrain(startY + N + 2, 0, map[0].length );
    //println( transX, transY, startX, stopX, startY, stopY );
    for(int i = startX; i < stopX; i++){
      for(int j = startY; j < stopY; j++){
        map[i][j].display(i*L, j*L);
      }
    }
    for( Object O : objects ) O.display();
  }
  void display( PGraphics pg, float l ){
    for(int i = 0; i < map.length; i++){
      for(int j = 0; j < map[0].length; j++){
        pg.fill(map[i][j].c);
        pg.rect( i*l, j*l, l, l );
      }
    }
  }
}
//O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.

class Tile{
  PImage[] sprite;
  boolean solid;
  color c;
  int frame, nMillis;
  Tile( boolean s, PImage p ){
    solid = s; 
    if( p.width != p.height ){
      float ratio = p.height/float(p.width);
      if( abs( ratio - floor(ratio) ) == 0 ){
        int n = int( ratio );
        sprite = new PImage[n];
        for( int i = 0; i < n; ++i ){
          sprite[i] = p.get( 0, i * p.width, p.width, p.width );
        }
      }
    }
    else{
      sprite = new PImage[1];
      sprite[0] = p;
    }
    frame = 0;
  }
  Tile( boolean s, color c ){
    solid = s; 
    this.c = c;
  }
  float[] destination() { return null; }
  void display( float x, float y ){
    if( sprite == null ){
      fill(c);
      rect( x, y, L, L );
    }
    else{
      image( sprite[frame], x, y );
      if( sprite.length > 1 ){
        if( millis() > nMillis){
          nMillis = millis() + frameStep;
          frame = (frame < sprite.length-1)? frame + 1 : 0 ;
        }
      }
    }
  }
  void resize(){
    if( sprite != null ){
      for( int i = 0; i < sprite.length; ++i ){
        sprite[i].resize( floor( L ), floor( L ) );
      }
    }
  }
  String type(){ return "tile"; }
}

class Path extends Tile{
  int dest;
  float x, y;
  Path( int d, float x, float y ){
    super( false, color(255, 127, 0 ) );
    dest = d;
    this.x = x;
    this.y = y;
  }
  float[] destination(){
    float[] out = { float(dest), x, y };
    return out;
  }
  String type(){ return "path"; }
}

class Farm extends Tile{
  Farm( ){ 
    super( false, tile_sprites[0] );
  }
  String type(){ return "farm"; }
}

class Grass extends Tile{
  Grass( ){
    super( false, tile_sprites[1] );
  }
  String type(){ return "grass"; }
}

class Water extends Tile{
  Water( ){
    super( true, tile_sprites[2] );
  }
  String type(){ return "water"; }
}

int tile_type( String s ){
  String[] types = {"farm", "grass", "water"};
  for( int i = 0; i < types.length; ++i ){
    if( s.equals( types[i] ) ) return i;
  }
  return -1;
}

//O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.

class Object{
  String name;
  PImage[] sprites;
  PImage solid;
  float x, y;
  int cI, cJ;
  
  int growth_step, nMillis;
  int phase, phases;
  String yield;
  int yield_amt;
  
  boolean killme = false;
  
  Object(String n ){
    name = n;
    growth_step = 0;
    phase = 0;
  }
  Object(String n, PImage[] s, PImage l ){
    name = n;
    sprites = s;
    solid = l;
    growth_step = 0;
    phase = 0;
  }
  Object(String n, PImage[] s, PImage l, int g, int p, String y, int ya, int ci, int cj ){
    name = n;
    sprites = s;
    solid = l;
    growth_step = g;
    phases = p;
    yield = y;
    yield_amt = ya;
    cI = ci;
    cJ = cj;
    nMillis = millis();
  }
  void load_sprite( PImage p ){
    sprites = new PImage[1];
    sprites[0] = p;
  }
  void set_specs( String[] data ){    
    String[] parameters = { "Click:", "Growth step:", "Phases:", "Yield:" };
    if( data != null ){
      for( int i = 0; i < data.length; ++i ){
        String[] sub_data = split( data[i], '\t' );
        if( sub_data.length == 2 ){
          float[] coinc = new float[parameters.length];
          for( int j = 0; j < parameters.length; ++j ){
            coinc[j] = coincidence( sub_data[0], parameters[j] );
          }
          int theOne = 0;
          for( int j = 1; j < parameters.length; ++j ){
            if( coinc[j] > coinc[theOne] ) theOne = j;
          }
          if( coinc[theOne] > typo_threshhold ){
            switch( theOne ){
              case 0:
                {
                  String[] line = split( sub_data[1], ' ' );
                  if( line.length == 2 ){
                    cI = int(line[0]);
                    cJ = int(line[1]);
                  }
                  else println( "ERROR: " + sub_data[1] );
                }
                break;
              case 1:
                growth_step = int( sub_data[1]);
                nMillis = millis();
                break;
              case 2:
                phases = int( sub_data[1] );
                phase = -1;
                if( sprites != null ){
                  PImage p = sprites[0].copy();
                  sprites = new PImage[phases];
                  int h = floor( p.height / float(phases) );
                  for( int j = 0; j < phases; ++j ){
                    sprites[j] = p.get( 0, j*h, p.width, h );
                  }
                }
                break;
              case 3:
                {
                  String[] line = split( sub_data[1], ' ' );
                  if( line.length == 2 ){
                    yield = line[0];
                    yield_amt = int(line[1]);
                  }
                  else println( "ERROR: " + sub_data[1] );
                }
                break;
            }
          }
        }
        else println( "ERROR: " + data[i] + ": probably no tab." );
      }
    }
  }
  void set_pos(int I, int J){
    x = (I+cI) * L;
    y = (J+cJ) * L;
  }
  boolean tick(){
    if( growth_step > 0 ){
      if( millis() > nMillis ){
        if( phase < phases-1 ){
          ++phase;
          nMillis = millis() + growth_step;
        }
      }
    }
    return killme;
  }
  boolean clicked( int I, int J, Item[] item_library, ArrayList<Item> floor_items ){
    if( ((I >= floor(x/L))&&(I < floor(x/L)+solid.width )) && ((J >= floor(y/L) )&&(J < floor(y/L)+solid.height )) ){ // se clicou dentro..
      if( growth_step > 0 && phase == phases-1 ){ // caso seja uma planta matura...
        Item it = null;
        for( int i = 0; i < item_library.length; ++i ){
          if( item_library[i].name.equals( yield ) ){
            it = item_library[i].get();
            break;
          }
        }
        if( it != null ){
          for( int i = 0; i < yield_amt; ++i ){
            it.set_pos( (I-0.5+random(-0.6, 0.6))*L, (J-0.5+random(-0.6, 0.6))*L );
            floor_items.add( it.get() );
          }
          killme = true;
          return true;
        }
      }
      //outros casos
    }
    return false;
  }
  void display(){
    image( sprites[phase], x, y );
  }
  Object get(){
    if( growth_step > 0 ) return new Object( name, sprites, solid, growth_step, phases, yield, yield_amt, cI, cJ  ); 
    return new Object( name, sprites, solid ); 
  }
  void resize(){
    if( sprites != null && solid != null){
      for(int i = 0; i < sprites.length; ++i){
        sprites[i].resize( floor( solid.width * L ), floor( solid.height * L ) );
      }
    }
  }
}

//O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.O.@.0.

class Item{
  String name;
  int count;
  boolean consumable;
  PImage sprite;
  Function[] Fs;
  
  float x, y;
  
  Item( String n ){
    name = n;
    count = 1;
    Fs = new Function[0];
  }
  Item(String n, PImage s, Function[] f, boolean c, float x, float y ){
    name = n;
    sprite = s;
    Fs = f; //new Function[f.length];
    count = 1;
    consumable = c;
    this.x = x;
    this.y = y;
    arrayCopy( f, Fs );
  }
  void set_specs( String[] data ){
    String[] parameters = { "Transform:", "Place:", "Consume:", "Consumable:" };
    Fs = new Function[data.length];
    for( int i = 0; i < data.length; ++i ){
      String[] sub_data = split( data[i], '\t' );
      if( sub_data.length == 2 ){
        float[] coinc = new float[parameters.length];
        for( int j = 0; j < parameters.length; ++j ){
          coinc[j] = coincidence( sub_data[0], parameters[j] );
        }
        int theOne = 0;
        for( int j = 1; j < parameters.length; ++j ){
          if( coinc[j] > coinc[theOne] ) theOne = j;
        }
        if( coinc[theOne] > typo_threshhold ){
          switch( theOne ){
            case 0:
              {
                String[] line = split( sub_data[1], ' ' );
                if( line.length == 2 ){
                  Fs[i] = new Transform( line[0], line[1] );
                }
                else println( "ERROR: " + sub_data[1] );
              }
              break;
            case 1:
              {
                String[] line = split( sub_data[1], ' ' );
                if( line.length == 2 ){
                  Fs[i] = new Place( line[0], line[1] );
                }
                else println( "ERROR: " + sub_data[1] );
              }
              break;
            case 2:
              {
                Fs[i] = new Consume( int(sub_data[1])  );
              }
              break;
            case 3:
              consumable = boolean( sub_data[1] );
              break;
            case 4:
              
              break;
            case 5:
              
              break;
          }
        }
      }
      else println( "ERROR: " + data[i] + ": probably no tab." );
    }
  }
  void set_pos( float x, float y ){
    this.x = x;
    this.y = y;
  }
  void exe( Map map, int I, int J, Object[] obj_library, Entity E ){
    for( int i = 0; i < Fs.length; ++i ){
      if( Fs[i] != null ){
        if( Fs[i].exe( map, I, J, obj_library, E ) ){
          if( consumable ) --count;
          break;
        }
      }
    }
  }
  void display(float X, float Y){
    image( sprite, X, Y );
  }
  void display(){
    image( sprite, x + (sprite.width*0.5), y + sprite.height );
  }
  Item get(){ return new Item( name, sprite, Fs, consumable, x, y ); }
}
//================================================================

class Function{
  boolean exe( Map map, int I, int J, Object[] obj_library, Entity E ){ return false; }
}

class Place extends Function{
  String type, obj;
  Place( String t, String o ){
    type = t;
    obj = o;
  }
  boolean exe( Map map, int I, int J, Object[] obj_library, Entity E ){
    if( map.map[I][J].type().equals( type ) ){
      Object O = null;
      for( int i = 0; i < obj_library.length; ++i ){
        if( obj_library[i].name.equals( obj ) ){
          O = obj_library[i].get();
          O.set_pos( I, J );
          break;
        }
      }
      if( O != null ){
        map.objects.add( O );
        return true;
      }
    }
    return false;
  }
}

class Transform extends Function{
  String target;
  int set;
  Transform( String t, String s ){
    target = t;
    set = tile_type( s );
  }
  boolean exe( Map map, int I, int J, Object[] obj_library, Entity E ){
    if( map.map[I][J].type().equals( target ) ){
      switch( set ){
        case 0:
          map.map[I][J] = new Farm( );
          return true;
        case 1:
          map.map[I][J] = new Grass( );
          return true;
        case 2:
          map.map[I][J] = new Water( );
          return true;
      }
    }
    return false;
  }
}

class Consume extends Function{
  int nutritional_value;
  Consume( int n ){
    nutritional_value = n;
  }
  boolean exe( Map map, int I, int J, Object[] obj_library, Entity E ){ return false; }
}