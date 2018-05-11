use physics, agents;

class Reward {
  var tDom = {1..0, 1..0},
      target:[tDom] int,
      sensor: Sensor,
      reward: real,
      stepPenalty: real;

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
