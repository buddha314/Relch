use Relch;

config const MAZE_WIDTH: int,
             MAZE_HEIGHT: int,
             STARTING_POSITION: int,
             EXIT_POSITION: int,
             EXIT_REWARD: real,
             STEP_PENALTY: real,
             N_STEPS: int,
             N_EPOCHS: int,
             LEARNING_EPSILON: real;

var env = new Environment(name="simulating amazing!"),
    maze = new Maze(width=10, height=10, wrap=false),
    theseus = maze.addAgent(name="Theseus", position=new MazePosition(STARTING_POSITION)),
    csense = maze.getDefaultCellSensor(),
    exitReward = new Reward(value=EXIT_REWARD, penalty=STEP_PENALTY),
    exitState:[1..1, 1..MAZE_WIDTH*MAZE_HEIGHT] int=0;

exitState[1, EXIT_POSITION] = 1;
exitReward = exitReward.buildTargets(targets=exitState);

env.addWorld(maze);

theseus = maze.addAgentSensor(agent=theseus, target=new SecretAgent()
  , sensor=csense, reward=exitReward);

exitReward.finalize();
theseus = maze.addAgentServo(agent=theseus, servo=maze.getDefaultMotionServo()
  ,sensor=csense);
theseus = maze.setAgentPolicy(agent=theseus, policy=new DQPolicy(epsilon=LEARNING_EPSILON, avoid=false)): MazeAgent;

for a in env.run(epochs=N_EPOCHS, steps=N_STEPS) {
  writeln(a);
}
