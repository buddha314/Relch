use NumSuch,
    Math,
    Epoch,
    physics;


class Policy {
  //var sensors: [1..0] Sensor,
  var onPolicy: bool,
      epsilon: real;   // for epsilon-greedy routines
  proc init(onPolicy: bool = true, epsilon: real = -1) {
    this.onPolicy = onPolicy;
    this.epsilon = epsilon;
  }

  //proc f(me: Agent, options:[] int, state:[] int) {
  proc f(options:[] int, state:[] int) throws {
    writeln(" ** in default policy");
    var r:[1..options.shape[2]] int;
    r = options[1,..];
    return r;
  }

  /*
  proc add(sensor : Sensor) {
    sensor.stateIndexStart = this.sensorDimension() + 1;
    sensor.stateIndexEnd = sensor.stateIndexStart + sensor.tiler.nbins - 1;
    this.sensors.push_back(sensor);
  } */

  /*
  proc sensorDimension() {
    var n: int = 0;
    for s in this.sensors {
      n += s.dim();
    }
    return n;
  } */

  proc randomAction(options:[] int) {
    var c = randInt(1,options.shape[1]);
    const choice:[1..options.shape[2]] int = options[c,..];
    return choice;
  }

  proc learn(agent: Agent) {
    return 0;
  }


  proc finalize(agent: Agent) {
    //for sensor in agent.sensors do this.add(sensor);
    return true;
  }
}

class RandomPolicy : Policy {
  proc init() {
    super.init();
    this.complete();
  }

  //proc f(me: Agent, options:[] int, state:[] int) {
  proc f(options:[] int, state:[] int) throws {
    return this.randomAction(options);
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
  proc f(options:[] int, state:[] int) throws {
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

/*
 By default, this chases the target.  Setting
 avoid = true and it will evade the target
 */
class FollowTargetPolicy : Policy {
  var targetSensor : Sensor,
      avoid: bool;
  proc init(sensor: Sensor, avoid: bool=false) {
    super.init();
    this.complete();
    //this.add(sensor);
    this.targetSensor = sensor;
    this.avoid = avoid;
  }

  //proc f(me: Agent, options:[] int, state: [] int) {
  proc f(options:[] int, state: [] int) throws {
    //writeln(" ** FOLLOW TARGET POLICY");
    var targetAngle = this.targetSensor.unbin(state[this.targetSensor.stateIndexStart..this.targetSensor.stateIndexEnd]);
    var thetas:[1..options.shape[1]] real;
    var t: [1..options.shape[2]] int;
    for i in 1..options.shape[1] {
      t = options[i,..];
      var theta = abs(targetAngle - this.targetSensor.unbin(t)) ;
      if theta > pi then theta = 2* pi - theta;
      thetas[i] = theta;
    }
    //writeln("thetas: ", thetas);
    var choice: [1..options.shape[2]] int;
    if this.avoid {
        choice = options[argmax(thetas), ..];
    } else {
        //writeln("argmin thetas: ", argmin(thetas));
        choice = options[argmin(thetas), ..];
    }
    return choice;
  }
}

/*
 Defaults to a full connected neural net from the Epoch package.
 */
class DQPolicy : Policy {
  var model: FCNetwork,
      momentum: real,
      epochs: int,
      learningRate: real,
      reportInterval: int,
      alphaR: real,
      regularization: string;

  //proc init(sensor: Sensor, avoid: bool=false) {
  proc init(epsilon: real
    ,momentum: real =0.0, epochs: int = 1000
    ,learningRate: real = 0.01, alphaR: real = 0
    ,regularization: string = "L2"
  ) {
      super.init(onPolicy=true, epsilon=epsilon);
      this.complete();
      //this.add(sensor);
      this.momentum = momentum;
      this.epochs = epochs;
      this.learningRate = learningRate;
      this.reportInterval = this.epochs;
      this.alphaR = alphaR;
      this.regularization = regularization;
  }

  proc finalize(agent: Agent) {
    super.finalize(agent=agent);
    var d: int = agent.optionDimension() + agent.sensorDimension();
    this.model = new FCNetwork([d,1], ["linear"]);
    return true;
  }

  proc learn(agent: Agent) {
    //writeln("In DQ Learning");
    var n = min reduce [agent.nMemories, agent.maxMemories];
    var y: [1..1, 1..n] real;
    var XX: [1..n, 1..this.model.inputDim()] int;
    for i in 1..n {
        ref currentMemory = agent.memories[i];
        XX[i,..] = currentMemory.v();
        y[1, i] = agent.memories[i].reward;
    }
    //this.model.train(X = XX ,Y = y
    this.model.train(X = XX.T ,Y = y
       ,momentum = this.momentum ,epochs = this.epochs ,learningRate = this.learningRate
       ,reportInterval = this.reportInterval ,regularization = this.regularization
       ,alpha = this.alphaR );
    return 0;
  }

  proc f(options:[] int, state:[] int) throws {
    var opstate = concatRight(options, state);
    if opstate.shape[2] != this.model.inputDim() then
      throw new DimensionMatchError(msg="Wrong input size to model on f()"
        ,expected=this.model.inputDim(), actual=opstate.shape[2]);
    // This returns a matrix, not a vector
    // In our case, it is just one row tall, so we
    // grab the first row
    var rn:[1..1] real;
    fillRandom(rn);
    if this.epsilon > 0 && rn[1] < this.epsilon then return this.randomAction(options);
    //var a = this.model.predict(opstate);
    var a = this.model.predict(opstate.T);
    var r:[1..options.shape[2]] int;
    r = options[argmax(a[1,..]), ..];
    return r;
  }

}
