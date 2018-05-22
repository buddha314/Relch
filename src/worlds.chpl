use physics;
/*
 Provides some basic machinery, including default tilers for sensors
 */
class World {
  var radius: real,
      wrap: bool,
      defaultLinearTiler: LinearTiler,
      defaultAngleTiler: AngleTiler;

  proc init(wrap: bool = false
      ,defaultDistanceBins: int = 17, defaultDistanceOverlap: real= 0.1
      ,defaultAngleBins: int = 11, defaultAngleOverlap: real = 0.05
    ) {
    this.defaultLinearTiler = new LinearTiler(nbins=defaultDistanceBins, x1=0.0
      ,x2=this.radius, overlap=defaultDistanceOverlap, wrap=this.wrap);
    this.defaultAngleTiler = new AngleTiler(nbins=defaultAngleBins
      ,overlap=defaultAngleOverlap);
    //this.defaultMotionServo = new Servo(tiler=this.defaultAngleTiler);
  }

  proc randomPosition2D() {
    const x = rand(1, this.width),
          y = rand(1, this.height);
    return new Position(x = x, y=y);
  }

  proc randomPosition() {
    return this.randomPosition();
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

  proc getDefaultAngleSensor() {
    return new AngleSensor(name="Default Angle Sensor", tiler=this.defaultAngleTiler);
  }

  /*
   Uses the default linear tiler over the radius of the world
   */
  proc getDefaultDistanceSensor() {
    return new DistanceSensor(name="Default Distance Sensor", tiler=this.defaultLinearTiler);
  }

  proc getDefaultMotionServo() {
    return new Servo(tiler=this.defaultAngleTiler);
  }

  /*
   Default is to be within 1 tile of the target
   */
  proc getDefaultProximityReward() {
    //return new ProximityReward(proximity=3);
    return new ProximityReward(proximity=1);
  }
}

class BoxWorld : World {
  const width: int,
        height: int,
        dimension: int,
        radius: real;
  proc init(width:int, height: int, dimension:int = 2) {
      super.init();
      this.width=width;
      this.height=height;
      this.radius = sqrt(this.width**2 + this.height**2);
      this.complete();
  }
}
