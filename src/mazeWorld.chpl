use Chingon;
use worlds;

class Maze: World {
  var wrap: bool,
      width: int,
      height: int,
      board: GameBoard;
  proc init(width: int, height: int, wrap: bool) {
    super.init();
    this.complete();
    this.wrap=wrap;
    this.width=width;
    this.height=height;
    this.board = new GameBoard(width=width, height=height, wrap=wrap);
  }

  proc isValidPosition(position: MazePosition) {
    return true;
  }

  proc isValidMove(agent: Agent, position: MazePosition) {
    return true;
  }
}

class GameBoard: Graph {
  var wrap: bool,
      width: int,
      height: int;

  proc init(width:int, height: int, wrap:bool) {
    var n: [1..0] string;
    for a in gridNames(i=height,j=width) do n.push_back(a);
    var X = buildGameGrid(c=width,r=height);
    super.init(X=X, name="Game Board", directed=false, vnames=n);
    this.wrap=wrap;
    this.width=width;
    this.height=height;
  }
}

/*
 Creates a sparse matrix with entries at the edges with defined number of nrows/ncols
*/
proc buildGameGrid(r: int, c:int) {
  var D: domain(2) = {1..r*c, 1..r*c},
      SD: sparse subdomain(D),
      X: [SD] real,
      m: int = 1,
      n: int = 1;

  var k = 1;
  for 1..r*c {
    if !(k % c == 0){
      SD += (k, k+1);
      SD += (k+1, k);
    }
    if !((k+c) > r*c) {
      SD += (k, k+c);
      SD += (k+c, k);
    }
    k += 1;
  }
  for a in SD {
    X[a] = 1;
  }
  return X;
}
