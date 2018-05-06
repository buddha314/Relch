use policies, agents;
  /* I really have no idea how I'm going to handle this yet */
  class Servo {
    var tiler: Tiler;
    proc init() {}
    proc init(tiler: Tiler) {
      this.tiler=tiler;
    }

    proc f(agent: Agent, choice: [] int) {
      const d: real = this.tiler.unbin(choice);
      agent.moveAlong(d);
      return agent;
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

  class Position {
    var x: real,
        y: real;
    proc init(x: real = 0, y: real = 0) {
      this.x = x;
      this.y = y;
    }
  }

  class Sensor {
    var name: string,
        size: int, // How long is the return vector
        distanceTiler: Tiler,
        angleTiler: Tiler,
        target: Perceivable;
    proc init(name:string) {
      this.name=name;
    }

    proc init(name:string, size: int) {
      this.name = name;
      this.size = size;
    }

    proc add(tiler: Tiler) {
      if tiler: AngleTiler != nil {
        this.angleTiler = tiler;
      } else if tiler : LinearTiler != nil {
        this.distanceTiler = tiler;
      }
    }

    /* Note Bene: You have to have both tilers or it core dumps! */
    proc v(me: Agent, you: Position) {
      var v:[1..this.dim()] int,
          d: real =  dist(me.position, you),
          a: real =  angle(me.position, you);
      v[1..this.distanceTiler.nbins] = this.distanceTiler.bin(d);
      v[this.distanceTiler.nbins+1..this.dim()] = this.angleTiler.bin(a);
      return v;
    }

    proc v(me: Agent, you: Agent) {
      return this.v(me=me, you=you.position);
    }

    proc v(me: Agent) {
      return this.v(me=me, you=this.target.position);
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