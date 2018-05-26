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
    var optDom: domain(2),
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

  proc presentOptions(agent: BoxWorldAgent) {
    var optDom: domain(2),
        options: [optDom] int;

    for s in 1..agent.servos.size {
      if s > 1 {
        halt("No more than one servo supported at the moment");
      }
      var servo = agent.servos[s];
      if servo: MotionServo != nil {
        var opts = this.getMotionServoOptions(agent=agent, servo=servo:MotionServo);
        optDom = opts.domain;
        options = opts;
      }
    }

    var state = this.buildAgentState(agent=agent);
    return (options, state);
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
