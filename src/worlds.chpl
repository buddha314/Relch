use physics, agents, sensors;
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

  /*
   This is here so ultimately the environment can edit the sensors
   */
  proc buildAgentState(agent: Agent) {
    //writeln("building state for ", agent.name);

    var state: [1..agent.sensorDimension()] int;
    for sensor in agent.sensors {
        //ref you = this.perceivables[sensor.youId];
        ref you = this.agents[sensor.youId];
        //writeln("me ", agent);
        //writeln("you ", you);
        //writeln("sensor: ", sensor);
        var a:[sensor.stateIndexStart..sensor.stateIndexEnd] int = sensor.v(me=agent, you=you);
        state[a.domain] = a;
    }
    //writeln("exiting build state for ", agent.name);
    return state;
  }

}
