use Relch;
config const WORLD_WIDTH: int,
             WORLD_HEIGHT: int,
             N_ANGLES: int,
             N_DISTS: int,
             N_STEPS: int,
             N_EPOCHS: int,
             DOG_SPEED: int,
             CAT_SPEED: int;

writeln("here -2?");
var hundredYardTiler = new LinearTiler(nbins=N_DISTS, x1=0, x2=950, overlap=0.1, wrap=true),
    angler = new AngleTiler(nbins=N_ANGLES, overlap=0.05),
    cat = new Agent(name="cat", position=new Position(x=75, y=75), speed=CAT_SPEED),
    dogAngleSensor = new AngleSensor(name="find the dog angle", tiler=angler),
    dogDistanceSensor = new DistanceSensor(name="find the dog distance", tiler=hundredYardTiler),
    boxWorld = new World(width=WORLD_WIDTH, height=WORLD_HEIGHT),
    sim = new Environment(name="steppin out", epochs=N_EPOCHS, steps=N_STEPS);

// Dog
var dog = new Agent(name="dog", position=new Position(x=25, y=25), speed=DOG_SPEED),
// Dog sensors
var catAngleSensor = new AngleSensor(name="find the cat angle", tiler=angler),
    catDistanceSensor = new DistanceSensor(name="find the cat distance", tiler=hundredYardTiler);
dog.add(catAngleSensor);
dog.add(catDistanceSensor);
// Dog Servos


writeln("here -1?");

catAngleSensor.target = cat;
dogAngleSensor.target = dog;
catDistanceSensor.target = cat;
dogDistanceSensor.target = dog;

var followDogPolicy = new FollowTargetPolicy(sensor=dogAngleSensor, avoid=true),
    motionServo = new Servo(tiler=angler);

// All Dog sensor


// Add dog Servos
dog.add(motionServo);

// All Dog policy stuff, in order
var followCatPolicy = new DQPolicy(sensor=catAngleSensor),
followCatPolicy.add(catDistanceSensor);



followDogPolicy.add(dogDistanceSensor);
writeln("here 2?");
dog.setPolicy(followCatPolicy);
cat.setPolicy(followDogPolicy);
writeln("here 3?");
cat.add(motionServo);
dog.add(new ProximityReward(proximity=5, sensor=catDistanceSensor));
sim.world = boxWorld;

var nn = new FCNetwork([dog.optionDimension() + dog.sensorDimension(), 1], ["linear"]);
//var nn = new FCNetwork([7, 1], ["linear"]);
followCatPolicy.add(nn);



writeln("here 4?");
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
