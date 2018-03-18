use Relch,
    Random,
    Chingon, NumSuch;

proc main() {
  var n: int = 7;
  writeln("N_EPISODES %n".format(N_EPISODES));
  var B = new GameBoard(7);

  const actions = ["N", "E", "W", "S"];

  const initialState = "A1";
  var currentState = initialState;
  for ep in 1..N_EPISODES {
    var adjacentStates = B.neighbors(currentState).keys;
    var choice = policy(adjacentStates);
    writeln("Here is my choice: %s".format(choice));
    currentState=choice;
    //writeln("Options: ", adjacentStates);
  }

  proc policy(states: domain(string)) {
    writeln("My options are: ", states);
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
