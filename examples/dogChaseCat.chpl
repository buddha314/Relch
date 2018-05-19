use Relch;
config const WORLD_WIDTH: int,
             WORLD_HEIGHT: int,
             N_ANGLES: int,
             N_DISTS: int,
             N_STEPS: int,
             N_EPOCHS: int,
             DOG_SPEED: real,
             CAT_SPEED: real;

var boxWorld = new World(width=WORLD_WIDTH, height=WORLD_HEIGHT),
    dog = new Agent(name="dog", position=new Position(x=25, y=25), speed=DOG_SPEED),
    cat = new Agent(name="cat", position=new Position(x=150, y=130), speed=CAT_SPEED);


// Add sensors and rewards to agents
var dogSensor = cat.addTarget(dog, boxWorld.defaultAngleSensor, avoid=false);  // Gives the cat the sensor as well
var catSensor = dog.addTarget(cat, boxWorld.defaultAngleSensor);  // Gives the dog the sensor as well
// Reward dog if he gets close to the cat
//dog.add(new ProximityReward(proximity=5, sensor=catSensor));

// Allow them to move
dog.add(boxWorld.defaultMotionServo);  // Moves the dog
cat.add(boxWorld.defaultMotionServo);  // Moves the cat

// Create the simultation
var sim = new Environment(name="steppin out", epochs=N_EPOCHS, steps=N_STEPS);
sim.world = boxWorld;
sim.add(dog);
sim.add(cat);

writeln("""
  Dog starts at (25, 25). The cat is now an agent and is
  positioned at (150,150).  The dog is using a FollowTargetPolicy and
  basically bum rushes the cat, overshoots, and comes back and forth.  The cat
  runs from the dog but is out-paced (speed 1 vs 3)

  Neither agent yet has a learning algorithm in place.  They are both too stupid for words.

  They make me sick they are so stupid. I'm ashamed I invented them...
  """);
for a in sim.run() {
  writeln(a);
}
