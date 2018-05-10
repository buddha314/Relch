use Relch,
    Sort,
    Random;

config const ENCOUNTERS: string,
             SUBGOAL_REWARD: int,
             BACKPACK_CAPACITY: int;

proc main() {
  var D = new Dungeon(w=BOARD_WIDTH, h=BOARD_HEIGHT),
      A = new Agent(),
      DM = new DungeonMaster(D);


  var states = D.verts;
  var actions = new BiMap();
  for a in D.allAvailableActions do actions.add(a);
  //var Q = initializeStateActionRandom(states=states, actions=actions);
  writeln(D);
  A.Q = initializeStateActionRandom(states=states, actions=actions);
  A.Q.pprint();
  //run(A=A, Q=Q, DM=DM);
  run(A=A, DM=DM);
  A.Q.pprint();
}

//proc run(A: Agent, Q: NamedMatrix, DM: DungeonMaster) {
proc run(A: Agent, DM: DungeonMaster) {
  const initialLocation = DM.dungeon.initialLocation;
  const initialAction = "E";

  var episodes: [1..0] Episode;
  for k in 1..N_EPISODES {
    var path: [1..0] string;
    DM.resetEncounters();
    var episode = new Episode(id=k);

    A.E = initializeEligibilityTrace(A.Q.rows, A.Q.cols);
    var currentLocation: string = initialLocation;
    var currentAction = A.policy(currentLocation, DM.presentOptions(currentLocation));
    A.backpack.clear();
    do {
      var (reward, nextLocation) = DM.evaluateAction(A, currentLocation, currentAction);
      var nextAction = A.policy(nextLocation, DM.presentOptions(nextLocation));

      // update Q and E
      A.updateQandE(currentLocation=currentLocation, currentAction=currentAction,
        reward=reward, nextLocation=nextLocation, nextAction=nextAction);

      currentLocation = nextLocation;
      currentAction = nextAction;
      episode.path.push_back(new Observation(state=currentLocation, reward=reward.v, episodeEnd=A.done()));
      path.push_back(currentLocation);
      path.push_back(currentAction);
    } while !A.done();
    //writeln(" - %n ".format(k), path);
    episodes.push_back(episode);
  }
  if PRINT_PATHS {
    for e in episodes do writeln(e);
  }
}

class Dungeon : GameBoard {
  var encounterCells: domain(string),
      encounterObjects: [encounterCells] string,
      initialLocation: string,
      allAvailableActions: domain(string);
  proc init(w:int, h:int) {
    super.init(w=w, h=h);
    this.complete();
    this.initialLocation = INITIAL_STATE;
    this.allAvailableActions += "N";
    this.allAvailableActions += "E";
    this.allAvailableActions += "W";
    this.allAvailableActions += "S";
    this.allAvailableActions += "COLLECT";
    this.allAvailableActions += "IGNORE";
    for c in ENCOUNTERS.split(",") {
      var s = c.split(":");
      this.encounterCells += s[1];
      this.encounterObjects(s[1]) = s[2];
    }
  }

  proc resetEncounters() {
    for c in ENCOUNTERS.split(",") {
      var s = c.split(":");
      this.encounterCells += s[1];
      this.encounterObjects(s[1]) = s[2];
    }
  }

  proc availableActions(state: string) {
    var availableActions = super.availableActions(state);
    if this.encounterCells.member(state) {
      availableActions += "COLLECT";
      availableActions += "IGNORE";
    }
    return availableActions;
  }

  /* How to move from place to place */
  proc step(currentState: string, action: string) {
    //var reward: real = this.stepPenalty;
    var reward: real = STEP_PENALTY;
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
    return newState;
  }

  proc writeThis(f) {
    const EMPTY_CELL = " * ",
          ENCOUNTER_CELL = " E ",
          START_CELL = " S ",
          TERMINAL_CELL = " X ",
          HALLWAY = "-",
          H_WALL = " | ";

    f <~> this.X.domain.dims() <~> "\n";
    for x in 1..this.verts.size() {
      if this.encounterCells.member(this.verts.get(x)) {
        //f <~> ENCOUNTER_CELL;
        f <~> " " + (this.encounterObjects[this.verts.get(x)])[1] + " ";
      } else if this.verts.get(x) == this.initialLocation {
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
}

class Agent {
  var backpack: [1..0] string,
      Q: NamedMatrix,
      E: NamedMatrix;

  proc init(){
    this.Q = new NamedMatrix();
    this.E = new NamedMatrix();
  }

  /* Sarsa (lambda) update */
  proc updateQandE(currentLocation: string, currentAction: string,
    reward: Reward, nextLocation: string, nextAction: string) {
      var delta: real = reward.v + DISCOUNT_FACTOR * this.Q.get(nextLocation, nextAction) - this.Q.get(currentLocation, currentAction);
      this.E.update(currentLocation, currentAction, 1.0);

      // update Q(s,a) += alpha * delta * E(s,a)
      var E_tmp: NamedMatrix = new NamedMatrix(this.E);  // might be a bad idea to copy this, not sure.
      E_tmp.eTimes(LEARNING_RATE*delta);
      this.Q.matPlus(E_tmp);

      // update E(s,a) = gamma*lambda*E(s,a)
      this.E.eTimes(DISCOUNT_FACTOR * TRACE_DECAY);

      // Okay, figure this bit out.
  }



  proc done() {
    if backpack.size >= BACKPACK_CAPACITY {
      return true;
    } else {
      return false;
    }
  }

  proc policy(currentLocation: string, options: domain(string)) {

    var ps: [1..1] real;
    var returnedAction: string;
    fillRandom(ps);
    if ps[1] < 1 - GREEDY_EPSILON {
      var actionMap = new BiMap();
      var actionQValues: [1..0] real;
      var k: int = 1;
      for o in options {
        actionMap.add(o, k);
        actionQValues.push_back(this.Q.get(currentLocation, o));
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
}

class DungeonMaster {
  var dungeon: Dungeon;
  proc init(dungeon: Dungeon) {
    this.dungeon = dungeon;
  }

  proc evaluateAction(A: Agent, currentLocation: string, currentAction: string) {
    var r: Reward;
    var nextLocation: string;
    if this.dungeon.encounterCells.member(currentLocation) {
      //writeln("at an encounter cell");
      if currentAction == "COLLECT" {
        r = new Reward(t="Goal", v=0, name=this.dungeon.encounterObjects[currentLocation]);
        A.backpack.push_back(this.dungeon.encounterObjects[currentLocation]);
        this.dungeon.encounterCells -= currentLocation;
        if A.backpack.size == BACKPACK_CAPACITY {
          // Backpack is full, make sure she got the right things.
          nextLocation = INITIAL_STATE;
          if A.backpack[1] == A.backpack[2] {
            r.v = GOAL_REWARD;
          } else {
            r.v = SUBGOAL_REWARD;
          }
        } else {
          r = new Reward(t="Item", v=0);
        }
      } else if currentAction == "IGNORE" {
        r = new Reward(t="Fatigue", v=0);
        //writeln("Ignoring encounter in cell %s".format(currentLocation));
      } else {
        r = new Reward(t="Fatigue", v=STEP_PENALTY);
        nextLocation = this.dungeon.step(currentLocation, currentAction);
        //writeln("evaluateAction could not get a nextLocation");
      }
      nextLocation = currentLocation;
    } else {
      //writeln("Just move along, son.");
      r = new Reward(t="Fatigue", v=STEP_PENALTY);
      nextLocation = this.dungeon.step(currentLocation, currentAction);
    }
    //writeln("returning r, l ", r, nextLocation );
    return (r, nextLocation);
  }

  proc presentOptions(currentLocation) {
    return this.dungeon.availableActions(currentLocation);
  }

  proc resetEncounters() {
    this.dungeon.resetEncounters();
  }
}

class Reward {
  var t: string,
      v: real,
      name: string;
  proc init(t:string, v: real, name:string="default reward"){
    this.t = t;
    this.v = v;
    this.name = name;
  }
}
