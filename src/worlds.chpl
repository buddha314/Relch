use physics, agents;
/*
 Provides some basic machinery, including default tilers for sensors
 */
class World {
  var agents: [1..0] Agent,
      perceivables: [1..0] Perceivable;

  proc init() {
  }

  proc addAgent(agent:Agent) {
    agent.id = this.agents.size+1;
    this.agents.push_back(agent);
    return agent;
  }
  /*
  proc addAgent(agent: Agent, position: Position) {
    return agent;
  } */

  proc addAgentSensor(agent: Agent, target: Perceivable, sensor: Sensor) {
    if agent.id <1 then this.add(agent);
    if target.id <1 then this.add(target);
    sensor.targetId = target.id;
    agent.addSensor(target=target, sensor=sensor);
    return agent;
  }

  /*
   Add a sensor with a reward attached
   */
  proc addAgentSensor(agent:Agent, target:Perceivable, sensor:Sensor, reward: Reward) {
    if agent.id < 1 then this.add(agent);
    if target.id < 1 then this.add(target);
    sensor.targetId = target.id;
    agent.addSensor(target=target, sensor=sensor, reward=reward);
    return agent;
  }

  proc randomPosition() {
    return this.randomPosition();
  }

  /*
   This world decides if that position is valid
   */
  proc isValidPosition(position: Position ) {
    return false;
  }

  /*
   Gets the options on a single motion servo
   */
  proc getMotionServoOptions(agent: Agent, servo: MotionServo) {
    var options:[1..0] int;
    return options;
  }

  /* Returns a position from the original point along theta */
  proc moveAlong(from: Position2D, theta: real, speed: real) {
    const p = new Position2D(x=from.x + speed*cos(theta), y=from.y + speed*sin(theta) );
    return p;
  }


  proc getDefaultAngleSensor() {
    return new AngleSensor(name="Default Angle Sensor", tiler=this.defaultAngleTiler);
  }

  /*
   Uses the default linear tiler over the radius of the world
   */
  proc getDefaultDistanceSensor() {
    return new DistanceSensor(name="Default Distance Sensor", tiler=this.defaultLinearTiler);
  }

  proc getDefaultMotionServo() {
    return new Servo(tiler=this.defaultAngleTiler);
  }

  /*
   Default is to be within 1 tile of the target
   */
  proc getDefaultProximityReward() {
    //return new ProximityReward(proximity=3);
    return new ProximityReward(proximity=1);
  }

  proc findCentroid(herd: Herd) {
    return this.findCentroid(herd=herd, perceivables=this.perceivables);
  }

  proc findCentroid(herd: Herd, perceivables: [] Perceivable) {
    return new Position();
  }
}

class BoxWorld: World {
  var wrap: bool,
      defaultDistanceBins: int,
      defaultDistanceOverlap: real,
      defaultAngleBins: int,
      defaultAngleOverlap: real,
      width: int,
      height: int,
      radius: real;

  proc init(width:int, height: int
      ,wrap: bool = false
      ,defaultDistanceBins: int = 17, defaultDistanceOverlap: real= 0.1
      ,defaultAngleBins: int = 11, defaultAngleOverlap: real = 0.05
    ) {
      this.wrap = wrap;
      this.defaultDistanceBins = defaultDistanceBins;
      this.defaultDistanceOverlap = defaultDistanceOverlap;
      this.defaultAngleBins = defaultAngleBins;
      this.defaultAngleOverlap = defaultAngleOverlap;
      this.width=width;
      this.height=height;
      this.radius = sqrt(this.width**2 + this.height**2);
  }

  proc isValidPosition(position: Position2D ) {
    if wrap {
      return true;
    } else if position.x >= 0 && position.x < this.width
              && position.y >= 0 && position.y <= this.height {
      return true;
    } else {
      return false;
    }
  }

  proc addAgent(name: string, position: Position2D, speed: real = 3.0) {
    var agent = new BoxWorldAgent(name=name, position=position, speed=3.0);
    agent.id = this.agents.size+1;
    this.agents.push_back(agent);
    return agent;
  }

  proc addAgentSensor(agent: BoxWorldAgent, target: BoxWorldAgent, sensor: Sensor) {
    if agent.id <1 then this.addAgent(agent);
    if target.id <1 then this.addAgent(target);
    sensor.meId = agent.id;
    sensor.youId = target.id;
    agent.addSensor(sensor=sensor);
    return agent;
  }

  proc addAgentServo(agent: BoxWorldAgent, servo: Servo, sensor: Sensor) {
    if agent.id < 1 then this.addAgent(agent);
    // Sensor has not been assigned, need to add it, then get last sensor added
    if sensor.meId < 1 then agent.addSensor(sensor);
    servo.sensorId = sensor.id;
    servo.optionIndexStart = agent.optionDimension() + 1;
    servo.optionIndexEnd = servo.optionIndexStart + sensor.dim() -1;
    agent.addServo(servo);
    return agent;
  }

  /*
   Gets the options on a single motion servo
   */
  proc getMotionServoOptions(agent: BoxWorldAgent, servo: MotionServo) {
    var sDom = {servo.optionIndexStart..servo.optionIndexEnd},
        optDom: domain(2),
        options: [optDom] int = 0,
        sensor: Sensor,
        currentRow: int = 1; // We will populate the first row for sure

    optDom = {1..currentRow, servo.optionIndexStart..servo.optionIndexEnd};
    // Add a null action (should always be an option)
    sensor = agent.sensors[servo.sensorId];
    options[currentRow,..] = 0;
    // Build a one-hot for each option
    for i in servo.optionIndexStart..servo.optionIndexEnd {
      var a:[servo.optionIndexStart..servo.optionIndexEnd] int = 0;
      a[i] = 1;
      var p = this.moveAlong(from=agent.position, theta=sensor.unbin(a), speed=agent.speed);
      if this.isValidPosition(p) {
        currentRow += 1;
        optDom = {1..currentRow, servo.optionIndexStart..servo.optionIndexEnd};
        options[currentRow, ..] = a;
      }
    }
    return options;
  }


  proc randomPosition() {
    const x = rand(1, this.width),
          y = rand(1, this.height);
    return new Position2D(x = x, y=y);
  }

  proc findCentroid(herd: Herd) {
    return this.findCentroid(herd=herd, perceivables=this.perceivables);
  }
  proc findCentroid(herd: Herd, perceivables:[] Perceivable) {
    var x: real = 0.0,
        y: real = 0.0,
        n: int = 0;
    var p = new Position();
    for perceivable in perceivables{
      // Make sure we have the correct target agent class
      //if agent:this.species != nil {
      if perceivable:herd.species != nil {
        x += perceivable.position.x;
        y += perceivable.position.y;
        n += 1;
      }
    }
    p.x = x/n;
    p.y = y/n;
    return p;
  }

  proc getDefaultDistanceSensor() {
    return new LinearSensor(nbins=this.defaultDistanceBins
      ,x1=0, x2=this.radius
      ,overlap=this.defaultDistanceOverlap
      ,wrap=this.wrap);
  }

  proc getDefaultAngleSensor() {
    return new AngleSensor2D(nbins = this.defaultAngleBins
      ,overlap=this.defaultAngleOverlap
      ,theta0=-pi, theta1=pi, wrap=true);
  }

  proc dist(me: Agent, you: Agent) {
    return dist(me.position, you.position);
  }
  proc dist(me: Agent, you: Position) {
    return dist(me.position, you);
  }
  proc dist(origin: Position, target: Position) {
    return sqrt((origin.x - target.x)**2 + (origin.y - target.y)**2);
  }
}


/*
 A Sensor it attached to a source, target and does its own tiling
 */
class Sensor {
  var nbins: int,
      dom: domain(2),
      bins: [dom] real,
      overlap: real,
      wrap: bool,
      meId: int,
      youId: int,
      stateIndexStart: int,
      stateIndexEnd: int,
      id: int;  // internal id
  proc init(nbins: int, overlap:real, wrap:bool) {
    this.nbins = nbins;
    this.dom = {1..nbins, 1..2};
    this.meId = -1;
    this.id = -1;
  }

  proc v(me:Agent, you:Agent) {
    var state:[1..0] int;
    return state;
  }

  proc unbin(x:[] int) {
    // x has a sub-domain of state, so need to normalize
    var y: [1..x.size] int = x;
    this.checkDim(x);
    var r: real = 0.0;
    for i in y.domain {
      if y[i] == 1 {
        r = (this.bins[i,1] + this.bins[i,2]) / 2 ;
        break;
      }
    }
    return r;
  }

  proc makeBins(x1: real, x2: real){
    const width = (x2-x1)/this.nbins;
    if this.overlap <= 0 {
      this.overlap = 0;
    } else {
      this.overlap = this.overlap * width;
    }
    for i in 1..this.nbins {
      this.bins[i, 1] = x1 + (i-1)*(width) - this.overlap;
      this.bins[i, 2] = x1 + (i)*(width) + this.overlap;
    }
  }

  proc dim() {
    return this.nbins;
  }
  proc checkDim(x:[] int) throws {
    if x.size != this.nbins {
      const err = new DimensionMatchError(msg="checking dimensions on Tiler", expected = this.nbins, actual=x.size);
      throw err;
    }
  }

  proc bin(x: real) {
    var v:[1..this.nbins] int = 0;
    for i in 1..this.nbins {
      if x >= this.bins[i,1] && x <= this.bins[i,2] {
          v[i] = 1;
        }
    }
    if this.wrap {
      // Note the right bracket already has this.overlap added
      if x >= this.bins[this.nbins,2] - 2* this.overlap && x <= this.bins[this.nbins,2] {
        v[1] = 1;
      } else if x >= this.bins[1,1]  && x <= this.bins[1,1] + 2*this.overlap {
        v[this.nbins] = 1;
      }
    }
    return v;
  }
}

class LinearSensor: Sensor {
  proc init(nbins: int, x1: real, x2: real, overlap:real=-1, wrap:bool=false) {
    super.init(nbins=nbins, overlap=overlap, wrap=wrap);
    this.complete();
    this.makeBins(x1=x1, x2=x2);
  }

  proc makeBins(x1: real, x2: real){
    const width = (x2-x1)/this.nbins;
    if this.overlap <= 0 {
      this.overlap = 0;
    } else {
      this.overlap = this.overlap * width;
    }
    for i in 1..this.nbins {
      this.bins[i, 1] = x1 + (i-1)*(width) - this.overlap;
      this.bins[i, 2] = x1 + (i)*(width) + this.overlap;
    }
  }

  proc unbin(x:[] int) {
    // x has a sub-domain of state, so need to normalize
    var y: [1..x.size] int = x;
    this.checkDim(x);
    var r: real = 0.0;
    for i in y.domain {
      if y[i] == 1 {
        r = (this.bins[i,1] + this.bins[i,2]) / 2 ;
        break;
      }
    }
    return r;
  }

  proc bin(x: real) {
    var v:[1..this.nbins] int = 0;
    for i in 1..this.nbins {
      if x >= this.bins[i,1] && x <= this.bins[i,2] {
          v[i] = 1;
        }
    }
    if this.wrap {
      // Note the right bracket already has this.overlap added
      if x >= this.bins[this.nbins,2] - 2* this.overlap && x <= this.bins[this.nbins,2] {
        v[1] = 1;
      } else if x >= this.bins[1,1]  && x <= this.bins[1,1] + 2*this.overlap {
        v[this.nbins] = 1;
      }
    }
    return v;
  }

  proc v(me:Agent, you:Agent) {
    var m = me: BoxWorldAgent,
        y = you: BoxWorldAgent;
    var d = sqrt((m.position.x-y.position.x)**2 + (m.position.y-y.position.y)**2);
    return this.bin(d);
  }
}

class AngleSensor2D: Sensor {
  proc init(nbins: int, overlap:real, theta0=-pi, theta1=pi, wrap:bool=true) {
    super.init(nbins=nbins, overlap:real, wrap: bool);
    this.complete();
    this.makeBins(x1=theta0, x2=theta1);
  }

  proc v(me: Agent, you: Agent) {
    var m = me:BoxWorldAgent,
        y = you:BoxWorldAgent;
    const a = angle2D(m.position, y.position);
    var v:[1..this.dim()] int = this.bin(a);
    return v;
  }

}

proc angle2D(x:Position2D, y: Position2D) {
  return atan2((y.y - x.y) , (y.x - x.x));
}
