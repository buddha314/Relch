use Relch,
    Random;


proc main() {
  var episodes: [1..0] Episode,
      n: int = 4;
  writeln("N_EPISODES %n".format(N_EPISODES));
  var B = new GridWorld(n);
  var ss: [1..0] string; for k in B.verts.keys do ss.push_back(k);
  var aa: [1..0] string; for k in B.actions.keys do aa.push_back(k);
  var Q = new NamedMatrix(rownames=ss, colnames=aa);



  const initialState = "A1";
  for k in 1..N_EPISODES {
    var episode = new Episode(id=k);
    var currentState = initialState;
    episode.path.push_back(new Observation(state=currentState, reward=0, episodeEnd=false));
    var episodeEnd = false;
    do {
      var options = B.availableActions(currentState);
      var choice = policy(options);

      //writeln("choice: ", choice);
      var obs = B.takeAction(currentState, choice);
      //writeln("obs ", obs);
      episode.path.push_back(obs);
      currentState=obs.state;
      episodeEnd = obs.episodeEnd;
    } while !episodeEnd;
    episodes.push_back(episode);
  }
  report(episodes);

  proc policy(states: domain(string)) {
    var s: [1..0] string;
    for t in states do s.push_back(t);
    var rs = choice(s);
    return rs[1];
  }

  proc step(action) {
    return 0;
  }

  proc report(episodes: [] Episode) {
    for e in episodes do writeln(e);
  }

}
