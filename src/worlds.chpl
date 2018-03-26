use Chingon,
    Random;


config const GREEDY_EPSILON: real;  // epsilon


/*
 Probably too abstract
 */
class World {
  proc init() { }
}

/*
Will have rewards and stuff eventually
 */
class GridWorld : GameBoard {
  //var absorbingStates: BiMap,
  var states: BiMap,
      terminalStates: BiMap,
      stepPenalty: int,
      deathPenalty: int,
      goalReward: int,
      initialState: string;

  proc init(w:int, h:int, terminalStates: BiMap) {
    super.init(w=w, h=h);

    this.states = new BiMap();
    this.states = this.verts;

    this.terminalStates = new BiMap();
    this.terminalStates = terminalStates;

    this.complete();
  }

  proc writeThis(f) {
    const EMPTY_CELL = " * ",
          GOAL_CELL = " G ",
          START_CELL = " S ",
          TERMINAL_CELL = " X ",
          HALLWAY = "-",
          H_WALL = " | ";

    f <~> this.X.domain.dims() <~> "\n";
    for x in 1..this.verts.size() {
      //f <~> this.seq2grid(x) <~> " ";
      if this.terminalStates.keys.member(this.verts.get(x)) {
        f <~> TERMINAL_CELL;
      } else if this.verts.get(x) == this.initialState {
        f <~> START_CELL;
      } else {
        f <~> EMPTY_CELL;
      }
      if this.SD.member(x, x+1) {
        f <~> HALLWAY;
      } else {
        f <~> " ";
      }
      if x % this.width == 0 {
        f <~> "\n";
        // back track to do the separating rows
        if x < this.verts.size() {
          for k in (x-this.width + 1)..x {
            if this.SD.member(k, k + this.width) {
              f <~> H_WALL;
            } else {
              f <~> "   ";
            }
            f <~> " ";
          }
          f <~> "\n";
        }
      }

    }
  }

  proc isTerminalState(state: string): bool {
    return this.terminalStates.keys.member(state);
  }

  proc step(currentState: string, action: string) {
    var reward: real = this.stepPenalty;
    var newState: string;
    if action == "N" {
        newState = this.verts.get(this.verts.get(currentState) - this.width);
    } else if action == "E" {
        newState = this.verts.get(this.verts.get(currentState) + 1);
    } else if action == "W" {
        newState = this.verts.get(this.verts.get(currentState) - 1);
    } else if action == "S" {
        newState = this.verts.get(this.verts.get(currentState) + this.width);
    }
    if !this.neighbors(currentState).keys.member(newState) {
      writeln("Illegal State chosen!  %s is not a neighbor of %s".format(newState, currentState));
      writeln("current neighbors: ", this.neighbors(currentState).keys);
      halt();
    }
    if this.isTerminalState(newState) {
      reward = terminalStates.get(newState);
      //writeln("I just terminated %s -> %n".format(newState, reward));
    }
    return (reward, newState);
  }

}

class Episode {
  var id: int,
      path: [1..0] Observation,
      value: int;
  proc init(id: int) {
    this.id = id;
  }

  proc finalObservation() {
    return this.path[this.path.domain.last];
  }

  proc finalReward() {
    return this.finalObservation().reward;
  }

  proc finalState() {
    return this.finalObservation().state;
  }

  proc finalValue() {
    return this.finalObservation().reward;
  }

  proc writeThis(f) {
    f <~> "Episode %n had final state %s for value %n".format(this.id, this.finalState(), this.finalValue());
  }
}

class Observation {
  var state: string, // S'
      reward: real,    // Reward
      episodeEnd: bool;

  proc init(state: string, reward: real, episodeEnd: bool=false ) {
    this.state = state;
    this.reward = reward;
    this.episodeEnd = episodeEnd;
  }
}

class Qoutcome {
 var agent: int,
     state: string,
     action: string,
     reward: real;

 proc init(agent:int =1, state:string, action:string, reward: real) {
   this.agent = agent;
   this.state = state;
   this.action = action;
   this.reward = reward;
 }

 proc readWriteThis(f) {
   f <~> "state, action, reward:  %8s  %8s  %{#.###}".format(this.state, this.action, this.reward);
 }
}

proc initializeStateActionRandom(states: BiMap, actions: BiMap) {
  var D = {1..states.size(), 1..actions.size()},
      Y: [D] real = 0.5,
      X: [D] real;
  fillRandom(X);
  const Z: [D] real = X-Y;
  return new NamedMatrix(X=Z, rows=states, cols=actions);
}

proc initializeEligibilityTrace(states: BiMap, actions: BiMap) {
  var D = {1..states.size(), 1..actions.size()},
      X: [D] real = 0;
  return new NamedMatrix(X=X, rows=states, cols=actions);
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
