/* Documentation for Relch */
module Relch {
  use NumSuch;
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
        dm: DungeonMaster,
        world: World,
        agents: [1..0] Agent;

    proc init(name: string, epochs:int) {
      this.name=name;
      this.epochs=epochs;
      this.dm = new DungeonMaster();
    }

    proc add(agent: Agent) {
        this.agents.push_back(agent);
    }

    iter run() {
      for i in 1..this.epochs {
        for a in this.agents {
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

  // Should be abstracted to something like DQNAgent
  class Agent {
    var name: string,
        position: Position,
        internalFeatures: [1..0] Feature,
        worldFeatures: [1..0] Feature,
        d: domain(2),
        Q: [d] real,
        E: [d] real;

    proc init(name:string
        , internalFeatures:[] Feature
        , worldFeatures: [] Feature
        , position:Position = new Position()) {
      this.name=name;
      this.complete();
      var m: int = 1;  // collects the total size of the feature space
      var n: int = 0;
      /*
      for f in internalFeatures {
        this.internalFeatures.push_back(f);
        n += f.size;
      }
      for f in worldFeatures {
        this.worldFeatures.push_back(f);
        n += f.size;
      }*/
      this.d = {1..m, 1..n};
      //fillRandom(this.Q);
      //fillRandom(this.E);
      this.position=position;
    }

    proc act(rabbits:[] Agent) {
      /*
      for f in this.internalFeatures {
        var v = f.v(this, rabbits);
      } */
      return this;
    }

    proc readWriteThis(f) throws {
      f <~> "%25s".format(this.name) <~> " "
        <~> "%4r".format(this.position.x) <~> " "
        <~> "%4r".format(this.position.y);
    }
  }

  class Position {
    var x: real,
        y: real;
    proc init(x: real = 0, y: real = 0) {
      this.x = x;
      this.y = y;
    }
  }

  class DungeonMaster {
    proc init() {}

    proc evaluateAction(agent: Agent) {
      return 0;
    }
  }

  class Feature {
    var size: int; // How long is the return vector
    proc init(size: int) {
      this.size = size;
    }
    proc v(me: Agent, them:[] Agent) {
      var v:[1..size] int;
      return v;
    }
  }

}
