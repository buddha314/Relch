// A file of Data Transfer objects
use Relch, agents;

class DTO {
  var id: int;
  proc init() {};
}

class EpochDTO : DTO {
    var steps: int,
        winner: string;
    proc init(id: int) {
      super.init();
      this.complete();
      this.id = id;
    }
}

class AgentDTO : DTO {
  var name: string,
      x: real,
      y: real;
  proc init(agent: Agent) {
    super.init();
    this.complete();
    this.id = agent.simId;
    this.name = agent.name;
    this.x = agent.position.x;
    this.y = agent.position.y;
  }
}
