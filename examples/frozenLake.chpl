use Relch,
    Random;


proc main() {
  var episodes: [1..0] Episode;
  var n: int = 4;
  writeln("N_EPISODES %n".format(N_EPISODES));
  var B = new GridWorld(n);

  const initialState = "A1";
  for k in 1..N_EPISODES {
    var episode = new Episode(id=k);
    var currentState = initialState;
    //episode.path.push_back(currentState);
    episode.path.push_back(new Observation(state=currentState, reward=0, halt=false));
    var halt = false;
    do {
      //var adjacentStates = B.neighbors(currentState).keys;
      var options = B.availableActions(currentState);
      //var choice = policy(adjacentStates);
      var choice = policy(options);

      writeln("choice: ", choice);
      var obs = B.takeAction(currentState, choice);
      writeln("obs ", obs);
      episode.path.push_back(obs);
      currentState=obs.state;
      halt = obs.halt;
    //} while !B.absorbingStates.keys.member(episode.finalState());
    } while !halt;
    //writeln("getting final state");
    //episode.value = B.absorbingStates.get(episode.finalState());
    //episode.value = episode.finalState().r;
    //writeln("got final state");
    episodes.push_back(episode);
  }
  report(episodes);

  proc policy(states: domain(string)) {
    var s: [1..0] string;
    for t in states do s.push_back(t);
    var rs = choice(s);
    return rs[1];
    //choice(states);
    /*
    var rs: [1..0] string;
    for s in
    states do rs.push_back(s);
    shuffle(rs);
    return rs[1];
    */
  }

  proc step(action) {
    return 0;
  }

  proc report(episodes: [] Episode) {
    for e in episodes do writeln(e);
  }

}
