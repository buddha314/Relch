use NumSuch,
    Math,
    physics;


class Policy {
  var sensors: [1..0] Sensor;
  proc init() {
  }

  proc f(options:[] int, state:[] int) {
    var r:[1..options.shape[2]] int;
    r = options[1,..];
    return r;
  }

  proc add(sensor : Sensor) {
    this.sensor.push_back(sensor);
  }
}

class RandomPolicy : Policy {
  proc init() {
    super.init();
    this.complete();
  }

  proc f(options:[] int, state:[] int) {
    var c = randInt(1,options.shape[1]);
    const choice:[1..options.shape[2]] int = options[c,..];
    return choice;
  }
}

class QLearningPolicy : Policy {
  var d: domain(2),
      Q: [d] real,
      E: [d] real;

  proc init(nActions: int, nStates: int) {
    super.init();
    this.complete();
    this.d = {1..nActions, 1..nStates};
    fillRandom(this.Q);
    this.E = 0.0;
  }
  proc f(options:[] int, state:[] int) {
    // Need to translate the options into discrete rows
    var choices: [1..options.shape[1]] real = 0.0;
    // The states are discrete, but the input looks like [0 0 1 0]
    //  meaning we are in state 3
    var s:int = argmax(state);
    for r in 1..options.shape[1] {
      if options[r,r] == 1 {
        choices[r] = this.Q[r,s];
      } else {
        choices[r] = 0.0;
      }
    }
    var opt:[1..options.shape[2]] int;
    opt = options[argmax(choices), ..];
    return opt;
  }
}

class FollowTargetPolicy : Policy {
  var sensor : Sensor;
  proc init(sensor: Sensor) {
    super.init();
    this.complete();
    this.sensor = sensor;
  }

  proc f(me: Agent, options:[] int, state: [] int) {
    var targetAngle = me.angleFromMe(this.sensor.target.position);
    var thetas:[1..options.shape[1]] real;
    var t: [1..options.shape[2]] int;
    for i in 1..options.shape[1] {
      t = options[i,..];
      var theta = abs(targetAngle - this.sensor.tiler.unbin(t)) ;
      if theta > pi then theta = 2* pi - theta;
      thetas[i] = theta;
    }
    var choice: [1..options.shape[2]] int = options[argmin(thetas), ..];
    return choice;
  }
}
