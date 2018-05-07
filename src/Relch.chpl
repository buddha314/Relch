/* Documentation for Relch */
module Relch {
  use Math, NumSuch;
  use agents, policies, physics;

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
        //dm: DungeonMaster,
        world: World,
        agents: [1..0] Agent,
        perceivables: [1..0] Perceivable;

    proc init(name: string, epochs:int, steps: int) {
      this.name=name;
      this.epochs=epochs;
      this.steps=steps;
      this.currentStep = 1;
      //this.dm = new DungeonMaster();
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
        var state: [1..1] int = [1];
        var reward = this.dispenseReward(agent=agent, choice=action);
        var done: bool = this.areYouThroughYet();  // Yes, this is a Steve Martin reference
        var position: Position = new Position();
        agent.currentStep += 1;
        return (state, reward, done, position);
    }

    proc reset(agent: Agent) {
      agent.currentStep = 1;
      agent.done = false;
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
      //var options = eye(agent.optionDimension(), int);
      var options = eye(4, int);
      //var state: [1..agent.sensorDimension()] int;
      var state: [1..4] int;
      var k: int = 1;
      for sensor in agent.sensors {
          //writeln("I am the DM looking at sensor ", sensor.name);
          state[k..sensor.dim()] = sensor.v(me=agent);
          k = sensor.dim() +1;
      }
      return (options, state);
    }

    proc dispenseReward(agent: Agent, choice: [] int) {
      return 10.0;
    }

    proc areYouThroughYet() {
      var r: bool = false;
      if this.currentStep >= this.steps then r = true;
      return r;
    }


    iter run() {
      var pp = new RandomPolicy();
      for i in 1..this.epochs {
        for agent in this.agents{
          this.reset(agent=agent);
          for step in 1..this.steps {
            // DM presents options
            var (options, currentState) = this.presentOptions(agent);
            // A chooses an action
            var choice = agent.choose(options, currentState);
            // DM rewards
            var (nextState, reward, done, position) = this.step(agent=agent, action=choice);
            /*
            if done {
              agent.done = true;
              this.reset(agent);
              break;
            }
            // A logs the reward
            // Return A
            */
            yield agent;
          }
        }
      }
    }
  }

  class World {
    const width: int,
          height: int;
    proc init(width: int, height: int) {
      this.width = width;
      this.height = height;
    }
  }

}
