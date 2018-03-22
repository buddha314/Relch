use Relch,
    Random;


/*
 This is developing into implementing the Sarsa(lambda) on-policy learning
 */
proc main() {
  var episodes: [1..0] Episode,
      n: int = 4;
  writeln("N_EPISODES %n".format(N_EPISODES));
  var B = new GridWorld(n);
  var ss: [1..0] string; for k in B.verts.keys do ss.push_back(k);
  var aa: [1..0] string; for k in B.actions.keys do aa.push_back(k);
  var Q = new NamedMatrix(rownames=ss, colnames=aa);

  /*
   Have to do this because
     (a) fillRandom won't work on sparse matrices as the subdomain is empty
     (b) fillRandom isn't defined (yet) for NamedMatrices
   */
  var rs: [1..ss.size * aa.size] real;
  fillRandom(rs);
  for i in 1..ss.size {
    for j in 1..aa.size {
      Q.SD += (i,j);
      Q.set(i,j, rs[Q.grid2seq(i,j)]);
    }
  }
  //writeln(Q);


  const initialState = "A1";
  const initialAction: string = policy(B.availableActions(initialState));
  for k in 1..N_EPISODES {
    // We need the Eligibility Trace E
    var E = new NamedMatrix(rownames=ss, colnames=aa);
    for i in 1..ss.size {
      for j in 1..aa.size {
        Q.SD += (i,j);
      }
    }

    var episode = new Episode(id=k);
    var currentState = initialState;
    var currentAction = initialAction;
    episode.path.push_back(new Observation(state=currentState, reward=0, episodeEnd=false));
    var episodeEnd = false;
    // Now run through the steps
    do {
      var options = B.availableActions(currentState);
      var choice = policy(options);  // For now, just random

      //writeln("choice: ", choice);
      var obs = B.takeAction(currentState, choice);  // Take action, Observe R, S'
      var delta = obs.reward + DISCOUNT_FACTOR * Q.get(obs.state, choice) - Q.get(currentState, currentAction);
      E.update(currentState, currentAction, 1);
      for a in B.actions.keys {
        for s in B.states.keys {
          Q.update(currentState, currentAction, LEARNING_RATE * delta * E.get(currentState, currentAction));
        }
      }

      //writeln("obs ", obs);
      episode.path.push_back(obs);
      currentState=obs.state;
      currentAction=choice;
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
