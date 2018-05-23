use physics, agents;
/*
 Provides some basic machinery, including default tilers for sensors
 */
class World {
  var radius: real,
      wrap: bool,
      agents: [1..0] Agent,
      perceivables: [1..0] Perceivable,
      defaultLinearTiler: LinearTiler,
      defaultAngleTiler: AngleTiler;

  proc init(wrap: bool = false
      ,defaultDistanceBins: int = 17, defaultDistanceOverlap: real= 0.1
      ,defaultAngleBins: int = 11, defaultAngleOverlap: real = 0.05
    ) {
    this.defaultLinearTiler = new LinearTiler(nbins=defaultDistanceBins, x1=0.0
      ,x2=this.radius, overlap=defaultDistanceOverlap, wrap=this.wrap);
    this.defaultAngleTiler = new AngleTiler(nbins=defaultAngleBins
      ,overlap=defaultAngleOverlap);
    //this.defaultMotionServo = new Servo(tiler=this.defaultAngleTiler);
  }

  proc addAgent(agent: Agent, position=new Position) {
    agent.position=position;
    this.agents.push_back(agent);
    return agent;
  }

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
    if agent.id <1 then this.add(agent);
    if target.id <1 then this.add(target);
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
    var sDom = {servo.optionIndexStart..servo.optionIndexEnd},
        optDom = {1..1, sDom},
        options: [optDom] int = 0;

    // Add a null action (should always be an option)
    optDom[1,..] = 0;
    // Build a one-hot for each option
    var currentRow = 1;
    for i in sDom {
      var a:[sDom] int = 0;
      a[i] = 1;
      var p = this.moveAlong(from=agent.position, theta=servo.tiler.unbin(a), speed=agent.speed);
      if this.isValidPosition(p) {
        optDom = {1..optDom.high+1, sDom};
        //for j in sDom do optDom[currentRow, j] = a[j];
        optDom[currentRow, ..] = a;
        currentRow += 1;
      }
    }
    return options;
  }

  /* Returns a position from the original point along theta */
  proc moveAlong(from: Position, theta: real, speed: real) {
    const p = new Position(x=from.x + speed*cos(theta), y=from.y + speed*sin(theta) );
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

  /*
   Provides just the raw theta, not the tiling
   */
  proc findAngle(me: Perceivable, you: Perceivable) {
    return atan2((target.y - origin.y) , (target.x - origin.x));
  }
}

class BoxWorld : World {
  const width: int,
        height: int,
        dimension: int,
        radius: real;
  proc init(width:int, height: int, dimension:int = 2) {
      super.init();
      this.width=width;
      this.height=height;
      this.radius = sqrt(this.width**2 + this.height**2);
      this.complete();
  }

  proc isValidPosition(position: Position ) {
    if wrap {
      return true;
    } else if position.x >= 0 && position.x < this.width
              && position.y >= 0 && position.y <= this.height {
      return true;
    } else {
      return false;
    }
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

  proc dist(me: Agent, you: Agent) {
    return dist(me.position, you.position);
  }
  proc dist(me: Agent, you: Position) {
    return dist(me.position, you);
  }
  proc dist(origin: Position, target: Position) {
    return sqrt((origin.x - target.x)**2 + (origin.y - target.y)**2);
  }

  proc angle(origin: Position, target: Position) {
    return atan2((target.y - origin.y) , (target.x - origin.x));
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
      stateIndexEnd: int;
  proc init(nbins: int, overlap:real, wrap:bool) {
    this.nbins = nbins;
    this.dom = {1..nbins, 1..2};
    this.makeBins();
  }

  proc v(state:[] int) {}

  proc unbin(state:[] int) {
    return 0.0;
  }

  proc makeBins() {}

  proc dim() {
    return this.nbins;
  }
  proc checkDim(x:[] int) throws {
    if x.size != this.nbins {
      const err = new DimensionMatchError(msg="checking dimensions on Tiler", expected = this.nbins, actual=x.size);
      throw err;
    }
  }
}

class LinearSensor: Sensor {
  proc init(nbins: int, x1: real, x2: real, overlap:real=-1, wrap:bool=false) {
    super.init(nbins=nbins, overlap=overlap, wrap=wrap);
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
}

class AngleSensor2D: Sensor {
  proc init(nbins: int, overlap:real, theta0=-pi, theta1=pi, wrap:bool=true) {
    super.init(nbins=nbins, overlap:real, wrap: bool);
    this.complete();
  }

  proc v(me: Agent, you: Position) {
    const a = angle2D(me.position, you);
    const v:[1..this.dim()] int = this.bin(a);
    return v;
  }
}

proc angle2D(me: Position2D, you: Position2D) {

}
