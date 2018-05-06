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

  class Simulation {
    var name: string,
        epochs: int,
        //dm: DungeonMaster,
        world: World,
        agents: [1..0] Agent,
        perceivables: [1..0] Perceivable;

    proc init(name: string, epochs:int) {
      this.name=name;
      this.epochs=epochs;
      //this.dm = new DungeonMaster();
    }

    proc add(agent: Agent) {
        this.agents.push_back(agent);
    }

    proc add(perceivable: Perceivable) {
      this.perceivables.push_back(perceivable);
    }

    proc presentOptions(agent: Agent) {
      /* Constructing options is kinda hard, right now just 1 for every
         element of the sensors */
      var options = eye(agent.optionDimension(), int);
      var state: [1..agent.sensorDimension()] int;
      var k: int = 1;
      for sensor in agent.sensors {
          //writeln("I am the DM looking at sensor ", sensor.name);
          state[k..sensor.dim()] = sensor.v(me=agent);
          k = sensor.dim() +1;
      }
      return (options, state);
    }

    proc dispenseReward(agent: Agent, choice: [] int) {

    }

    iter run() {
      for i in 1..this.epochs {
        for a in this.agents {
          // DM presents options
          // A chooses an action
          // DM rewards
          // A logs the reward
          // Return A
          yield a;
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
