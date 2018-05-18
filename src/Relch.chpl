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
        epochs: int,
        steps: int,
        currentStep: int,
        world: World,
        agents: [1..0] Agent,
        perceivables: [1..0] Perceivable;

    proc init(name: string, epochs:int, steps: int) {
      this.name=name;
      this.epochs=epochs;
      this.steps=steps;
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

    proc reset(agent: Agent) {
      agent.currentStep = 1;
      agent.position = agent.initialPosition;
      agent.done = false;
      //for sensor in agent.policy.sensors {
      for sensor in agent.sensors {
        sensor.done = false;
      }
    }

    /* This will actually emit, not render */
    proc render() {}

    proc add(agent: Agent) {
        this.agents.push_back(agent);
    }

    proc add(perceivable: Perceivable) {
      this.perceivables.push_back(perceivable);
    }

    proc presentOptions(agent: Agent) {
      /* Constructing options is kinda hard, right now just 1 for every
         element of the sensors */
      var optDom = {1..0, 1..agent.optionDimension()},
          options: [optDom] int = 0;

      var apos = agent.position;
      for s in 1..agent.servos.size {
        const servo = agent.servos[s];
        // Copying this so we can repeat it for later sensors
        var optSnapshot: [1..options.shape[1], 1..options.shape[2]] int  = options;
        var nAddedOptions: int = 0;
        for i in 1..servo.dim() {
          var a: [1..servo.dim()] int = 0;
          a[i] = 1;
          var theta = servo.tiler.unbin(a);
          var p = moveAlong(from=agent.position, theta=theta, speed=agent.speed);
          // Need to add a row to the options
          if this.world.isValidPosition(p) {
            // Might be the first one
            if s == 1 {
              optDom = {1..optDom.dims()(1).high +1, optDom.dims()(2)};
              for x in servo.optionIndexStart..servo.optionIndexEnd do options[i,x] = a[x-servo.optionIndexStart+1];
            } else if s > 1 && nAddedOptions == 0 {   // First new option, so add to the empty space
              const nr = optSnapshot.domain.dims()(1).high;
              for j in 1..nr {
                for x in servo.optionIndexStart..servo.optionIndexEnd do options[j,x] = a[x-servo.optionIndexStart+1];
              }
            } else if s > 1 && nAddedOptions > 0 {  // In this case you have to copy all the previous lines and add the options
              const nr = optSnapshot.shape[1];
              for j in 1..nr {
                var currentRow: [1..optDom.dims()(2).high] int = options[j,..];
                currentRow[servo.optionIndexStart..servo.optionIndexEnd] = a;
                optDom = {1..optDom.dims()(1).high+1, optDom.dims()(2)};
                options[optDom.dims()(1).high, ..] = currentRow;
              }
            }
            nAddedOptions += 1;
          } else {
            //writeln("Not a chance, suckah!");
          }
        }
      }

      // Right now, this just constructs the state from the Agent as a pass
      // through.  Soon it will make decisions;
      var state = buildAgentState(agent=agent);

      return (options, state);
    }

    /*
     This is here so ultimately the environment can edit the sensors
     */
    proc buildAgentState(agent: Agent) {
      var state: [1..agent.sensorDimension()] int;
      for sensor in agent.sensors {
          var a:[sensor.stateIndexStart..sensor.stateIndexEnd] int = sensor.v(me=agent);
          state[a.domain] = a;
      }
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
      if this.currentStep >= this.steps then r = true;
      if any {
        //for sensor in agent.policy.sensors {
        for sensor in agent.sensors {
          if sensor.done then return true;
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
    iter run() {
      for agent in this.agents {
        if !agent.finalized then agent.finalize();
      }
      for i in 1..this.epochs {
        //writeln("starting epoch ", i);
        for step in 1..this.steps {
        //writeln("\tstarting step ", step);
          for agent in this.agents{
            //writeln("\t\tagent: ", agent);
            if agent.done then continue;
            agent.currentStep = step;
            // DM presents options
            //writeln("\t\tpresenting options");
            var (options, currentState) = this.presentOptions(agent);
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
          if this.robotStop() {
            break;
          }
        }
        for agent in this.agents {
          writeln("larnin!");
          agent.learn();
          this.reset(agent);
        }
      }
    }
  }
}
