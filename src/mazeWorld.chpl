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

  //proc addAgentSensor(agent: MazeAgent, target: MazeAgent, sensor: Sensor) {
  proc addAgentSensor(agent: MazeAgent, sensor: Sensor) {
    if agent.id <1 then this.addAgent(agent);
    //if target.id <1 then this.addAgent(target);
    sensor.meId = agent.id;
    //sensor.youId = target.id;
    agent.addSensor(sensor=sensor);
    return agent;
  }

  proc addAgentServo(agent: MazeAgent, servo: Servo, sensor: Sensor) {
    if agent.id < 1 then this.addAgent(agent);
    // Sensor has not been assigned, need to add it, then get last sensor added
    if sensor.meId < 1 then agent.addSensor(sensor);
    servo.sensorId = sensor.id;
    servo.optionIndexStart = agent.optionDimension() + 1;
    servo.optionIndexEnd = servo.optionIndexStart + sensor.dim() -1;
    agent.addServo(servo);
    return agent;
  }

  proc getDefaultMotionServo() {
    var s = new MazeMotionServo(moves=this.moves, width=this.width, height=this.height);
    return s;
  }

  proc getDefaultCellSensor() {
    var s = new CellSensor(nbins=this.width*this.height, wrap=this.wrap);
    return s;
  }


  /*
  Only NEWS motion allowed
   */
  proc getMotionServoOptions(agent:Agent, servo:Servo){
    var optDom: domain(2),
      options: [optDom] int = 0,
      sensor: Sensor,
      currentRow: int = 1; // We will populate the first row for sure

    optDom = {1..currentRow, servo.optionIndexStart..servo.optionIndexEnd};
    // Add a null action (should always be an option)
    sensor = agent.sensors[servo.sensorId];
    options[currentRow,..] = 0;
    // Build a one-hot for each option
    for i in servo.optionIndexStart..servo.optionIndexEnd {
      var a:[servo.optionIndexStart..servo.optionIndexEnd] int = 0;
      a[i] = 1;
      var p = this.moveAlong(from=agent.position, theta=sensor.unbin(a), speed=agent.speed);
      if this.isValidPosition(p) {
        currentRow += 1;
        optDom = {1..currentRow, servo.optionIndexStart..servo.optionIndexEnd};
        options[currentRow, ..] = a;
      }
    }
    return options;
  }
}

class MazePosition: Position {
  var cellId: int;
  proc init(cellId: int) {
    this.cellId = cellId;
  }
}

class MazeAgent: Agent {
  var position: MazePosition;
  proc init(name: string, position:MazePosition=new MazePosition("A1")
    , maxMemories:int=10000) {
    super.init(name=name, maxMemories=maxMemories);
    this.complete();
    this.position=position;
  }
}

// Senses the cell in a maze
class CellSensor: Sensor {
  proc init(nbins: int, wrap:bool=false) {
    super.init(nbins=nbins, overlap=0, wrap=wrap);
    this.complete();
  }

  proc v(agent: MazeAgent) {
    var state:[this.stateIndexStart..this.stateIndexEnd] int = 0;
    state[agent.position.id] = 1;
    return state;
  }
}

class MazeMotionServo: Servo {
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

  proc f(agent: MazeAgent, choice:[] int) {
    const o:[1..this.dim()] int = choice[this.optionIndexStart..this.optionIndexEnd];
    //var sensor = agent.sensors[this.sensorId];
    //const d: real = sensor.unbin(o);
    for i in choice.domain {
      if choice[i] == 1 {
        if moves.get(i) == "N" {
          agent.position.cellId -= this.width;
          break;
        } else if moves.get(i) == "S" {
          agent.position.cellId += this.width;
          break;
        } else if moves.get(i) == "E" {
          agent.position.cellId += 1;
          break;
        } else if moves.get(i) == "W" {
          agent.position.cellId -= 1;
          break;
        }
      }
    }
    return agent;
  }
}
