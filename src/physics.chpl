use policies, agents;
  /* I really have no idea how I'm going to handle this yet */
class Servo {
  var tiler: Tiler,
      optionIndexStart: int,
      optionIndexEnd: int;

  proc init() {}
  proc init(tiler: Tiler) {
    this.tiler=tiler;
  }

  proc f(agent: Agent, choice: [] int) {
    const o:[1..this.dim()] int = choice[this.optionIndexStart..this.optionIndexEnd];
    const d: real = this.tiler.unbin(o);
    agent.moveAgentAlong(d);
    return agent;
  }

  proc dim() {
    return this.tiler.nbins;
  }
}

/* Returns a position from the original point along theta */
proc moveAlong(from: Position, theta: real, speed: real) {
  const p = new Position(x=from.x + speed*cos(theta), y=from.y + speed*sin(theta) );
  return p;
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

class Position {
  var x: real,
      y: real;
  proc init(x: real = 0, y: real = 0) {
    this.x = x;
    this.y = y;
  }
}


/*
 Sensor need to be attached to an agent for constructing state.  They aren't
 really useful on their own
 */
class Sensor {
  var name: string,
      stateIndexStart: int,   // which part of the state space does this populate?
      stateIndexEnd: int,
      tiler: Tiler,
      target: Perceivable,
      done: bool;

  proc init(name:string, tiler: Tiler) {
    this.name=name;
    this.stateIndexStart = 0;
    this.stateIndexEnd = 0;
    this.tiler = tiler;
  }

  proc add(tiler: Tiler) {
    this.tiler = tiler;
  }

  proc v(me: Agent, you: Position) {
    var v:[1..this.dim()] int = 0;
    return v;
  }

  proc v(me: Agent, you: Perceivable) {
    return this.v(me=me, you=you.position);
  }

  proc v(me: Agent) {
    return this.v(me=me, you=this.target);
  }

  proc dim() {
    var n: int = 0;
    if this.tiler != nil {
      n += this.tiler.nbins;
    }
    return n;
  }
}

class AngleSensor : Sensor {
  proc init(name:string, tiler:Tiler) {
    super.init(name=name, tiler=tiler);
    this.complete();
  }

  proc v(me: Agent, you: Position) {
    const a = angle(me.position, you);
    const v:[1..this.dim()] int = this.tiler.bin(a);
    return v;
  }
}

class DistanceSensor : Sensor {
  proc init(name:string, tiler:Tiler) {
    super.init(name=name, tiler=tiler);
    this.complete();
  }
  proc v(me:Agent, you: Position) {
    const a = dist(me.position, you);
    const v:[1..this.dim()] int = this.tiler.bin(a);
    //writeln("sensor says distance is ", a, " -> ", v, " -> ", this.tiler.unbin(v));
    return v;
  }
}

class StepSensor : Sensor {
  proc init(name: string, steps: int) {
    super.init(name=name, tiler=new StepTiler(nbins=steps));
    this.complete();
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
  proc unbin(x:[] int) throws {
    this.checkDim(x);
    return 0.0;
  }
  proc checkDim(x:[] int) throws {
    if x.size != this.nbins {
      const err = new DimensionMatchError(expected = this.nbins, actual=x.size);
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


/*
 Provides some basic machinery, including default tilers for sensors
 */
class World {
  const width: int,
        height: int;
  var radius: real,
      wrap: bool,
      defaultLinearTiler: LinearTiler,
      defaultDistanceSensor: DistanceSensor,
      defaultAngleTiler: AngleTiler,
      defaultAngleSensor: AngleSensor;

  proc init(width: int, height: int
      ,wrap: bool = false
      ,defaultDistanceBins: int = 17, defaultDistanceOverlap: real= 0.1
      ,defaultAngleBins: int = 11, defaultAngleOverlap: real = 0.05
    ) {
    this.width = width;
    this.height = height;
    this.radius = sqrt(this.width**2 + this.height**2);
    this.defaultLinearTiler = new LinearTiler(nbins=defaultDistanceBins, x1=0.0
      ,x2=this.radius, overlap=defaultDistanceOverlap, wrap=this.wrap);
    this.defaultDistanceSensor = new DistanceSensor(name="Default Distance Sensor", tiler=this.defaultLinearTiler);
    this.defaultAngleTiler = new AngleTiler(nbins=defaultAngleBins
      ,overlap=defaultAngleOverlap);
    this.defaultAngleSensor = new AngleSensor(name="Default Angle Sensor", tiler=this.defaultAngleTiler);
  }

  proc isValidPosition(position: Position ) {
    if wrap {
      return true;
    } else if position.x >= 0 && position.x < this.width
              && position.y >= 0 && position.y <= this.height {
      return true;
    } else {
      return false;
    }
  }
}
