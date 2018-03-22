use Chingon;

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
  var absorbingStates: BiMap;

  proc init(r:int) {
    super.init(r=r);
    this.absorbingStates = new BiMap();
    this.absorbingStates.add("B2", -1);
    this.absorbingStates.add("B4", -1);
    this.absorbingStates.add("C4", -1);
    this.absorbingStates.add("D1", -1);
    this.absorbingStates.add("D4", 1);
    this.complete();
  }

  proc takeAction(currentState: string, action: string) {
    var currentStateId: int = this.verts.get(currentState),
        newStateId: int;
    if action == "N" {
      newStateId = currentStateId - this.cols;
    } else if action == "E" {
      newStateId = currentStateId + 1;
    } else if action == "W" {
      newStateId = currentStateId - 1;
    } else if action == "S" {
      newStateId = currentStateId + this.cols;
    }
    var newState = this.verts.get(newStateId);
    writeln(action, " means moving from %s to %s".format(currentState, newState));
    return new Observation(state=newState
      ,reward=1, halt=!this.absorbingStates.keys.member(newState));
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
      halt: bool;

  proc init(state: string, reward: real, halt: bool=false ) {
    this.state = state;
    this.reward = reward;
    this.halt = halt;
  }
}
