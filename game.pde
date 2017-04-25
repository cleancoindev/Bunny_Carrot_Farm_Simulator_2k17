class Game{
  Map[] world;
  Entity Player;
  Object[] obj_library;
  Item[] item_library;
  Item[] player_items;
  ArrayList<Item> floor_items;
  int selected;
  PImage item_display_grid, item_display_numbers, item_display_selection;
  float idg_x, idg_y, idg_l;
  
  int currentMap = 1;
  
  boolean w, a, s, d;
  
  int[][] y_index;
  float pPy;
  
  
  Game(){ //- - - - - - - - - - - - - - - - - - - - - - - - - - CONSTRUCTOR - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  
    L = 40;
    N = floor(width/L);
    
    //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - MAP SPRITES - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    
    File file = new File(sketchPath() + "\\data\\world\\tiles\\");
    String[] l = file.list();
    tile_sprites = new PImage[l.length];
    for(int i = 0; i < l.length; i++){
      tile_sprites[i] = loadImage( sketchPath() + "\\data\\world\\tiles\\" + l[i] );
    }
    
    //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - LOAD MAP FILES - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    
    file = new File(sketchPath() + "\\data\\world\\");
    l = file.list();
    PImage[] rooms = new PImage[0];
    String[] conns = new String[0];
    for(int i = 0; i < l.length; i++){
      String[] q = split( l[i], '.' );
      if( q[q.length-1].equals("png") ){
        rooms = (PImage[]) append( rooms, loadImage( "\\world\\"+l[i] ));
      }
      else if( q[0].equals("connections") ){
        conns = loadStrings( "\\world\\"+l[i] );
      }
    }
    
    //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - BUILD MAP - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    
    world = new Map[rooms.length];
    for(int o = 0; o < world.length; o++){
      world[o] = new Map( rooms[o].width, rooms[o].height );
      for(int i = 0; i < rooms[o].width; i++){
        for(int j = 0; j < rooms[o].height; j++){
          switch( rooms[o].get(i, j) ){
            case 0xff000000:
              world[o].map[i][j] = new Tile( true, color(0) );
              break;
            case 0xffFFFFFF:
              world[o].map[i][j] = new Tile(  false, color(255) );
              break;
            case 0xff7F7F7F:
              world[o].map[i][j] = new Tile( true, color(127) );
              break;
            case #786446:
              world[o].map[i][j] = new Tile(  true, #786446 );
              break;
            case #5ba0db:
              world[o].map[i][j] = new Water();
              break;
            case #6df483:
              world[o].map[i][j] = new Grass();
              break;
            case 0xffFF7F00:
              float[] d = find_connection( o, i, j, conns );
              if( d.length == 3 ) world[o].map[i][j] = new Path( round(d[0]), d[1], d[2] );
              else {
                world[o].map[i][j] = new Tile( false, 0xffFF7F00 );
                println( "unconnected path: " + o + ": " + i + "x" + j );
              }
              break;
            default:
              world[o].map[i][j] = new Tile( false, rooms[o].get(i, j) );
              break;
          }
          
        }
      }
    }
    configure_translation();
    
    //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - BUILD OBJ_LIBRARY - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    {
      file = new File(sketchPath() + "\\data\\world\\objects\\");
      l = file.list();
      obj_library = new Object[ floor( l.length / 3.0 ) ];
      int filled = 0;
      String[] suffixes = { ".png", " solid.png", ".txt" };
      for(int i = 0; i < l.length; i++){
        int end = 0;
        for( int j = 0; j < l[i].length(); ++j ){
          if( l[i].charAt(j) == ' ' || l[i].charAt(j) == '.' ){
            end = j;
            break;
          }
        }
        String name = l[i].substring( 0, end );
        int theEQ = -1;
        for( int j = 0; j < filled; ++j ){
          if( name.equals( obj_library[j].name ) ){
            theEQ = j;
            break;
          }
        }  
        if( theEQ == -1 ){
          theEQ = filled;
          obj_library[theEQ] = new Object( name );
          ++filled;
        }
        
        String suffix = l[i].substring( end );
        int theType = -1;
        for( int j = 0; j < suffixes.length; ++j ){
          if( suffix.equals( suffixes[j] ) ){
            theType = j;
            break;
          }
        }
        if( theType >= 0 ){
          switch( theType ){
            case 0: // sprite
              obj_library[theEQ].load_sprite( loadImage( sketchPath() + "\\data\\world\\objects\\" + l[i] ) );
              break;
            case 1: // solid
              obj_library[theEQ].solid =  loadImage( sketchPath() + "\\data\\world\\objects\\" + l[i] );
              break;
            case 2: //txt;
              obj_library[theEQ].set_specs( loadStrings(sketchPath() + "\\data\\world\\objects\\" + l[i] ) );
              break;
          }
        }
        else println( "ERROR: file has either too many or too few '.'" );
      }
    }
    //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - BUILD ITEM_LIBRARY - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    {
      file = new File(sketchPath() + "\\data\\world\\items\\");
      l = file.list();
      item_library = new Item[ floor( l.length * 0.5 ) ];
      int filled = 0;
      String[] suffixes = { ".png", ".txt" };
      for(int i = 0; i < l.length; i++){
        int end = 0;
        for( int j = 0; j < l[i].length(); ++j ){
          if( l[i].charAt(j) == ' ' || l[i].charAt(j) == '.' ){
            end = j;
            break;
          }
        }
        String name = l[i].substring( 0, end );
        int theEQ = -1;
        for( int j = 0; j < filled; ++j ){
          if( name.equals( item_library[j].name ) ){
            theEQ = j;
            break;
          }
        }  
        if( theEQ == -1 ){
          theEQ = filled;
          item_library[theEQ] = new Item( name );
          ++filled;
        }
        
        String suffix = l[i].substring( end );
        int theType = -1;
        for( int j = 0; j < suffixes.length; ++j ){
          if( suffix.equals( suffixes[j] ) ){
            theType = j;
            break;
          }
        }
        if( theType >= 0 ){
          switch( theType ){
            case 0: // sprite
              item_library[theEQ].sprite = loadImage( sketchPath() + "\\data\\world\\items\\" + l[i] );
              break;
            case 1: //txt;
              item_library[theEQ].set_specs( loadStrings(sketchPath() + "\\data\\world\\items\\" + l[i] ) );
              break;
          }
        }
        else println( "ERROR: file has either too many or too few '.'" );
      }
    }
    //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - LOAD MAP OBJECTS - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    
    l = loadStrings( sketchPath() + "\\data\\world\\objects.txt" );
    for(int i = 0; i < l.length; i++){
      String[] sl = split( l[i], '\t' );
      if( sl.length == 3 ){
        int map = int( sl[1] );
        if( map >= 0 ){
          String name = sl[0];
          Object obj = null;
          for(int j = 0; j < obj_library.length; ++j ){
            if( obj_library[j].name.equals( name ) ){
              obj = obj_library[j].get();
              break;
            }
          }
          if( obj != null ){
            String[] ssl = split( sl[2], ' ' );
            obj.x = float( ssl[0] ) * L;
            obj.y = float( ssl[1] ) * L;
                 
            world[ map ].objects.add( obj );
          }
        }
      }
    }    
    //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - PLAYER - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    
    Player = new Entity();
    Player.load_sprites( loadImage("bunny walk.png"), loadImage("bunny idle.png"), L/16, 0.5, 0.85 );
  
    Player.pos = new PVector( 49.5 * L, 39.5 * L );
    
    player_items = new Item[9];
    player_items[0] = item_library[1].get();
    player_items[1] = item_library[0].get();
    selected = 1;
    
    this.resize(40);
    
    floor_items = new ArrayList();
    
    item_display_grid = loadImage( "item display grid.png" );
    idg_x = width - item_display_grid.width;
    idg_y = height - item_display_grid.height;
    idg_l = ( item_display_grid.width - 4 ) / 3.0;
    item_display_numbers = loadImage( "item display number.png" );
    item_display_selection = loadImage( "item display selection.png" );

  }//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  void resize( float nl ){
    L = nl;
    
    for(int i = 0; i < obj_library.length; ++i){
      obj_library[i].resize();
    }
    for(int i = 0; i < tile_sprites.length; ++i){
      tile_sprites[i].resize( int(L), round((tile_sprites[i].height/tile_sprites[i].width)*L) );
    }
    //for(int i = 0; i < item_library.length; ++i){
    //  item_library[i].resize();
    //}
    
    for( int m = 1; m < world.length; ++m ){
      for(int o = 0; o < world[ m ].objects.size(); ++o){
        world[ m ].objects.get( o ).resize();
      }
      for(int i = 0; i < world[m].map.length; ++i){
        for(int j = 0; j < world[m].map[0].length; j++){
          world[ m ].map[i][j].resize();
        }
      }
    }
  }
  
  void update_y_index(){
    int size = 0;
    for( int m = 0; m < world.length; ++m ){
      if( world[m].objects.size() > size ){
        size = world[m].objects.size();
      }
    }
    float[][] ys = new float[world.length][ size+1 ];
    y_index = new int[world.length][ size+1 ];
    for( int m = 0; m < world.length; ++m ){
      for( int o = 0; o < size-1; ++o ){
        if( o < world[m].objects.size()){
          ys[m][o] = world[m].objects.get(o).y + world[m].objects.get(o).sprites[0].height;
          y_index[m][o] = o;
        }
        else{
          ys[m][o] = 100000000;
          y_index[m][o] = -2;
        }
      }
      ys[m][size-1] = Player.pos.y;
      y_index[m][size-1] = -1;
      
      boolean x = true;
      while ( x ) {
        x = false;
        for (int i = 0; i< ys.length-1; i++) {
          if (ys[m][i] > ys[m][i+1]) {
            float q = ys[m][i+1];
            ys[m][i+1] = ys[m][i];
            ys[m][i] = q;
    
            int Q = y_index[m][i+1];
            y_index[m][i+1] = y_index[m][i];
            y_index[m][i] = Q;
            x = true;
          }
        }
      }
    }
  }
  
  //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - CONTROLS - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  void keyTyped() {
    if (key == 'w' || key == 'W') w = true; 
    if (key == 's' || key == 'S') s = true; 
    if (key == 'a' || key == 'A') a = true; 
    if (key == 'd' || key == 'D') d = true;
    else if( key == '1' || key == '2' || key == '3' || 
             key == '4' || key == '5' || key == '6' || 
             key == '7' || key == '8' || key == '9' ) selected = int(key)-49 ;
    Player.pathing = false;
  }
  void keyReleased(){
    if (key == 'w' || key == 'W') w = false;
    if (key == 's' || key == 'S') s = false;
    if (key == 'a' || key == 'A') a = false; 
    if (key == 'd' || key == 'D') d = false;
  }
  
  void mouseReleased(){
    PVector M = new PVector( mouseX - transX, mouseY -transY );
    if( mouseButton == LEFT ){
      int I = floor( M.x / L );
      int J = floor( M.y / L );
      if( Player.pos.dist( M ) < 1.5 * L ){
        boolean interacted_w_obj = false;
        for( int i = 0; i < world[ currentMap ].objects.size(); ++i ){
          if( world[ currentMap ].objects.get(i).clicked( I, J, item_library, floor_items ) ){
            interacted_w_obj = true;
            break;
          }
        }
        if( !interacted_w_obj && player_items[selected] != null ){
          player_items[selected].exe( world[ currentMap ], I, J, obj_library, Player );
        }
      }
      /*
      if( Player.pos.dist( M ) < 1.5 * L ){
        int I = floor( M.x / L );
        int J = floor( M.y / L );
        if( world[ currentMap ].map[I][J] instanceof Grass ){
          world[ currentMap ].map[I][J] = new Farm( );
        }
      }
      */
    }
    else if( mouseButton == RIGHT ){ //Player.pos = new PVector(mouseX-transX, mouseY-transY);
      //Entity ent = Player;
      Player.receive_path( M.x, M.y, world[currentMap] );
    }
  }
  void mouseWheel(MouseEvent E) {
    float wheel = E.getAmount();
    if (wheel == 1) selected = ( selected < 9 )? ++selected : 0;
    else if (wheel == -1) selected = ( selected > 0 )? --selected : 8;
  }
  
  //- - - - - - - - - - - - - - - - - - - - - - - - - TRANSLATION - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  
  void configure_translation(){
    if( world[currentMap].width() <= width ){
      transX = (width - world[currentMap].width()) / 2.0;
      dynamic_tx = false;
    }
    else dynamic_tx = true;
    
    if( world[currentMap].height() <= height ){
      transY = (height - world[currentMap].height()) / 2.0;
      dynamic_ty = false;
    }
    else dynamic_ty = true;
  }
  
  void update_translation(){
    if( dynamic_tx ){
      if( Player.pos.x - cx < 0 ) transX = 0;
      else if( Player.pos.x + cx > world[currentMap].width() ) transX = -world[currentMap].width() + width;
      else transX = -Player.pos.x + cx;
    }
    if( dynamic_ty ){
      if( Player.pos.y - cy < 0 ) transY = 0;
      else if( Player.pos.y + cy > world[currentMap].height() ) transY = -world[currentMap].height() + height;
      else transY = -Player.pos.y + cy;
    }
  }
  
  void exe(){//- - - - - - - - - - - - - - - - - - - - - - - - - EXE - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    background(0);
    
    println( currentMap, Player.pos.x, Player.pos.y );
    
    for( int i = 0; i < player_items.length; ++i ){
      if( player_items[i] != null ) if( player_items[i].count <= 0 ) player_items[i] = null;
    }
    
    for( int j = 1; j < world.length; ++j ){
      world[j].tick(); 
    }
    
    for( int j = floor_items.size()-1; j >= 0 ; --j ){
      if( dist( Player.pos.x, Player.pos.y, floor_items.get(j).x, floor_items.get(j).y ) < 1.2 * L ){
        boolean added = false;
        for( int i = 0; i < player_items.length; ++i ){
          if( player_items[i] != null ){
            if( player_items[i].name.equals( floor_items.get(j).name ) ){
              player_items[i].count += 1;
              floor_items.remove(j);
              added = true;
              break;
            }
          }
        }
        if( !added ){
          for( int i = 0; i < player_items.length; ++i ){
            if( player_items[i] == null && j < floor_items.size() ){
              //println( i, j );
              player_items[i] = floor_items.get(j).get();
              floor_items.remove(j);
            }
          }
        }
      }
    }
    
    for( int i = 1; i < player_items.length ; ++i ){
      for( int j = 0; j < i ; ++j ){
        if( player_items[i] != null && player_items[j] != null ){
          if( player_items[i].name.equals(player_items[j].name ) ){
            int n = min( i, j );
            int x = max( i, j );
            player_items[n].count += player_items[x].count;
            player_items[x] = null;
          }
        }
      }  
    }
    
    stroke( 180 ); 
    
    pushMatrix();
    translate( transX, transY );
    
    world[currentMap].display();
    
    PVector dir = new PVector();
    if( Player.pathing ){
      dir = Player.path_dir(world[currentMap]);
    }
    else{
      if(w) dir.add(0, -1);
      if(a) dir.add(-1, 0);
      if(s) dir.add(0, 1);
      if(d) dir.add(1, 0);
      dir.normalize();
    }
    PVector[] newPos = Player.movement( dir );
    int[] I = new int[4]; for(int i = 0; i < 4; i++) I[i] = floor( newPos[i].x / L );
    int[] J = new int[4]; for(int i = 0; i < 4; i++) J[i] = floor( newPos[i].y / L );
    
    boolean blocked = false;
    int blocks = 0;
    for(int i = 0; i < 4; i++){
      int y = floor(Player.corners[i].y / L);
      if( I[i] >= 0 && I[i] < world[currentMap].map.length){
        if( world[currentMap].map[I[i]][y].solid ){
          blocked = true;
          break;
        }
      }
      else blocked = true;
    }
    if( blocked ) ++blocks;
    else  Player.moveX( dir );
    
    blocked = false;
    for(int i = 0; i < 4; i++){
      int x = floor(Player.corners[i].x / L);
      if( J[i] >= 0 && J[i] < world[currentMap].map[0].length){
        if( world[currentMap].map[x][J[i]].solid ){
          blocked = true;
          break;
        }
      }
      else blocked = true;
    }
    if( blocked ) ++blocks;
    else Player.moveY( dir );
    
    if( blocks == 2 && Player.pathing ) Player.recalculate_path( world[currentMap] );
    
    if( pPy != Player.pos.y ){
      update_y_index();
    }
    pPy = Player.pos.y;
  
    for( int i = 0; i < y_index.length; ++i ){
      if( y_index[currentMap][i] >= 0 ){
        if( y_index[currentMap][i] < world[currentMap].objects.size() ) world[currentMap].objects.get( y_index[currentMap][i] ).display();
      }
      else if( y_index[currentMap][i] == -1 ){
      //  Player.display();
      }
      else break;
    }
    Player.display();
    
    for( int i = 0; i < floor_items.size(); ++i ){
      floor_items.get(i).display();
    }
    
    popMatrix();
    fill(0);
    image( item_display_grid, idg_x, idg_y );
    for( int j = 0; j < 3; ++j ){
      for( int i = 0; i < 3; ++i ){
        if( player_items[ i + (3*j) ] != null ){
          player_items[ i + (3*j) ].display( idg_x + 2 + (i * idg_l ), idg_y + 2 + (j * idg_l ) );//j + (3*i)
          if( player_items[ i + (3*j) ].count > 1 ) text( player_items[ i + (3*j) ].count, idg_x + 6 + (i * idg_l ), idg_y + 2 + (j * idg_l ) + (0.75 * idg_l) );
        }
      }
    }
    image( item_display_numbers, idg_x, idg_y );
    if( selected >= 0 && selected < 9 ){
      int j = floor( selected / 3.0 );
      int i = selected - (3*j);
      image( item_display_selection, idg_x + 2 + (i * idg_l ), idg_y + 2 + (j * idg_l ) );
    }
    
    
    //println( Player.current_I, Player.current_J );
    Tile current_tile = world[currentMap].map[Player.current_I][Player.current_J];
    if( current_tile instanceof Path ){
      float[] n = current_tile.destination();
      currentMap = PApplet.parseInt( n[0] );
      Player.pos = new PVector( n[1]*L, n[2]*L );
      Player.refresh_corners();
      configure_translation();
    }
    
    update_translation();
    //transX = -Player.pos.x + cx;
    //transY = -Player.pos.y + cy;
    
    //println( frameRate );
    //println( transX, transY, Player.pos.x, Player.pos.y );
  }
}