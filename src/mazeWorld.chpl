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

  /*
  proc addAgentSensor(agent: MazeAgent, target: Agent, sensor: Sensor) {
    writeln(" ** maze add agent sensor");
    if agent.id <1 then this.addAgent(agent);
    if target.id <1 then this.addAgent(target);
    sensor.meId = agent.id;
    sensor.youId = target.id;
    agent.addSensor(sensor=sensor);
    return agent;
  } */


  /*
  proc addAgentSensor(agent: MazeAgent, target: Agent, sensor: Sensor, reward: Reward) {
    writeln("maze world sensor reward");
    if agent.id <1 then this.addAgent(agent);
    if target.id <1 then this.addAgent(target);
    sensor.meId = agent.id;
    sensor.youId = target.id;
    agent.addSensor(sensor=sensor);
    return agent;
  } */


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

  proc canMove(agent: MazeAgent, dir: string) {
    //return this.board.canMove(c);
    return this.canMove(position=agent.position, dir=dir);
  }

  proc canMove(position:MazePosition, dir: string) {
    return this.board.canMove(fromId=position.cellId, dir=dir);
  }

  /*
  Only NEWS motion allowed
   */
  proc getMotionServoOptions(agent:MazeAgent, servo:Servo){
    var optDom: domain(2),
      options: [optDom] int = 0,
      sensor: Sensor,
      currentRow: int = 1; // We will populate the first row for sure

    optDom = {1..currentRow, servo.optionIndexStart..servo.optionIndexEnd};
    // Add a null action (should always be an option)
    sensor = agent.sensors[servo.sensorId];
    options[currentRow,..] = 0;
    // Build a one-hot for each option
    if servo: MazeMotionServo != nil {
      for i in servo.optionIndexStart..servo.optionIndexEnd {
        var dir = this.moves.get(i-servo.optionIndexStart+1);
        if this.canMove(agent=agent, dir=dir) {
          var a:[servo.optionIndexStart..servo.optionIndexEnd] int = 0;
          a[i] = 1;
          currentRow += 1;
          optDom = {1..currentRow, servo.optionIndexStart..servo.optionIndexEnd};
          options[currentRow, ..] = a;
        }
      }
    }
    return options;
  }

  proc presentOptions(agent: MazeAgent) {
    var optDom: domain(2),
        options: [optDom] int;
    for s in 1..agent.servos.size {
      if s > 1 {
        halt("No more than one servo supported at the moment");
      }
      var servo = agent.servos[s];
      if servo: MazeMotionServo != nil {
        var opts = this.getMotionServoOptions(agent=agent, servo=servo:MazeMotionServo);
        optDom = opts.domain;
        options = opts;
      }
    }

    var state = this.buildAgentState(agent=agent);
    return (options, state);
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
