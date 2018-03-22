use Relch,
    Random;


proc main() {
  var episodes: [1..0] Episode;
  var n: int = 4;
  writeln("N_EPISODES %n".format(N_EPISODES));
  //var B = new GameBoard(n);
  var B = new GridWorld(n);

  /*
  var absorbingStates = new BiMap();
  absorbingStates.add("B2", -1);
  absorbingStates.add("B4", -1);
  absorbingStates.add("C4", -1);
  absorbingStates.add("D1", -1);
  absorbingStates.add("D4", 1);
  */

  const initialState = "A1";
  for k in 1..N_EPISODES {
    var episode = new Episode(id=k);
    var currentState = initialState;
    episode.path.push_back(currentState);
    do {
      var adjacentStates = B.neighbors(currentState).keys;
      var choice = policy(adjacentStates);
      episode.path.push_back(currentState);
      currentState=choice;
    } while !B.absorbingStates.keys.member(episode.finalState());
    episode.value = B.absorbingStates.get(episode.finalState());
    episodes.push_back(episode);
  }
  report(episodes);

  proc policy(states: domain(string)) {
    var rs: [1..0] string;
    for s in
    states do rs.push_back(s);
    shuffle(rs);
    return rs[1];
  }
  proc step(action) {
    return 0;
  }

  proc report(episodes: [] Episode) {
    for e in episodes do writeln(e);
  }

}
