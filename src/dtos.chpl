// A file of Data Transfer objects
use Relch, agents;

class DTO {
  var id: int,
      event: string;
  proc init(id: int) {
    this.id=id;
  };
}

class EpochDTO : DTO {
    var steps: int,
        winner: string;
    proc init(id: int, steps:int, winner:string) {
      super.init(id=id);
      this.complete();
      this.event = "epoch";
      this.steps = steps;
      this.winner = winner;
    }
}


class AgentDTO : DTO {
  var name: string;
  proc init(id: int, name:string) {
    super.init(id=id);
    this.complete();
    this.event="agent";
    this.name=name;
  }
}

class BoxWorldAgentDTO : AgentDTO {
  var x: real,
      y: real;
  proc init(id: int, name:string, x:real, y:real) {
    super.init(id=id, name=name);
    this.complete();
    this.x = x;
    this.y = y;
  }
}

class MazeAgentDTO : AgentDTO {
  var cellId: int;
  proc init(id: int, name:string, cellId: int) {
    super.init(id=id, name=name);
    this.complete();
    this.cellId = cellId;
  }
}
