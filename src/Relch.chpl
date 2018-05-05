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

    proc presentOptions(player: Agent) {

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
  class Agent : Perceivable {
    var speed: real,
        sensors: [1..0] Sensor,
        d: domain(2),
        Q: [d] real,
        E: [d] real,
        compiled : bool = false;

    proc init(name:string
        , position:Position = new Position()
        , speed: real = 3.0 ) {
      super.init(name=name, position=position);
      this.complete();
      this.speed=speed;
    }

    proc add(sensor : Sensor) {
      this.sensors.push_back(sensor);
    }

    proc act(rabbits:[] Agent) {
      return this;
    }

    proc compile() {
      var m: int = 1;  // collects the total size of the feature space
      var n: int = 0;
      for f in this.sensors{
        n += f.size;
      }
      this.d = {1..m, 1..n};
      var X:[d] real;
      fillRandom(X);
      var nm = new NamedMatrix(X=X);
      fillRandom(this.Q);
      fillRandom(this.E);
      this.compiled = true;
    }

    /*
     This really need to be abstracted
     */
    proc distanceFromMe(you: Agent) {
      return dist(this.position, you.position);
    }

    proc angleFromMe(you: Agent) {
      return angle(this.position, you.position);
    }

    /* Move along an angle */
    proc moveAlong(theta: real) {
      this.position.x += this.speed * cos(theta);
      this.position.y += this.speed * sin(theta);
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

  class Sensor {
    var size: int, // How long is the return vector
        distanceTiler: Tiler,
        angleTiler: Tiler,
        target: Perceivable;
    proc init() {}

    proc init(size: int) {
      this.size = size;
    }

    proc add(tiler: Tiler) {
      if tiler: AngleTiler != nil {
        this.angleTiler = tiler;
      } else if tiler : LinearTiler != nil {
        this.distanceTiler = tiler;
      }
    }
    proc v(me: Agent, them: Position) {
      var v:[1..this.dim()] int,
          d: real =  dist(me.position, them),
          a: real =  angle(me.position, them);
      v[1..this.distanceTiler.nbins] = this.distanceTiler.bin(d);
      v[this.distanceTiler.nbins+1..this.dim()] = this.angleTiler.bin(a);
      //return this.distanceTiler.bin(d);
      return v;
    }

    proc v(me: Agent, them: Agent) {
      return this.v(me=me, them=them.position);
    }

    proc dim() {
      var n: int = 0;
      if this.angleTiler != nil {
        n += this.angleTiler.nbins;
      }
      if this.distanceTiler != nil {
        n += this.distanceTiler.nbins;
      }
      return n;
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

    proc bin(x: real) {return [0];}
    proc unbin(x:[] int) {return 0.0;}

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

    /* go from bins back to a value, typically the mid point */
    proc unbin(x:[] int) {
      var r: real;
      for i in x.domain {
        if x[i] == 1 {
          // return the mid point
          r = (this.bins[i,1] + this.bins[i,2]) / 2 ;
          break;
        }
      }
      return r;
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

  class Perceivable {
    var name: string,
        position: Position;
    proc init(name: string, position: Position) {
      this.name = name;
      this.position = position;
    }
  }

  class Herd : Perceivable {
    type species;
    proc init(name: string, position: Position, type species) {
      super.init(name=name, position=new Position());
      this.species = species;
      this.complete();
    }

    proc findCentroid(agents: [] Agent) {
        var x: real = 0.0,
            y: real = 0.0,
            n: int = 0;
        var p = new Position();
        for agent in agents {
          // Make sure we have the correct target agent class
          if agent:this.species != nil {
            x += agent.position.x;
            y += agent.position.y;
            n += 1;
          }
        }
        p.x = x/n;
        p.y = y/n;
        return p;
    }

    proc findPositionOfNearestMember(me: Agent, agents: [] Agent) {
      var p = new Position(),
          d: real = -1;
      for agent in agents {
        if agent:this.species != nil {
          const dd = dist(me, agent);
          if dd < d || d < 0 {
            p.x = agent.position.x;
            p.y = agent.position.y;
            d = dd;
          }
        }
      }
      return p;
    }

    proc findNearestMember(me: Agent, agents: [] Agent) {
      var a: Agent,
          d: real = -1;
      for agent in agents {
        if agent:this.species != nil {
          const dd = dist(me, agent);
          if dd < d || d < 0 {
            a = agent;
            d = dd;
          }
        }
      }
      return a;
    }
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

  proc angle(origin: Position, target: Position) {
    return atan2((target.y - origin.y) , (target.x - origin.x));
  }
}
