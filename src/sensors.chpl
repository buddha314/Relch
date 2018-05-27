use agents;
/*
 A Sensor it attached to a source, target and does its own tiling
 */
class Sensor {
  var nbins: int,
      dom: domain(2),
      bins: [dom] real,
      overlap: real,
      wrap: bool,
      meId: int,
      youId: int,
      stateIndexStart: int,
      stateIndexEnd: int,
      id: int;  // internal id
  proc init(nbins: int, overlap:real, wrap:bool) {
    this.nbins = nbins;
    this.dom = {1..nbins, 1..2};
    this.meId = -1;
    this.youId = -1;
    this.id = -1;
  }

  proc v(me:Agent, you:Agent) {
    var state:[1..0] int;
    return state;
  }

  proc unbin(x:[] int) {
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

  proc makeBins(x1: real, x2: real){
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

  proc dim() {
    return this.nbins;
  }
  proc checkDim(x:[] int) throws {
    if x.size != this.nbins {
      const err = new DimensionMatchError(msg="checking dimensions on sensor", expected = this.nbins, actual=x.size);
      throw err;
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

class LinearSensor: Sensor {
  proc init(nbins: int, x1: real, x2: real, overlap:real=-1, wrap:bool=false) {
    super.init(nbins=nbins, overlap=overlap, wrap=wrap);
    this.complete();
    this.makeBins(x1=x1, x2=x2);
  }

  proc makeBins(x1: real, x2: real){
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

  //proc v(me:Agent, you:Agent) {
  proc v(me, you) {
    var m = me: BoxWorldAgent,
        y = you: BoxWorldAgent;
    var d = sqrt((m.position.x-y.position.x)**2 + (m.position.y-y.position.y)**2);
    return this.bin(d);
  }
}

class AngleSensor2D: Sensor {
  proc init(nbins: int, overlap:real, theta0=-pi, theta1=pi, wrap:bool=true) {
    super.init(nbins=nbins, overlap:real, wrap: bool);
    this.complete();
    this.makeBins(x1=theta0, x2=theta1);
  }

  //proc v(me: Agent, you: Agent) {
  proc v(me, you) {
    var m = me:BoxWorldAgent,
        y = you:BoxWorldAgent;
    const a = angle2D(m.position, y.position);
    var v:[1..this.dim()] int = this.bin(a);
    return v;
  }

}

proc angle2D(x:Position2D, y: Position2D) {
  return atan2((y.y - x.y) , (y.x - x.x));
}
