use worlds;

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
      //writeln("** BAD POINT ", position.x, ",", position.y);
      return false;
    }
  }

  proc canMove(agent: Agent, sensor:Sensor, choice:[] int) {
      var a = agent:BoxWorldAgent;
      var p = this.moveAlong(from=a.position, theta=sensor.unbin(choice), speed=agent.speed);
      return this.isValidPosition(p);
  }

  proc addAgent(name: string, position: Position2D, speed: real = 3.0) {
    var agent = new BoxWorldAgent(name=name, position=position, speed=speed);
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
