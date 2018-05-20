/* Documentation for Relch */
module Relch {
  use Math, NumSuch;
  use agents, policies, physics, rewards;

  /*
  use worlds;
  config const N_EPISODES: int,
               PRINT_PATHS: bool,
               LEARNING_STEPS: int,
               BOARD_WIDTH: int,
               BOARD_HEIGHT: int,
               STEP_PENALTY: int,
               DEATH_PENALTY: int,
               GOAL_REWARD: int,
               INITIAL_STATE: string,
               GOAL_STATE: string,
               LEARNING_RATE: real,   // alpha
               DISCOUNT_FACTOR: real, // gamma
               TRACE_DECAY: real;     // lambda

  */

  /* Modeled after the AIGym Class: https://github.com/openai/gym/tree/master/gym/envs#how-to-create-new-environments-for-gym* */
  class Environment {
    var name: string,
        currentStep: int,
        world: World,
        agents: [1..0] Agent,
        perceivables: [1..0] Perceivable;

    proc init(name: string) {
      this.name=name;
      this.currentStep = 1;
    }


    /*
     This needs to return these things:
     1. The new state (e.g. relative positions to other objects), [] int
     2. Reward: real
     3. Done: bool, should the simumlation stop now?
     4. New Position: In several sims, the actual position is not part of the state space
        so use this to give the agent his new position
     */
    proc step(agent: Agent, action:[] int) {
        var state: [1..agent.sensorDimension()] int = buildAgentState(agent=agent);
        var reward = this.dispenseReward(agent=agent, state=state);
        var done: bool = this.areYouThroughYet(agent=agent, any=true);  // Yes, this is a Steve Martin reference
        agent.currentStep += 1;
        return (state, reward, done);
    }

    proc reset() {
      this.resetAgents();
    }

    proc resetAgents() {
      for agent in this.agents do this.resetAgent(agent);
    }
    proc resetAgent(agent: Agent) {
      agent.currentStep = 1;
      agent.position = agent.initialPosition;
      agent.done = false;
      //for sensor in agent.policy.sensors {
      for sensor in agent.sensors {
        sensor.done = false;
      }
      for reward in agent.rewards do reward.accomplished = false;
    }

    /* This will actually emit, not render */
    proc render() {}

    proc add(perceivable: Perceivable) {
      perceivable.simId = this.perceivables.size +1;
      this.perceivables.push_back(perceivable);
      return perceivable;
    }

    proc add(agent: Agent) {
      agent.simId = this.perceivables.size + 1;
      this.perceivables.push_back(agent);
      this.agents.push_back(agent);
      return agent;
    }

    /*
     Setting interactions between objects
     */

    /*
    Creates a FollowTargetPolicy for the agent against the target
     */
    proc setAgentTarget(agent: Agent, target: Perceivable, sensor: Sensor, avoid:bool=false) {
      if agent.simId < 1 then this.add(agent);
      if target.simId < 1 then this.add(target);
      sensor.targetId = target.simId;
      agent.addTarget(target, sensor, avoid);
      return agent;
    }

    /*
    Pass through
     */
    proc addAgentServo(agent: Agent, servo: Servo) {
      return agent.add(servo);
    }

    proc addAgentSensor(agent: Agent, target: Perceivable, sensor: Sensor) {
      if agent.simId <1 then this.add(agent);
      if target.simId <1 then this.add(target);
      sensor.targetId = target.simId;
      agent.addSensor(target=target, sensor=sensor);

      return agent;
    }

    /*
     Add a sensor with a reward attached
     */
    proc addAgentSensor(agent:Agent, target:Perceivable, sensor:Sensor, reward: Reward) {
      if agent.simId <1 then this.add(agent);
      if target.simId <1 then this.add(target);
      sensor.targetId = target.simId;
      agent.addSensor(target=target, sensor=sensor, reward=reward);
      return agent;
    }

    /*
     Set the Agent Policy
     */
    proc setAgentPolicy(agent: Agent, policy: Policy) {
      agent.setPolicy(policy);
      return agent;
    }

    proc presentOptions(agent: Agent) {
      /* Constructing options is kinda hard, right now just 1 for every
         element of the sensors */
      var optDom = {1..0, 1..agent.optionDimension()},
          options: [optDom] int = 0;

      //writeln("building options");
      var apos = agent.position;
      for s in 1..agent.servos.size {
        const servo = agent.servos[s];
        //writeln("servo ", servo);
        // Copying this so we can repeat it for later sensors
        var optSnapshot: [1..options.shape[1], 1..options.shape[2]] int  = options;
        var nAddedOptions: int = 0;
        var sDom = {servo.optionIndexStart..servo.optionIndexEnd};
        var currentRowNumber = 0;
        for i in sDom {
          var a: [sDom] int = 0;
          a[i] = 1;
          var theta = servo.tiler.unbin(a);
          var p = moveAlong(from=agent.position, theta=theta, speed=agent.speed);
          // Need to add a row to the options
          if this.world.isValidPosition(p) {
            //writeln("valid point ", p);
            // Might be the first one
            if s == 1 {
              //writeln("s==1");
              optDom = {1..optDom.dims()(1).high +1, optDom.dims()(2)};
              for x in sDom do options[optDom.dims()(1).high,x] = a[x];
            } else {
              halt("Only one servo supported.");
            }
             /*
             else if s > 1 && nAddedOptions == 0 {   // First new option, so add to the empty space
              writeln("s> 1, nop 0");
              const nr = optSnapshot.domain.dims()(1).high;
              for j in 1..nr {
                for x in servo.optionIndexStart..servo.optionIndexEnd do options[j,x] = a[x-servo.optionIndexStart+1];
              }
            } else if s > 1 && nAddedOptions > 0 {  // In this case you have to copy all the previous lines and add the options
              writeln("s> 1, nop > 0");
              const nr = optSnapshot.shape[1];
              for j in 1..nr {
                var currentRow: [1..optDom.dims()(2).high] int = options[j,..];
                currentRow[servo.optionIndexStart..servo.optionIndexEnd] = a;
                optDom = {1..optDom.dims()(1).high+1, optDom.dims()(2)};
                options[optDom.dims()(1).high, ..] = currentRow;
              }
            } */

            nAddedOptions += 1;
            currentRowNumber += 1;
            //writeln("end valid point");
          } else {
            //writeln("Not a valid position: ", p);
          }
        }
      }

      // Right now, this just constructs the state from the Agent as a pass
      // through.  Soon it will make decisions;
      //writeln("building state for ", agent.name);
      var state = buildAgentState(agent=agent);
      //var state: [1..3] int = [0, 0, 1];

      //writeln("exiting presentOptions");
      return (options, state);
    }

    /*
     This is here so ultimately the environment can edit the sensors
     */
    proc buildAgentState(agent: Agent) {
      writeln("building state for ", agent.name);

      var state: [1..agent.sensorDimension()] int;
      for sensor in agent.sensors {
          ref you = this.perceivables[sensor.targetId];
          //writeln("me ", agent);
          //writeln("you ", you);
          //writeln("sensor: ", sensor);
          var a:[sensor.stateIndexStart..sensor.stateIndexEnd] int = sensor.v(me=agent, you=you);
          state[a.domain] = a;
      }
      writeln("exiting build state for ", agent.name);
      return state;
    }

    proc dispenseReward(agent: Agent, state: [] int) {
      var r: real = 0.0;
      for reward in agent.rewards {
        r += reward.f(state);
      }
      return r;
    }

    // If any sensor is done, you are done
    // Otherwise all sensors must be done
    proc areYouThroughYet(agent: Agent, any: bool = true) {
      var r: bool = false;
      //if this.currentStep >= this.steps then r = true;
      if any {
        for reward in agent.rewards {
          if reward.accomplished then writeln("sim halted by agent ", agent.name);
          if reward.accomplished then return true;
        }
      }
      return r;
    }

    /*
    This should probably be a class;
    Yes, this is a King Gizzard reference
     */
    proc robotStop() {
      for agent in this.agents  {
        if agent.done then return true;
      }
      return false;
    }

    /*
      Does the actual simulation
     */
    iter run(epochs: int, steps: int) {
      if this.world == nil {
        halt("No world set, aborting");
      }
      var finalized: bool = true;
      for agent in this.agents {
        writeln("finalizing ", agent.name);
        if !agent.finalized {
          finalized = finalized && agent.finalize();
        }
        if !agent.finalized then halt("Agent ", agent.name, " cannot be finalized, halting.");
      }
      for i in 1..epochs {
        writeln("starting epoch ", i);
        var keepSteppin: bool = true,
            step: int = 1;
        //for step in 1..steps {
        while keepSteppin {
          var sr = new StepReport(epoch=i, step=step);
        //writeln("\tstarting step ", step);
          for agent in this.agents{
            //writeln("\t\tagent: ", agent);
            if agent.done then continue;
            agent.currentStep = step;
            // DM presents options
            writeln("\t\tpresenting options");
            var (options, currentState) = this.presentOptions(agent);
            //if agent.name == "dog" then writeln(options);
            // A chooses an action
            writeln("\t\tagent choosing");
            var choice = agent.choose(options, currentState);
            writeln("\t\tagent acting");
            agent.act(choice);
            // DM rewards
            writeln("\t\tstepping");
            var (nextState, reward, done) = this.step(agent=agent, action=choice);
            // Add the memory
            try! agent.add(new Memory(state=nextState, action=choice, reward=reward));
            if done {
              agent.done = true;
              break;
            }
            // Return A
            yield agent;
          }
          //writeln(sr);
          if this.robotStop() {
            keepSteppin = false;
          }
          step += 1;
          if steps > 0 && step >= steps then keepSteppin = false;
        }
        step = 0;
        for agent in this.agents {
          writeln("larnin!");
          agent.learn();
        }
        this.reset();
      }
    }
  }

  class StepReport {
    var epoch: int,
        step: int;
    proc init(epoch:int, step:int) {
      this.epoch = epoch;
      this.step = step;
    }

    proc readWriteThis(f) {
      f <~>
      "epoch: " <~> this.epoch <~>
      " step: " <~> this.step <~> "\n";
    }
  }
}
