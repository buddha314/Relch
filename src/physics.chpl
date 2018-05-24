use policies, agents;
  /* I really have no idea how I'm going to handle this yet */

class MotionServo : Servo {
  proc init() {
    super.init();
    this.complete();
  }
  proc f(agent: Agent, choice: [] int) {
    const o:[1..this.dim()] int = choice[this.optionIndexStart..this.optionIndexEnd];
    var sensor = agent.sensors[this.sensorId];
    const d: real = sensor.unbin(o);
    agent.moveAgentAlong(d);
    return agent;
  }
}

/*
 Used to collect items like in Gem Hunter (coming soon!)
 */
class CollectingServo: Servo {
  proc init() {
    super.init();
    this.complete();
  }


}

class Servo {
  var sensorId: int,
      optionIndexStart: int,
      optionIndexEnd: int;

  proc init() {}

  proc f(agent: Agent, choice: [] int) {
    return agent;
  }

  proc dim() {
    return this.optionIndexEnd-this.optionIndexStart+1;
  }
}

//class Position2D: Position {
class Position2D{
  var x: real,
      y: real;
  proc init(x: real = 0, y: real = 0) {
    super.init();
    this.complete();
    this.x = x;
    this.y = y;
  }
}

class Position {
  proc init() {}
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
  proc unbin(x:[] int) throws {
    this.checkDim(x);
    return 0.0;
  }
  proc checkDim(x:[] int) throws {
    if x.size != this.nbins {
      const err = new DimensionMatchError(msg="checking dimensions on Tiler", expected = this.nbins, actual=x.size);
      throw err;
    }
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

  /* go from bins back to a value, typically the mid point */
  proc unbin(x:[] int) throws {
    // x has a sub-domain of state, so need to normalize
    var y: [1..x.size] int = x;
    this.checkDim(x);
    var r: real = 0.0;
    for i in y.domain {
      if y[i] == 1 {
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

// Designed to hold the number of steps an agent has taken
class StepTiler : Tiler {
  proc init(nbins: int) {
    super.init(nbins=nbins, ndims=1, overlap=0, wrap=false);
    this.complete();
  }

  // Doesn't need to do anything
  proc makeBins() {}
  proc v(me: Agent) {
    var u: [1..this.nbins] int = 0;
    u[me.currentStep] = 1;
    return u;
  }
}
