use Chingon;
use worlds, agents;

class Maze: World {
  var wrap: bool,
      width: int,
      height: int,
      moves: BiMap,
      board: GameBoard;
  proc init(width: int, height: int, wrap: bool) {
    super.init();
    this.complete();
    this.wrap=wrap;
    this.width=width;
    this.height=height;
    this.board = new GameBoard(w=width, h=height, wrap=wrap);
    this.moves=new BiMap();
    moves.add("N",1);
    moves.add("E",2);
    moves.add("W",3);
    moves.add("S",4);
  }

  proc addAgent(name: string, position: MazePosition, speed: real = 1.0) {
    var agent = new MazeAgent(name=name, position=position);
    agent.id = this.agents.size+1;
    this.agents.push_back(agent);
    return agent;
  }

  proc addAgentServo(agent: MazeAgent, servo: Servo, sensor: Sensor) {
    if agent.id < 1 then this.addAgent(agent);
    // Sensor has not been assigned, need to add it, then get last sensor added
    if sensor.meId < 1 then agent.addSensor(sensor);
    servo.sensorId = sensor.id;
    servo.optionIndexStart = agent.optionDimension() + 1;
    if servo: MazeMotionServo != nil {
      servo.optionIndexEnd = servo.optionIndexStart + this.moves.size() -1;
    } else {
      servo.optionIndexEnd = servo.optionIndexStart + sensor.dim() -1;
    }
    agent.addServo(servo);
    return agent;
  }

  proc getDefaultMotionServo() {
    var s = new MazeMotionServo(moves=this.moves, width=this.width, height=this.height);
    return s;
  }

  proc getDefaultCellSensor() {
    var s = new CellSensor(nbins=this.width*this.height, moves=this.moves, wrap=this.wrap);
    return s;
  }


  proc canMove(agent: Agent, sensor:Sensor, choice:[] int) {
    var ma = agent:MazeAgent;
    var dir = this.moves.get(argmax(choice) - choice.domain.low +1);
    return this.board.canMove(fromId=ma.position.cellId, dir=dir);
  }

}

class MazePosition: Position {
  var cellId: int;
  proc init(cellId: int) {
    this.cellId = cellId;
  }
}

class MazeAgent: Agent {
  var position: MazePosition,
      initialPosition: int;
  proc init(name: string, position:MazePosition
    , maxMemories:int=10000) {
    super.init(name=name, maxMemories=maxMemories);
    this.complete();
    this.position=position;
    this.initialPosition = position.cellId;
  }

  proc DTO() {
    return new MazeAgentDTO(id=this.id, name=this.name, cellId=this.position.cellId);
  }

  proc reset() {
    this.position.cellId = initialPosition;
    super.reset();
  }
}

// Senses the cell in a maze
class CellSensor: Sensor {
  var moves: BiMap;
  proc init(nbins: int, moves:BiMap, wrap:bool=false) {
    super.init(nbins=nbins, overlap=0, wrap=wrap);
    this.complete();
    this.moves=moves;
  }

  proc v(me: Agent, you: Agent) {
    var me2: MazeAgent = me:MazeAgent;
    var state:[this.stateIndexStart..this.stateIndexEnd] int = 0;
    state[me2.position.cellId] = 1;
    return state;
  }

  proc unbin(x:[] int) {
    var y: real;
    for i in 1..x.size {
      if x[i] == 1 then y = i:real;
    }
    return y;
  }
}

class MazeMotionServo: MotionServo {
  var moves: BiMap,
      width: int,
      height: int;
  proc init(moves:BiMap, width:int, height:int) {
    super.init();
    this.complete();
    this.moves = moves;
    this.width=width;
    this.height=height;
  }

  proc f(agent: Agent, choice:[] int) {
    const o:[1..this.dim()] int = choice[this.optionIndexStart..this.optionIndexEnd];
    var a = agent: MazeAgent;
    if a == nil then halt("Maze Agents only in this Servo");
    for i in choice.domain {
      if choice[i] == 1 {
        if moves.get(i) == "N" {
          a.position.cellId -= this.width;
          break;
        } else if moves.get(i) == "S" {
          a.position.cellId += this.width;
          break;
        } else if moves.get(i) == "E" {
          a.position.cellId += 1;
          break;
        } else if moves.get(i) == "W" {
          a.position.cellId -= 1;
          break;
        }
      }
    }
    return true;
  }
}
