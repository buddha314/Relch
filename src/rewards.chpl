use physics, agents;

class Reward {
  var tDom = {1..0, 1..0},
      target:[tDom] int,
      stateIndexStart: int,
      stateIndexEnd: int,
      value: real,
      penalty: real,
      accomplished: bool;

  proc init(value:real = 10.0, penalty: real = -1.0) {
    this.value = value;
    this.penalty = penalty;
    this.accomplished = false;
  }

  proc buildTargets(targets:[] int) {
    this.tDom = targets.domain;
    for i in 1..targets.shape[1] {
      for j in 1..targets.shape[2] {
        this.target[i,j] = targets[i, j];
      }
    }
    return this;
  }

  proc f(state:[] int) {
    var substate = state[this.stateIndexStart..this.stateIndexEnd];
    //writeln("substate: ", substate);
    //writeln(" reward shape ", this.target.shape);
    for i in 1..this.target.shape[1] {
      const x:[substate.domain] int = this.target[i,..];
      //writeln("checking for x: ", x);
      if substate.equals(x) {
        this.accomplished = true;
        //writeln("yes, there is a match");
        return this.value;
      }
    }
    return this.penalty;
  }

  proc finalize() {
    var dom = {1..this.target.shape[1], this.stateIndexStart..this.stateIndexEnd};
    reshape(this.target, dom);
    return true;
  }

}

/*
 Proximity is an integer to reflect the tiling. So is is the number
 of tiles away the target can be.
 */
class ProximityReward : Reward {
  var proximity: int;
  proc init(proximity: int, reward: real = 10.0, penalty: real = -1) {
    var x:[1..1,1..1] int;
    super.init(value=value, penalty=penalty);
    this.complete();
    this.proximity = proximity;
  }

  proc buildTargets() {
    //writeln(" ** proximity build targets");
    var rows: int = 2*this.proximity- 1;
    this.tDom = {1..rows, this.stateIndexStart..this.stateIndexEnd}; // Keep the state domain
    this.target[1,stateIndexStart] = 1;
    for i in 2..proximity {
      this.target[i,stateIndexStart + i-1] = 1;
      // To handle overlap on the inside distance
      this.target[proximity + i-1, stateIndexStart + i-2] = 1;
      this.target[proximity + i-1, stateIndexStart + i-1] = 1;
    }
    //writeln(this.target);
    return true;
  }

  proc f(state:[] int) {
    var substate = state[this.stateIndexStart..this.stateIndexEnd];
    //writeln("substate: ", substate);
    for i in 1..this.target.shape[1] {
      const x:[substate.domain] int = this.target[i,..];
      //writeln("checking for x: ", x);
      if substate.equals(x) {
        this.accomplished = true;
        //writeln("yes, there is a match");
        return this.value;
      }
    }
    return this.penalty;
  }

  proc finalize() {
    return this.buildTargets();
  }
}
