use physics, policies;

// Should be abstracted to something like DQNAgent
class Agent : Perceivable {
  var speed: real,
      sensors: [1..0] Sensor,
      servos: [1..0] Servo,
      d: domain(2),
      Q: [d] real,
      E: [d] real,
      policy: Policy,
      compiled : bool = false,
      currentStep: int,
      done: bool;

  proc init(name:string
      , position:Position = new Position()
      , speed: real = 3.0 ) {
    super.init(name=name, position=position);
    this.complete();
    this.speed=speed;
    this.currentStep = 1;
    this.done = false;
  }

  proc add(sensor : Sensor) {
    this.sensors.push_back(sensor);
    return this;
  }

  proc add(servo: Servo) {
    this.servos.push_back(servo);
    return this;
  }

  /* Expects an integer array of options */
  proc choose(options: [] int, state: [] int) {
      const choice = this.policy.f(options=options, state=state);
      //return act(choice);
      return choice;
  }

  proc act(choice:[] int) {
    var k: int = 1;
    for servo in this.servos {
      var c: [1..servo.dim()] int = choice[k..(k+servo.dim())];
      servo.f(agent=this, choice=c);
      k += servo.dim() + 1;
    }
    return this;
  }

  proc compile() {
    var m: int = 1;  // collects the total size of the feature space
    var n: int = 0;
    for f in this.sensors{
      n += f.size;
    }
    this.d = {1..m, 1..n};
    var X:[d] real;
    fillRandom(X);
    var nm = new NamedMatrix(X=X);
    fillRandom(this.Q);
    fillRandom(this.E);
    this.compiled = true;
  }

  /*
   This really need to be abstracted
   */
  proc distanceFromMe(you: Agent) {
    return dist(this.position, you.position);
  }

  proc angleFromMe(you: Agent) {
    return angle(this.position, you.position);
  }

  /* Move along an angle */
  proc moveAlong(theta: real) {
    this.position.x += this.speed * cos(theta);
    this.position.y += this.speed * sin(theta);
  }

  proc optionDimension() {
    var n: int = 0;
    for servo in this.servos {
      n += servo.tiler.nbins;
    }
    return n;
  }

  proc sensorDimension() {
    var n: int = 0;
    for sensor in this.sensors {
      n += sensor.dim();
    }
    return n;
  }


  proc readWriteThis(f) throws {
    f <~> "%25s".format(this.name) <~> " "
      <~> "%4r".format(this.position.x) <~> " "
      <~> "%4r".format(this.position.y);
  }
}

class Perceivable {
  var name: string,
      position: Position;
  proc init(name: string, position: Position) {
    this.name = name;
    this.position = position;
  }
}

class Herd : Perceivable {
  type species;
  proc init(name: string, position: Position, type species) {
    super.init(name=name, position=new Position());
    this.species = species;
    this.complete();
  }

  proc findCentroid(agents: [] Agent) {
      var x: real = 0.0,
          y: real = 0.0,
          n: int = 0;
      var p = new Position();
      for agent in agents {
        // Make sure we have the correct target agent class
        if agent:this.species != nil {
          x += agent.position.x;
          y += agent.position.y;
          n += 1;
        }
      }
      p.x = x/n;
      p.y = y/n;
      return p;
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
