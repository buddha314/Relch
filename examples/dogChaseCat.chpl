use Relch;
config const WORLD_WIDTH: int,
             WORLD_HEIGHT: int,
             N_ANGLES: int,
             N_DISTS: int,
             N_STEPS: int,
             N_EPOCHS: int,
             DOG_SPEED: int,
             CAT_SPEED: int;

var hundredYardTiler = new LinearTiler(nbins=N_DISTS, x1=0, x2=950, overlap=0.1, wrap=true),
    angler = new AngleTiler(nbins=N_ANGLES, overlap=0.05),
    dog = new Agent(name="dog", position=new Position(x=25, y=25), speed=DOG_SPEED),
    cat = new Agent(name="cat", position=new Position(x=75, y=75), speed=CAT_SPEED),
    catAngleSensor = new AngleSensor(name="find the cat angle", tiler=angler),
    dogAngleSensor = new AngleSensor(name="find the dog angle", tiler=angler),
    catDistanceSensor = new DistanceSensor(name="find the cat distance", tiler=hundredYardTiler),
    dogDistanceSensor = new DistanceSensor(name="find the dog distance", tiler=hundredYardTiler),
    boxWorld = new World(width=WORLD_WIDTH, height=WORLD_HEIGHT),
    sim = new Environment(name="steppin out", epochs=N_EPOCHS, steps=N_STEPS);


catAngleSensor.target = cat;
dogAngleSensor.target = dog;
catDistanceSensor.target = cat;
dogDistanceSensor.target = dog;
var followCatPolicy = new FollowTargetPolicy(sensor=catAngleSensor),
    followDogPolicy = new FollowTargetPolicy(sensor=dogAngleSensor, avoid=true),
    motionServo = new Servo(tiler=angler);

followCatPolicy.add(catDistanceSensor);
followDogPolicy.add(dogDistanceSensor);
dog.policy = followCatPolicy;
cat.policy = followDogPolicy;
dog.add(motionServo);
cat.add(motionServo);
dog.add(new ProximityReward(proximity=5, sensor=catDistanceSensor));
sim.world = boxWorld;
sim.add(dog);
sim.add(cat);

writeln("""
  Dog starts at (25, 25). The cat is now an agent and is
  positioned at (150,150).  The dog is using a FollowTargetPolicy and
  basically bum rushes the cat, overshoots, and comes back and forth.  The cat
  runs from the dog but is out-paced (speed 1 vs 3)

  Neither agent yet has a learning algorithm in place.  They are both too stupid for words.
  """);
for a in sim.run() {
  writeln(a);
}
