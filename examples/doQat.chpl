use Relch;
config const WORLD_WIDTH: int,
             WORLD_HEIGHT: int,
             N_ANGLES: int,
             N_DISTS: int,
             N_STEPS: int,
             N_EPOCHS: int,
             DOG_SPEED: real,
             CAT_SPEED: real;

var env = new Environment(name="simulatin' amazing!"),
    boxWorld = new BoxWorld(width=WORLD_WIDTH, height=WORLD_HEIGHT, wrap=false),
    dog = boxWorld.addAgent(name="dog", position=new Position2D(x=25, y=25), speed=DOG_SPEED): BoxWorldAgent,
    cat = boxWorld.addAgent(name="cat", position=new Position2D(x=150, y=150), speed=CAT_SPEED): BoxWorldAgent,
    catSensor = boxWorld.getDefaultAngleSensor(),
    dogSensor = boxWorld.getDefaultAngleSensor();

// Create the simulation
env.world = boxWorld;

//dog = boxWorld.setAgentTarget(agent=dog, target=cat, sensor=catSensor): BoxWorldAgent;
dog = boxWorld.setAgentPolicy(agent=dog, policy=new DQPolicy(epsilon=0.01, avoid=false)): BoxWorldAgent;
cat = boxWorld.setAgentTarget(agent=cat, target=dog, sensor=dogSensor, avoid=true): BoxWorldAgent;
dog = boxWorld.addAgentServo(agent=dog, sensor=catSensor, boxWorld.getDefaultMotionServo()): BoxWorldAgent;
cat = boxWorld.addAgentServo(agent=cat, sensor=dogSensor, boxWorld.getDefaultMotionServo()): BoxWorldAgent;
dog = boxWorld.addAgentSensor(agent=dog, target=cat,
 sensor=boxWorld.getDefaultDistanceSensor(), reward=boxWorld.getDefaultProximityReward()): BoxWorldAgent;




 /*
var sim = new Environment(name="simulatin' amazing!"),
   boxWorld = new World(width=WORLD_WIDTH, height=WORLD_HEIGHT, wrap=false),
   dog = new Agent(name="dog", position=new Position(x=25, y=25), speed=DOG_SPEED),
   //cat = new Agent(name="cat", position=new Position(x=150, y=130), speed=CAT_SPEED);
   cat = new Agent(name="cat", position=new Position(x=100, y=100), speed=CAT_SPEED);

 // Create the simulation
sim.world = boxWorld;
dog = sim.add(dog);
cat = sim.add(cat);
//dog = sim.setAgentTarget(agent=dog, target=cat, sensor=boxWorld.getDefaultAngleSensor());
dog = sim.setAgentPolicy(agent=dog, policy=new DQPolicy(avoid=false));
cat = sim.setAgentTarget(agent=cat, target=dog, sensor=boxWorld.getDefaultAngleSensor(), avoid=true);
dog = sim.addAgentServo(dog, boxWorld.getDefaultMotionServo());
cat = sim.addAgentServo(cat, boxWorld.getDefaultMotionServo());
dog = sim.addAgentSensor(agent=dog, target=cat,
  sensor=boxWorld.getDefaultDistanceSensor(), reward=boxWorld.getDefaultProximityReward());
*/


writeln("""
 Dog starts at (25, 25). The cat is an agent and is
 positioned at (150,150).  The dog is using a DQPolicy to find the cat, let's
 see how it goes
""");
for a in env.run(epochs=N_EPOCHS, steps=N_STEPS) {
//for a in sim.run(epochs=1, steps=3) {
   writeln(a);
}
