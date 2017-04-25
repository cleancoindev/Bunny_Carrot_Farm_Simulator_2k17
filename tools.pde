float[] find_connection( int o, int i, int j, String[] conns ){
  float[] out = new float [0];
  for( int a = 0; a < conns.length; a++ ){
    String[] q = split( conns[a], ' ' );
    if( int( q[0] ) == o ){
      if( int( q[1] ) == i ){
        if( int( q[2] ) == j ){
          out = new float [3];
          out[0] = int( q[3] );
          out[1] = float( q[4] );
          out[2] = float( q[5] );
        }
      }
    }
  }
  return out;
}

class Index{
  int i, j;
  Index( int i, int j ){
    this.i = i;
    this.j = j;
  }
  boolean equals( Index b ){
    if( i == b.i && j == b.j ) return true;
    else return false;
  }
  Index get(){ return new Index( i, j ); }
}

ArrayList<Index> A_Star( Index start, Index goal, Map map ){
  // The set of nodes already evaluated.
  ArrayList<Index> closedSet = new ArrayList();
  // The set of currently discovered nodes still to be evaluated.
  // Initially, only the start node is known.
  ArrayList<Index> openSet = new ArrayList();
  openSet.add( start );
  // For each node, which node it can most efficiently be reached from.
  // If a node can be reached from many nodes, cameFrom will eventually contain the
  // most efficient previous step.
  Index[][] cameFrom = new Index[map.rows()][map.columns()];
  
  // For each node, the cost of getting from the start node to that node.
  float[][] gScore = new float[map.rows()][map.columns()];//:= map with default value of Infinity
  for(int i = 0; i < map.rows(); i++) for(int j = 0; j < map.columns(); j++) gScore[i][j] = -1;
  // The cost of going from start to start is zero.
  gScore[start.i][start.j] = 0;
  // For each node, the total cost of getting from the start node to the goal
  // by passing by that node. That value is partly known, partly heuristic.
  float[][] fScore = new float[map.rows()][map.columns()];// := map with default value of Infinity
  for(int i = 0; i < map.rows(); i++) for(int j = 0; j < map.columns(); j++) fScore[i][j] = -1;
  // For the first node, that value is completely heuristic.
  fScore[start.i][start.j] = heuristic_cost_estimate(start, goal);
  
  float r = sqrt(2);
  int[] ik =     { -1,  0,  1,  1,  1,  0, -1, -1 };
  int[] jk =     { -1, -1, -1,  0,  1,  1,  1,  0 };
  float[] dist = {  r,  1,  r,  1,  r,  1,  r,  1 };
  
  while( openSet.size() > 0 ){ //openSet is not empty
    Index current; 
    float[] openSet_fscores = new float[openSet.size()];
    for( int u = 0; u < openSet.size(); ++u ) openSet_fscores[u] = fScore[ openSet.get(u).i ][ openSet.get(u).j ];
    int theU = openSet.size()-1;
    int theI = openSet.get(theU).i;
    int theJ = openSet.get(theU).j;
    float small = ( fScore[ openSet.get(theU).i ][ openSet.get(theU).j ] >= 0 )? fScore[ openSet.get(theU).i ][ openSet.get(theU).j ] : 9999999;
    for( int u = openSet_fscores.length-2; u >= 0; --u ){
      if( openSet_fscores[u] >= 0 && openSet_fscores[u] < small ){
        small = openSet_fscores[u];
        theI = openSet.get(u).i;
        theJ = openSet.get(u).j;
        theU = u;
      }
    }
    //println( "("+openSet.size()+")", fScore[ openSet.get(0).i ][ openSet.get(0).j ], ". "+theI+", "+theJ );
    current = new Index( theI, theJ ); //the node in openSet having the lowest fScore[] value
    
    if( current.equals(goal) ) return reconstruct_path(cameFrom, start, goal );
    
    openSet.remove( theU );
    closedSet.add( current.get() );
    
    
    for( int u = 0; u < 8; ++u ){ // each neighbor of current
      
      int ni = current.i + ik[u];
      int nj = current.j + jk[u];
      
      if(  ni < 0 || ni >= map.rows() ) continue;    // Ignore the world borders
      if(  nj < 0 || nj >= map.columns() ) continue;
      
      Index neighbor = new Index( ni, nj );
      
      if( map.map[ni][nj].solid ) continue; // Ignore the solid walls
      
      int oi = -1, oj = -1;
      switch( u ){
        case 0:
          oi = current.i -1;
          oj = current.j -1;
          break;
        case 2:
          oi = current.i +1;
          oj = current.j -1;
          break;
        case 4:
          oi = current.i +1;
          oj = current.j +1;
          break;
        case 6:
          oi = current.i -1;
          oj = current.j +1;
          break;
      }
      if( oi >= 0 && oi < map.rows() && oj >=0 && oj < map.columns() ){
        if( map.map[oi][current.j].solid || map.map[current.i][oj].solid ) continue; // Ingnore blocked diagonals
      }
      
      //print( ni+", "+nj+" | " );
      
      if( contains( closedSet, neighbor) ) continue;   // Ignore the neighbor which is already evaluated.
          
      // The distance from start to a neighbor
      float tentative_gScore = gScore[current.i][current.j] + dist[u]; //dist_between(current, neighbor)
      
      if( !contains( openSet, neighbor ) ){  // Discover a new node
        openSet.add( neighbor );
      }
      else if( tentative_gScore >= gScore[neighbor.i][neighbor.j] && gScore[neighbor.i][neighbor.j] >= 0 ) continue; // This is not a better path.

      // This path is the best until now. Record it!
      cameFrom[ni][nj] = current.get();
      gScore[ni][nj] = tentative_gScore;
      fScore[ni][nj] = gScore[ni][nj] + heuristic_cost_estimate(neighbor, goal);
    }
    //println(".");
    //ddraw( closedSet, openSet, cameFrom, gScore, start, goal );
  }
  
  //println("fuck");
  return null; //failure
}

float heuristic_cost_estimate( Index a, Index b ){
  return dist( a.i, a.j, b.i, b.j );
}

ArrayList<Index> reconstruct_path(Index[][] cameFrom, Index start, Index goal ){
  ArrayList<Index> tp = new ArrayList(); //total_path
  tp.add( goal ); 
  while( !tp.get( tp.size() -1 ).equals( start ) ){
    tp.add( cameFrom[ tp.get( tp.size() -1 ).i ][ tp.get( tp.size() -1 ).j ].get() );
  }
  //shorten path
  return tp;
}

boolean contains( ArrayList<Index> list, Index item ){
  for(int i = 0; i < list.size(); i++){
    if( list.get(i).equals( item ) ) return true;
  }
  return false;
}

//========================================================================================

ArrayList<PVector> Bresenham_plus(int x1, int y1, int x2, int y2 ){ //float x1, float y1, float x2, float y2){
  int i;               // loop counter
  int ystep, xstep;    // the step on y and x axis
  int error;           // the error accumulated during the increment
  int errorprev;       // *vision the previous value of the error variable
  int y = y1, x = x1;  // the line points
  int ddy, ddx;        // compulsory variables: the double values of dy and dx
  int dx = x2 - x1;
  int dy = y2 - y1;
  ArrayList<PVector> v = new ArrayList();
  v.add( new PVector(x1, y1));// POINT (y1, x1);  // first point
  // NB the last point can't be here, because of its previous point (which has to be verified)
  if (dy < 0){
    ystep = -1;
    dy = -dy;
  }
  else ystep =  1;
  
  if (dx < 0){
    xstep = -1;
    dx = -dx;
  }
  else xstep = 1;
  
  ddy = 2 * dy;  // work with double values for full precision
  ddx = 2 * dx;
  if (ddx >= ddy){  // first octant (0 <= slope <= 1)
    // compulsory initialization (even for errorprev, needed when dx==dy)
    errorprev = error = dx;  // start in the middle of the square
    for (i=0 ; i < dx ; i++){  // do not use the first point (already done)
      x += xstep;
      error += ddy;
      if (error > ddx){  // increment y if AFTER the middle ( > )
        y += ystep;
        error -= ddx;
        // three cases (octant == right->right-top for directions below):
        if (error + errorprev < ddx) v.add( new PVector( x, y-ystep)); // POINT (y-ystep, x); // bottom square also
          
        else if (error + errorprev > ddx) v.add( new PVector(x-xstep, y));// POINT (y, x-xstep);  // left square also
          
        else{  // corner: bottom and left squares also
          v.add( new PVector(x, y-ystep) ); //POINT (y-ystep, x);
          v.add( new PVector(x-xstep, y) ); // POINT (y, x-xstep);
        }
      }
      v.add( new PVector( x, y ) ); //POINT (y, x);
      errorprev = error;
    }
  }
  else{  // the same as above
    errorprev = error = dy;
    for (i=0 ; i < dy ; i++){
      y += ystep;
      error += ddx;
      if (error > ddy){
        x += xstep;
        error -= ddy;
        if (error + errorprev < ddy) v.add( new PVector( x-xstep, y) ); // POINT (y, x-xstep);
          
        else if (error + errorprev > ddy) v.add( new PVector(x, y-ystep) );// POINT (y-ystep, x);
          
        else{
          v.add( new PVector( x-xstep, y) );// POINT (y, x-xstep);
          v.add( new PVector( x, y-ystep) );// POINT (y-ystep, x);
        }
      }
      v.add( new PVector( x, y ) ); // POINT (y, x);
      errorprev = error;
    }
  }
  return v;
}
//============================================================================================

float coincidence( String a, String b ) {
  int N = min( a.length(), b.length() );
  int eq = 0;
  for ( int i = 0; i < N; ++i ) {
    if ( a.charAt(i) == b.charAt(i) ) ++eq;
    else if( char(int(a.charAt(i))-32) == b.charAt(i) ) ++eq;
    else if( char(int(a.charAt(i))+32) == b.charAt(i) ) ++eq;
  }
  return eq/float(N);
}
//=============================================================================================

int[] indices_in_ascending_order(float[] k) {
  int[] indices = new int[k.length];
  for (int i = 0; i < k.length; i++) {
    indices[i] = i;
  }
  boolean x = false;
  while ( !x ) {
    x = true;
    for (int i = 0; i< k.length-1; i++) {
      if (k[i] > k[i+1]) {
        float q = k[i+1];
        k[i+1] = k[i];
        k[i] = q;

        int Q = indices[i+1];
        indices[i+1] = indices[i];
        indices[i] = Q;
        x=false;
      }
    }
  }
  return indices;
}