use Relch;

config const MAZE_WIDTH: int,
             MAZE_HEIGHT: int,
             STARTING_POSITION: int,
             EXIT_POSITION: int,
             N_STEPS: int,
             N_EPOCHS: int;

var env = new Environment(name="simulating amazing!"),
    maze = new Maze(width=10, height=10, wrap=false),
    theseus = maze.addAgent(name="Theseus", position=new MazePosition(1)),
    csense = maze.getDefaultCellSensor(),
    exitReward = new Reward(value=10, penalty=-1),
    exitState:[1..1, 1..MAZE_WIDTH*MAZE_HEIGHT] int=0;

exitState[1, EXIT_POSITION] = 1;
exitReward = exitReward.buildTargets(targets=exitState);

env.addWorld(maze);

theseus = maze.addAgentSensor(agent=theseus, target=new SecretAgent()
  , sensor=csense, reward=exitReward);

exitReward.finalize();
theseus = maze.addAgentServo(agent=theseus, servo=maze.getDefaultMotionServo()
  ,sensor=csense);
maze.setAgentPolicy(agent=theseus, policy=new RandomPolicy());

for a in env.run(epochs=N_EPOCHS, steps=N_STEPS) {
  writeln(a);
}
