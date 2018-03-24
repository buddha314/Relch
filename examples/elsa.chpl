use Relch,
    Sort,
    Random;

proc main() {
    var episodes: [1..0] Episode,
        terminalStates = new BiMap();

    terminalStates.add(GOAL_STATE, GOAL_REWARD);

    var B = new GridWorld(w=BOARD_WIDTH, h=BOARD_HEIGHT, terminalStates=terminalStates);
    B.initialState = INITIAL_STATE;
    B.stepPenalty = STEP_PENALTY;
    B.deathPenalty = DEATH_PENALTY;
    B.goalReward = GOAL_REWARD;
    B.addWall("B2", "B3");
    B.addWall("C1", "C2");
    B.addWall("E3", "E4");
    //
    writeln(B);
    //pprint(B);
    //writeln("verts:\n",B.verts);
    //writeln("actions:\n",B.actions);
    //writeln("verts max: ", B.verts.max());
    var actions = new BiMap();
    actions.add("N");
    actions.add("E");
    actions.add("W");
    actions.add("S");
    var states: BiMap = B.verts;

    // Main routine
    var Q = initializeStateActionRandom(states=states, actions=actions);
    Q.pprint();

    const initialState = INITIAL_STATE;
    for k in 1..N_EPISODES {
      var path: [1..0] string;
      //writeln(" - %n".format(k));
      var E: NamedMatrix = initializeEligibilityTrace(B.verts, actions);
      var currentState = initialState;
      var currentAction = policy(currentState, B=B, Q=Q);
      do {
        // take action, get reward, nextState
        var (reward, nextState) = B.step(currentState, currentAction);
        //writeln("    got reward, nextState %n, %s from current state %s".format(reward, nextState, currentState));
        // choose nextAction from nextState using policy e.g. e-greedy
        var nextAction = policy(nextState, B=B, Q=Q);
        //writeln("    trying action %s from next state %s".format(nextAction, nextState));
        // define delta
        var delta: real = reward + DISCOUNT_FACTOR * Q.get(nextState, nextAction) - Q.get(currentState, currentAction);
        // E(currentState, currentAction) += 1
        E.update(currentState, currentAction, 1.0);

        // update Q(s,a) += alpha * delta * E(s,a)
        var E_tmp: NamedMatrix = new NamedMatrix(E);  // might be a bad idea to copy this, not sure.
        E_tmp.eTimes(LEARNING_RATE*delta);
        Q.matPlus(E_tmp);

        // update E(s,a) = gamma*lambda*E(s,a)
        E.eTimes(DISCOUNT_FACTOR * TRACE_DECAY);

        // reset states
        currentState = nextState;
        currentAction = nextAction;
        path.push_back(currentState);
      } while !B.isTerminalState(currentState);
      writeln(k, ": ", path);
    }
    Q.pprint();
}

proc policy(currentState: string, B: GridWorld, Q: NamedMatrix) {
  const options = B.availableActions(currentState);

  var ps: [1..1] real;
  var returnedAction: string;
  fillRandom(ps);
  if ps[1] < 1 - GREEDY_EPSILON {
    var actionMap = new BiMap();
    var actionQValues: [1..0] real;
    var k: int = 1;
    for o in options {
      actionMap.add(o, k);
      actionQValues.push_back(Q.get(currentState, o));
      k += 1;
    }
    returnedAction = actionMap.get(argmax(actionQValues));
  } else {
    var s: [1..0] string;
    for t in options do s.push_back(t);
    var tmp = choice(s);
    returnedAction = tmp[1];
  }
  return returnedAction;
}
