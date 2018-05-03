/* Documentation for Relch */
module Relch {
  use Math, NumSuch;
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

  // Should be abstracted to something like DQNAgent
  class Agent {
    var name: string,
        position: Position,
        internalSensors: [1..0] Sensor,
        worldSensors: [1..0] Sensor,
        d: domain(2),
        Q: [d] real,
        E: [d] real;

    proc init(name:string
        , internalSensors:[] Sensor
        , worldSensors: [] Sensor
        , position:Position = new Position()) {
      this.name=name;
      this.complete();
      var m: int = 1;  // collects the total size of the feature space
      var n: int = 0;
      for f in internalSensors{
        this.internalSensors.push_back(f);
        n += f.size;
      }
      for f in worldSensors{
        this.worldSensors.push_back(f);
        n += f.size;
      }
      this.d = {1..m, 1..n};
      var X:[d] real;
      fillRandom(X);
      var nm = new NamedMatrix(X=X);
      fillRandom(this.Q);
      fillRandom(this.E);
      this.position=position;
    }

    proc act(rabbits:[] Agent) {
      /*
      for f in this.internalFeatures {
        var v = f.v(this, rabbits);
      } */
      return this;
    }

    /*
     This really need to be abstracted
     */
    proc distanceFromMe(you: Agent) {
      return sqrt((this.position.x - you.position.x)**2 + (this.position.y - you.position.y)**2);
    }

    proc angleFromMe(you: Agent) {
      return atan2((you.position.y - this.position.y) , (you.position.x - this.position.x));
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

    proc presentOptions(agent: Agent) {
      return 0;
    }
  }

  class Sensor {
    var size: int; // How long is the return vector
    proc init(size: int) {
      this.size = size;
    }
    proc v(me: Agent, them:[] Agent) {
      var v:[1..size] int;
      return v;
    }
  }

  class Tiler {
    var nbins: int,
        ndims: int,
        dom: domain(2),
        bins: [dom] real,
        overlap: real,
        wrap: bool;

    proc init(nbins:int, ndims: int, overlap: real, wrap:bool) {
      this.nbins = nbins;
      this.dom = {1..nbins, 1..2*ndims};
      this.overlap = overlap;
      this.wrap = wrap;
    }

    proc makeBins() {}
  }

  class LinearTiler : Tiler {
    proc init(nbins: int, x1: real, x2: real, overlap:real=-1, wrap:bool=false) {
      super.init(nbins=nbins, ndims=1, overlap=overlap, wrap=wrap);
      this.complete();
      this.makeBins(x1: real, x2: real);
    }

    proc makeBins(x1: real, x2: real) {
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

  /*
  I don't want to freak out engineers, but this works in radians and goes the
  positive (counter-clockwise) direction.
   */
  class AngleTiler : LinearTiler {
    proc init(nbins: int, overlap:real=-1, theta0: real =-pi , theta1: real = pi) {
      super.init(nbins=nbins, x1=theta0, x2=theta1, overlap=overlap, wrap=true);
      this.complete();
    }
  }

}
