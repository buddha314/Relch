use Relch,
    Random;

proc main() {
  var n: int = 4;
  writeln("N_EPISODES %n".format(N_EPISODES));
  var B = new GameBoard(n);

  var terminalStates: domain(string);
  terminalStates += "B2";
  terminalStates += "B4";
  terminalStates += "C4";
  terminalStates += "D1";

  const initialState = "A1";
  for ep in 1..N_EPISODES {
    var currentState = initialState;
    var alive: bool = true;
    var path: [1..0] string;
    path.push_back(currentState);
    while alive {
      var adjacentStates = B.neighbors(currentState).keys;
      var choice = policy(adjacentStates);
      path.push_back(choice);
      //writeln("Here is my choice: %s".format(choice));
      currentState=choice;
      if terminalStates.member(choice) then alive = false;
    }
    writeln("path: ", path);
    //writeln("Options: ", adjacentStates);
  }

  proc policy(states: domain(string)) {
    //writeln("My options are: ", states);
    //completely random policy
    var rs: [1..0] string;
    for s in
    states do rs.push_back(s);
    shuffle(rs);
    return rs[1];
  }
  proc step(action) {
    return 0;
  }

}
