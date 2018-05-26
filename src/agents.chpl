use NumSuch, worlds, policies, rewards;

// Should be abstracted to something like DQNAgent
//class Agent : Perceivable {
class Agent {
  var name: string,
      maxMemories: int,
      currentStep: int,
      nMemories: int,
      done: bool,
      id: int,
      sensors: [1..0] Sensor,
      servos: [1..0] Servo,
      policy: Policy,
      finalized: bool = false,
      rewards: [1..0] Reward,
      memoriesDom = {1..0},
      memories: [memoriesDom] Memory,
      position: Position,
      speed: real;

  proc init(name:string
      , maxMemories: int = 100000) {
    //this.speed=speed;
    this.name=name;
    this.maxMemories = maxMemories;
    this.currentStep = 1;
    this.nMemories = 0;
    this.done = false;
    this.memoriesDom = {1..this.maxMemories};
  }

  proc add(servo: Servo) {
    return this.addServo(servo);;
    return this;
  }

  proc addServo(servo: Servo) {
    //servo.optionIndexStart = this.optionDimension() + 1;
    //servo.optionIndexEnd = servo.optionIndexStart + servo.dim() - 1;
    this.servos.push_back(servo);
    return this;
  }

  proc add(memory: Memory) throws {
    if memory.state.size != this.sensorDimension() then
      throw new DimensionMatchError(msg="Memory state. ", expected=this.sensorDimension(), actual=memory.state.size);
    if memory.action.size != this.optionDimension() then
      throw new DimensionMatchError(msg="Memory action. ", expected=this.optionDimension(), actual=memory.action.size);

    this.memories[this.nMemories % maxMemories + 1] = memory;
    this.nMemories +=1;
    return this;
  }

  /*
  @TODO I don't like this because the Sensor now lives in two places.
   */
  proc addTarget(target: Agent, sensor: Sensor, avoid: bool = false) {
      this.policy = new FollowTargetPolicy(sensor=sensor, avoid=avoid);
      this.addSensor(sensor=sensor);
      return sensor;
  }

  /*
  For the dog to see the cat, it needs a target, a sensor and a tiler
   */
  proc addSensor(sensor: Sensor) {
    sensor.id = this.sensors.size+1;
    sensor.stateIndexStart = this.sensorDimension() + 1;
    sensor.stateIndexEnd = sensor.stateIndexStart + sensor.dim() - 1;
    this.sensors.push_back(sensor);
    return this;
  }

  proc addSensor(target: Perceivable, sensor: Sensor, reward: Reward) {
    sensor.target = target;
    this.addSensor(sensor=sensor);

    reward.stateIndexStart = sensor.stateIndexStart;
    reward.stateIndexEnd = sensor.stateIndexEnd;
    this.rewards.push_back(reward);
    return this;
  }

  proc setPolicy(policy: Policy) {
    this.policy=policy;
    return this;
  }

  /* Expects an integer array of options */
  proc choose(options: [] int, state: [] int) {
      //writeln("options: ", options);
      //writeln("state: ", state);
      const choice = this.policy.f(options=options, state=state);
      return choice;
  }

  proc finalize() {
    var t: bool = true;
    t = t && this.policy.finalize(agent = this);
    t = t && this.servos.size > 0;
    t = t && this.sensors.size > 0;
    for reward in this.rewards {
      t = t && reward.finalize();
    }
    this.finalized = t;
    return this.finalized;
  }

  proc act(choice:[] int) {
    for servo in this.servos {
      servo.f(agent=this, choice=choice);
    }
    return this;
  }

  proc learn() {
    this.policy.learn(agent=this);
  }

  /*
   This really need to be abstracted
   */
  proc distanceFromMe(you: Perceivable) {
    return this.distanceFromMe(you.position);
  }

  proc distanceFromMe(you: Position) {
    return dist(this.position, you);
  }

  proc angleFromMe(you: Perceivable) {
    return angleFromMe(you.position);
  }

  proc angleFromMe(you: Position) {
    return angle(this.position, you);
  }

  /* Move along an angle */
  proc moveAgentAlong(theta: real) {
    this.position = moveAlong(from=this.position, theta=theta, speed=this.speed);
  }

  proc optionDimension() {
    var n: int = 0;
    for servo in this.servos {
      n += servo.dim();
    }
    return n;
  }

  proc sensorDimension() {
    var n = 0;
    for sensor in this.sensors do n += sensor.dim();
    return n;
    //return this.policy.sensorDimension();
  }

  proc readWriteThis(f) throws {
    f <~> "%6i".format(this.id) <~> " "
      <~> "%7s".format(this.name) <~> " ";
      //<~> "%4r".format(this.position.x) <~> " "
      //<~> "%4r".format(this.position.y);
  }

  proc writeRecord() {
    return new AgentRecord(id=this.id, name=this.name
      , x=this.position.x, y=this.position.y);
  }
}


class Perceivable {
  var name: string,
      position: Position,
      initialPosition: Position,
      id: int;
  proc init(name: string, position: Position) {
    this.name = name;
    this.position = position;
    this.initialPosition = position;
    this.id = -1;
  }
}

class Herd : Perceivable {
  type species;
  proc init(name: string, position: Position, type species) {
    super.init(name=name, position=new Position());
    this.species = species;
    this.complete();
  }


  proc findPositionOfNearestMember(me: Agent, agents: [] Agent) {
    var p = new Position(),
        d: real = -1;
    for agent in agents {
      if agent:this.species != nil {
        const dd = dist(me, agent);
        if dd < d || d < 0 {
          p.x = agent.position.x;
          p.y = agent.position.y;
          d = dd;
        }
      }
    }
    return p;
  }

  proc findNearestMember(me: Agent, agents: [] Agent) {
    var a: Agent,
        d: real = -1;
    for agent in agents {
      if agent:this.species != nil {
        const dd = dist(me, agent);
        if dd < d || d < 0 {
          a = agent;
          d = dd;
        }
      }
    }
    return a;
  }
}

class ConcealedCarryAgent: Agent {
  var packDom: domain = {1..0},
      pack: [1..0] int;
  proc init(name: string, capacity:int) {
      super.init(name=name);
      this.complete();
      this.packDom = {1..capacity};
  }
}

class BoxWorldAgent : Agent {
  var position: Position2D;

  proc init(name: string, speed: real, position: Position2D) {
    super.init(name=name);
    this.complete();
    this.speed= speed;
    this.position=position;
  }
}

// Used for default targets like CellSensor or ClockSensor
class SecretAgent: Agent {
  proc init() {
    super.init(name="Secret Agent");
    this.complete();
  }
}

class Memory {
  var stateDom = {1..0},
      actionDom = {1..0},
      state: [stateDom] int,
      action: [actionDom] int,
      reward: real;
  proc init(state:[] int, action:[] int, reward: real) {
    this.stateDom = state.domain;
    this.actionDom = action.domain;
    this.state = state;
    this.action = action;
    this.reward = reward;
  }

  proc dim() {
    return this.stateDom.size + this.actionDom.size;
  }

  // return action concat with state
  proc v() {
    var v = concat(this.action, this.state);
    return v;
  }
}
