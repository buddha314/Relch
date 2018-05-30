use policies, agents;

class MotionServo : Servo {
  proc init() {
    super.init();
    this.complete();
  }
  proc f(agent: Agent, choice: [] int) {
    if agent: BoxWorldAgent == nil then halt("Not an agent with a position");
    var a = agent: BoxWorldAgent;
    const o:[1..this.dim()] int = choice[this.optionIndexStart..this.optionIndexEnd];
    var sensor = a.sensors[this.sensorId];
    const d: real = sensor.unbin(o);
    var p = new Position2D(
       x=a.position.x + a.speed * cos(d)
      ,y=a.position.y + a.speed * sin(d) );
    a.position = p;
    return true;
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
    writeln(" ** DEFAULT SERVO.f");
    //return agent;
    return true;
  }

  proc dim() {
    return this.optionIndexEnd-this.optionIndexStart+1;
  }
}

class Position {
  proc init() {}
}

class Position2D: Position {
  var x: real,
      y: real;
  proc init(x: real = 0, y: real = 0) {
    super.init();
    this.complete();
    this.x = x;
    this.y = y;
  }
}
