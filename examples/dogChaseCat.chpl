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
//dog = sim.add(dog);
//cat = sim.add(cat);

dog = boxWorld.setAgentTarget(agent=dog, target=cat, sensor=catSensor): BoxWorldAgent;
cat = boxWorld.setAgentTarget(agent=cat, target=dog, sensor=dogSensor, avoid=true): BoxWorldAgent;
dog = boxWorld.addAgentServo(agent=dog, sensor=catSensor, boxWorld.getDefaultMotionServo()): BoxWorldAgent;
cat = boxWorld.addAgentServo(agent=cat, sensor=dogSensor, boxWorld.getDefaultMotionServo()): BoxWorldAgent;
dog = boxWorld.addAgentSensor(agent=dog, target=cat,
  sensor=boxWorld.getDefaultDistanceSensor(), reward=boxWorld.getDefaultProximityReward()): BoxWorldAgent;

writeln("""
  Dog starts at (25, 25). The cat is now an agent and is
  positioned at (110,100).  The dog is using a FollowTargetPolicy and
  basically bum rushes the cat, overshoots, and comes back and forth.  The cat
  runs from the dog but is out-paced (speed 1 vs 3)

  Neither agent yet has a learning algorithm in place.  They are both too stupid for words.

  They make me sick they are so stupid. I'm ashamed I invented them...
  """);
//for a in env.run(epochs=N_EPOCHS, steps=N_STEPS) {
for a in env.run(epochs=2, steps=100) {
  writeln(a);
}
