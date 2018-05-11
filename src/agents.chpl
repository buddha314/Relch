use physics, policies;

// Should be abstracted to something like DQNAgent
class Agent : Perceivable {
  var speed: real,
      servos: [1..0] Servo,
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

  proc add(servo: Servo) {
    servo.optionIndexStart = this.optionDimension() + 1;
    servo.optionIndexEnd = servo.optionIndexStart + servo.dim();
    this.servos.push_back(servo);
    return this;
  }

  /* Expects an integer array of options */
  proc choose(options: [] int, state: [] int) {
      const choice = this.policy.f(options=options, state=state);
      return choice;
  }

  proc act(choice:[] int) {
    for servo in this.servos {
      servo.f(agent=this, choice=choice);
    }
    return this;
  }

  proc compile() {
    var m: int = 1;  // collects the total size of the feature space
    var n: int = 0;
    for f in this.sensors{
      n += f.size;
    }
    this.compiled = true;
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
      n += servo.tiler.nbins;
    }
    return n;
  }

  proc sensorDimension() {
    return this.policy.sensorDimension();
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
