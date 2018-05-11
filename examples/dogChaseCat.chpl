use Relch;
config const WORLD_WIDTH: int,
             WORLD_HEIGHT: int,
             N_ANGLES: int,
             N_DISTS: int,
             N_STEPS: int,
             N_EPOCHS: int;

var hundredYardTiler = new LinearTiler(nbins=N_DISTS, x1=0, x2=100, overlap=0.1, wrap=true),
    angler = new AngleTiler(nbins=N_ANGLES, overlap=0.05),
    whiteBoyTyler = new LinearTiler(nbins=N_DISTS, x1=0, x2=100, overlap=0.1, wrap=false), // Does not wrap
    dog = new Agent(name="dog", position=new Position(x=25, y=25)),
    cat = new Agent(name="cat", position=new Position(x=50, y=50)),
    catAngleSensor = new AngleSensor(name="find the cat", tiler=angler),
    catDistanceSensor = new DistanceSensor(name="find the cat", tiler=hundredYardTiler),
    dogAngleSensor = new AngleSensor(name="find the dog", tiler=angler),
    dogDistanceSensor = new DistanceSensor(name="find the dog", tiler=hundredYardTiler),
    boxWorld = new World(width=WORLD_WIDTH, height=WORLD_HEIGHT),
    sim = new Environment(name="steppin out", epochs=N_EPOCHS, steps=N_STEPS);

catAngleSensor.target = cat;
var followCatPolicy = new FollowTargetPolicy(sensor=catAngleSensor),
    motionServo = new Servo(tiler=angler);

sim.world = boxWorld;
followCatPolicy.add(catDistanceSensor);
dog.policy = followCatPolicy;
dog.add(motionServo);
dog.add(new ProximityReward(proximity=15, sensor=catDistanceSensor));
sim.add(dog);

writeln("""
  Dog starts at (25, 25). The cat is not an agent and is
  positioned at (50,50).  The dog is using a FollowTargetPolicy and
  basically bum rushes the cat, overshoots, and comes back and forth.
  """);
for a in sim.run() {
  writeln(a);
}
