use physics, agents;

class Reward {
  var tDom = {1..0, 1..0},
      target:[tDom] int,
      sensor: Sensor,
      reward: real,
      stepPenalty: real;

  proc init(reward:real = 10.0, stepPenalty: real = -1.0) {
    this.reward = reward;
    this.stepPenalty = stepPenalty;
  }

  proc init(target: [] int, sensor: Sensor, reward=10.0, stepPenalty=-1.0) {
    this.tDom = target.domain;
    this.target = target;
    this.sensor = sensor;
    this.reward = reward;
    this.stepPenalty = stepPenalty;
  }
  proc f(state:[] int, sensor: Sensor) {
    var v:[1..sensor.dim()] int = state[sensor.stateIndexStart..sensor.stateIndexEnd];
    for i in 1..target.shape[1] {
      var t:[1..sensor.dim()] int = target[i,..];
      if t.equals(v) {
        sensor.done = true;
        return this.reward;
      }
    }
    return this.stepPenalty;
  }

  proc f(state:[] int) {
    return this.f(state=state, sensor=this.sensor);
  }
}

class ProximityReward : Reward {
  var proximity: real;
  proc init(proximity: real, sensor:Sensor, reward: real = 10.0, stepPenalty: real = -1) {
    var x:[1..1,1..1] int;
    super.init(target=x, sensor=sensor, reward=reward, stepPenalty=stepPenalty);
    this.complete();
    this.proximity = proximity;
  }

  proc f(state:[] int, sensor: Sensor) {
    var d = sensor.tiler.unbin(state[sensor.stateIndexStart..sensor.stateIndexEnd]);
    // Needs to be cast as the median of the bin it inhabits
    var prox = sensor.tiler.unbin( sensor.tiler.bin(this.proximity));
    if d <= prox {
      writeln("STOP!");
      sensor.done = true;
      return this.reward;
    } else {
      return this.stepPenalty;
    }
  }

}
