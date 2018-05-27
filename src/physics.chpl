use policies, agents;
  /* I really have no idea how I'm going to handle this yet */

class MotionServo : Servo {
  proc init() {
    super.init();
    this.complete();
  }
  proc f(agent: BoxWorldAgent, choice: [] int) {
    if agent: BoxWorldAgent == nil then halt("Not an agent with a position");
    const o:[1..this.dim()] int = choice[this.optionIndexStart..this.optionIndexEnd];
    var sensor = agent.sensors[this.sensorId];
    const d: real = sensor.unbin(o);
    var p = new Position2D(
       x=agent.position.x + agent.speed * cos(d)
      ,y=agent.position.y + agent.speed * sin(d) );
    agent.position = p;
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

  proc f(agent, choice: [] int) {
    return agent;
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
