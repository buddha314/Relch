use physics, agents, sensors, mazeWorld, dtos;
/*
 Provides some basic machinery, including default tilers for sensors
 */
class World {
  var agents: [1..0] Agent;

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

  //proc addAgentSensor(agent: Agent, target: Agent, sensor: Sensor) {
  proc addAgentSensor(agent, target, sensor: Sensor) {
    writeln(" ** default add agent sensor");
    if agent.id <1 then this.addAgent(agent);
    if target.id <1 then this.addAgent(target);
    sensor.meId = agent.id;
    sensor.youId = target.id;
    agent.addSensor(sensor=sensor);
    return agent;
  }

  /*
   Add a sensor with a reward attached
   */
  proc addAgentSensor(agent, target, sensor:Sensor, reward: Reward) {
    writeln("default sensor reward");
    if agent.id < 1 then this.addAgent(agent);
    if target.id < 1 then this.addAgent(target);
    sensor.youId = target.id;
    agent.addSensor(target=target, sensor=sensor, reward=reward);
    //reward.stateIndexStart = sensor.stateIndexStart;
    //reward.stateIndexEnd = sensor.stateIndexEnd;
    return agent;
  }

  proc setAgentPolicy(agent: Agent, policy: Policy) {
    return agent.setPolicy(policy);
  }

  proc setAgentTarget(agent: Agent, target: Agent, sensor: Sensor, avoid: bool=false) {
    if agent.id < 1 then this.addAgent(agent);
    if target.id < 1 then this.addAgent(target);
    sensor.youId = target.id;
    agent.addTarget(target=target, sensor=sensor, avoid=avoid);
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

  proc canMove(agent: Agent, servo: Servo, option:[] int) {
    return true;
  }

  proc dispenseReward(agent: Agent, state: [] int) {
    var r: real = 0.0;
    for reward in agent.rewards {
      writeln(" ** adding reward for ", agent.name);
      r += reward.f(state);
    }
    return r;
  }


  // If any sensor is done, you are done
  // Otherwise all sensors must be done
  proc areYouThroughYet(erpt: EpochDTO, agent: Agent, any: bool = true) {
    var r: bool = false;
    //if this.currentStep >= this.steps then r = true;
    if any {
      for reward in agent.rewards {
        if reward.accomplished then erpt.winner = agent.name;
        if reward.accomplished then return true;
      }
    }
    return r;
  }


  /*
   This needs to return these things:
   1. The new state (e.g. relative positions to other objects), [] int
   2. Reward: real
   3. Done: bool, should the simumlation stop now?
   4. New Position: In several sims, the actual position is not part of the state space
      so use this to give the agent his new position
   */
  proc step(erpt: EpochDTO, agent, action:[] int) {
    // Agent has to actually move now.
    for servo in agent.servos {
      servo.f(agent=agent, choice=action);
    }
    var nextState = this.buildAgentState(agent=agent);
    var reward = dispenseReward(agent=agent, state=nextState);
    var done = areYouThroughYet(erpt=erpt, agent=agent, any=true);
    return (nextState, reward, done);
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
    return new MotionServo();
  }

  /*
   Default is to be within 1 tile of the target
   */
  proc getDefaultProximityReward() {
    //return new ProximityReward(proximity=3);
    return new ProximityReward(proximity=1);
  }

  proc findCentroid(herd: Herd) {
    return this.findCentroid(herd=herd, agents=this.agents);
  }

  proc findCentroid(herd: Herd, agents: [] Agent) {
    return new Position();
  }

  /*
   This is here so ultimately the environment can edit the sensors
   */
  //proc buildAgentState(agent: Agent) {
  proc buildAgentState(agent) {
    //writeln("building state for ", agent.name);
    var state: [1..agent.sensorDimension()] int;
    for sensor in agent.sensors {
      if sensor.youId > 0 {
        ref you = this.agents[sensor.youId];
        var a:[sensor.stateIndexStart..sensor.stateIndexEnd] int = sensor.v(me=agent, you=you);
        //writeln("  a: ", a);
        state[a.domain] = a;
      }
    }
    //writeln("exiting build state for ", agent.name, " with state ", state);
    return state;
  }

}
