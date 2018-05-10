use Relch,
    Charcoal;

class RelchTest : UnitTest {

  const WORLD_WIDTH: int = 800,
        WORLD_HEIGHT: int = 500,
        N_ANGLES: int = 5,
        N_DISTS: int = 7;

  /* We use these again and again for testing */
  var hundredYardTiler = new LinearTiler(nbins=N_DISTS, x1=0, x2=100, overlap=0.1, wrap=true),
      angler = new AngleTiler(nbins=N_ANGLES, overlap=0.05),
      whiteBoyTyler = new LinearTiler(nbins=N_DISTS, x1=0, x2=100, overlap=0.1, wrap=false), // Does not wrap
      dog = new Agent(name="dog", position=new Position(x=25, y=25)),
      cat = new Agent(name="cat", position=new Position(x=50, y=50)),
      aSensor = new AngleSensor(name="s1", tiler=angler),
      dSensor = new DistanceSensor(name="d1", tiler=hundredYardTiler),
      catAngleSensor = new AngleSensor(name="find the cat", tiler=angler),
      catDistanceSensor = new DistanceSensor(name="find the cat", tiler=hundredYardTiler),
      dogAngleSensor = new AngleSensor(name="find the dog", tiler=angler),
      dogDistanceSensor = new DistanceSensor(name="find the dog", tiler=hundredYardTiler),
      boxWorld = new World(width=WORLD_WIDTH, height=WORLD_HEIGHT);

  proc setUp(name: string = "setup") {
    hundredYardTiler = new LinearTiler(nbins=N_DISTS, x1=0, x2=100, overlap=0.1, wrap=true);
    angler = new AngleTiler(nbins=N_ANGLES, overlap=0.05);
    whiteBoyTyler = new LinearTiler(nbins=N_DISTS, x1=0, x2=100, overlap=0.1, wrap=false); // Does not wrap
    dog = new Agent(name="dog", position=new Position(x=25, y=25));
    cat = new Agent(name="cat", position=new Position(x=50, y=50));
    aSensor = new AngleSensor(name="s1", tiler=angler);
    dSensor = new DistanceSensor(name="d1", tiler=hundredYardTiler);
    catAngleSensor = new AngleSensor(name="find the cat", tiler=angler);
    catDistanceSensor = new DistanceSensor(name="find the cat", tiler=hundredYardTiler);
    dogAngleSensor = new AngleSensor(name="find the dog", tiler=angler);
    dogDistanceSensor = new DistanceSensor(name="find the dog", tiler=hundredYardTiler);
    boxWorld = new World(width=WORLD_WIDTH, height=WORLD_HEIGHT);
    return super.setUp(name);
  }

  proc tearDown(ref t: Timer) {
    return super.tearDown(t);
    //ref s = t;
    //t.stop();
    //writeln("s: ", t.elapsed());
  }

  proc init(verbose:bool) {
    super.init(verbose=verbose);
    this.complete();
  }

  proc testRunDefault() {
    var t = this.setUp("RunDefault");
    catAngleSensor.add(angler);
    catAngleSensor.target=cat;
    var sim = new Environment(name="steppin out", epochs=2, steps=3),
        followCatPolicy = new FollowTargetPolicy(sensor=catAngleSensor),
        motionServo = new Servo(tiler=angler);
    sim.world = boxWorld;
    dog.policy = followCatPolicy;
    dog.add(motionServo);
    sim.add(dog);
    sim.run();
    return this.tearDown(t);
  }

  proc testTilers() {
    var t = this.setUp("Tilers");
    var eo:[1..N_DISTS] int = [1,1,0,0,0,0,0];
    var eo2:[1..N_DISTS] int = [1,0,0,0,0,0,0];
    var eo3:[1..N_DISTS] int = [1,0,0,0,0,0,1];
    assertIntArrayEquals(msg="LinearTiler correctly sees overlaps", expected=eo, actual=hundredYardTiler.bin(14.2));
    assertIntArrayEquals(msg="LinearTiler correctly sees non-overlaps", expected=eo2, actual=hundredYardTiler.bin(3.14));
    assertRealApproximates(msg="LinearTiler correcly unbins x", expected=7.14286, actual=hundredYardTiler.unbin(eo));
    assertIntArrayEquals(msg="LinearTiler correctly sees right wrap correctly", expected=eo3, actual=hundredYardTiler.bin(100.05));
    assertIntArrayEquals(msg="LinearTiler correctly sees left wrap correctly", expected=eo3, actual=hundredYardTiler.bin(0.05));
    assertIntArrayEquals(msg="LinearTiler correctly sees left wrap correctly (negative)", expected=eo3, actual=hundredYardTiler.bin(-0.05));

    assertIntArrayEquals(msg="White boys can't wrap", expected=eo2, actual=whiteBoyTyler.bin(-0.05));

    var ao:[1..N_ANGLES] int = [1,0,0,0,1];
    var ao2:[1..N_ANGLES] int = [0,0,1,0,0];
    var ao3:[1..N_ANGLES] int = [0,0,0,0,1];
    assertIntArrayEquals(msg="Angler sees -pi correctly", expected=ao, actual=angler.bin(-pi));
    assertIntArrayEquals(msg="Angler sees origin correctly", expected=ao2, actual=angler.bin(0));
    assertRealApproximates(msg="Angler unbins correctly", expected=2.51327, actual=angler.unbin(ao3));
    return this.tearDown(t);
  }

  proc testSensors() {
    var t = this.setUp("Sensors");
    var sim = new Environment(name="simulation amazing", epochs=10, steps=5);
    sim.world = new World(width=WORLD_WIDTH, height=WORLD_HEIGHT);

    class Seagull : Agent {
      proc init(name:string, position: Position) {
          super.init( name=name,position=position );
          this.complete();
      }
    }
    var mike = new Seagull(name="mike", position=new Position(x=100, y=100));
    var pondo = new Seagull(name="pando", position=new Position(x=110, y=110));
    var kevin = new Seagull(name="kevin", position=new Position(x=100, y=110));
    var gord = new Seagull(name="gord", position=new Position(x=100, y=110));

    sim.add(mike);
    sim.add(pondo);
    sim.add(kevin);
    sim.add(gord);
    var aflocka = new Herd(name="aflocka", position=new Position(), species=Seagull);

    var s1flockangle: [1..N_ANGLES] int = [0, 0, 0, 1, 0],
        s2flockdist:  [1..N_DISTS] int = [1, 0, 0, 0, 0, 0, 0],
        s1gordangle: [1..N_DISTS] int = [0, 0, 0, 1, 0],
        s2gorddist: [1..N_DISTS] int = [1,0,0,0,0,0,0];

    assertIntArrayEquals(msg="Sensor 1 picks up angle to flock"
      , expected=s1flockangle, actual=aSensor.v(mike, aflocka.findCentroid(sim.agents)));
    assertIntArrayEquals(msg="Sensor 1 picks up dist to flock"
      , expected=s2flockdist, actual=dSensor.v(mike, aflocka.findCentroid(sim.agents)));

    var nn = aflocka.findPositionOfNearestMember(dog, sim.agents);
    assertRealEquals("Sensor finds that mike is closest to dog (x)", expected=100.0,actual=nn.x);
    assertRealEquals("Sensor finds that mike is closest to dog (y)", expected=100.0,actual=nn.y);
    var nm = aflocka.findNearestMember(dog, sim.agents);
    assertStringEquals("Sensor finds that mike is closest to dog (agent)", expected="mike",actual=nm.name);
    return this.tearDown(t);
  }

  proc testAgentRelativeMethods() {
    var t = this.setUp("RelativeMethods");
    var d: real = 35.3553;
    assertRealApproximates(msg="Distance from dog to cat is correct"
      , expected=d, actual=dog.distanceFromMe(cat)
      , error=1.0e-3);

    // cat starts at (50, 50)
    assertRealApproximates(msg="Angle to cat is pi/4", expected=pi/4, actual = dog.angleFromMe(cat));
    // 2nd Q (0, 50)
    cat.position.x = 0.0;
    assertRealApproximates(msg="Angle to cat is 3pi/4", expected=3*pi/4, actual = dog.angleFromMe(cat));
    // 3rd Q (0,0)
    cat.position.y = 0;
    assertRealApproximates(msg="Angle to cat is -3pi/4", expected=-3*pi/4, actual = dog.angleFromMe(cat));
    // 4th Q (50, 0)
    cat.position.x = 50;
    assertRealApproximates(msg="Angle to cat is -pi/4", expected=-pi/4, actual = dog.angleFromMe(cat));

    cat.moveAgentAlong(pi/6);
    assertRealApproximates(msg="Cat moved along pi/6 (x)", expected=52.5981, actual=cat.position.x, error=1e-03);
    assertRealApproximates(msg="Cat moved along pi/6 (y)", expected=1.5, actual=cat.position.y);
    return this.tearDown(t);
  }

  proc testBuildSim() {
    var t = this.setUp("BuildSim");
    var sim = new Environment(name="simulation amazing", epochs=10, steps=10);
    sim.world = new World(width=WORLD_WIDTH, height=WORLD_HEIGHT);

    /* Build some sensor arrays */
    var ifs:[1..0] Sensor,
        wfs:[1..0] Sensor;

    sim.add(dog);
    sim.add(cat);

    class Seagull : Agent {
      proc init(name:string, position: Position) {
          super.init( name=name,position=position );
          this.complete();
      }
    }
    var mike = new Seagull(name="mike", position=new Position(x=100, y=100));
    var pondo = new Seagull(name="pando", position=new Position(x=110, y=110));
    var kevin = new Seagull(name="kevin", position=new Position(x=100, y=110));
    var gord = new Seagull(name="gord", position=new Position(x=100, y=110));

    sim.add(mike);
    sim.add(pondo);
    sim.add(kevin);
    sim.add(gord);
    var aflocka = new Herd(name="aflocka", position=new Position(), species=Seagull);
    var centroid = aflocka.findCentroid(sim.agents);
    assertRealEquals("centroid has correct x", expected=102.5, actual=centroid.x);
    assertRealEquals("centroid has correct y", expected=107.5, actual=centroid.y);
    return this.tearDown(t);
  }

  proc testDogChaseCat() {
    var t = this.setUp("DogChaseCat");
    var sim = new Environment(name="simulation amazing", epochs=10, steps=5);
    sim.world = new World(width=WORLD_WIDTH, height=WORLD_HEIGHT);

    catAngleSensor.target = cat;
    catDistanceSensor.target = cat;

    dog.add(catAngleSensor);
    dog.add(catDistanceSensor);

    var motionServo = new Servo(tiler=angler);
    dog.add(motionServo);

    /* Now run it with the policy, probably won't converge */
    /* Get doggy back at the starting line */
    dog.position.x = 25;
    dog.position.y = 25;
    for e in 1..25 {
      var (options, state) = sim.presentOptions(dog);
      var a = dog.choose(options, state);
      writeln(dog.position);

    }
    return this.tearDown(t);
  }

  proc testPolicies() {
    var t = this.setUp("Policies");
    // Reset position for safety of the animals involved
    var p = new Policy();
    var rp = new RandomPolicy();
    catAngleSensor.target = cat;
    var ftp = new FollowTargetPolicy(sensor=catAngleSensor);
    assertIntEquals(msg="Follow Target Policy has correct sensory dims"
      , expected=N_ANGLES, actual=ftp.sensorDimension());
    assertIntEquals(msg="Follow Target Policy sensor has correct state index start"
      , expected=1, actual=ftp.targetSensor.stateIndexStart);
    assertIntEquals(msg="Follow Target Policy sensor has correct state index end"
        , expected=6, actual=ftp.targetSensor.stateIndexEnd);



    var nActions: int = 4,
        nStates :int = 5;
    var qstate: [1..nStates] int = 0,
        qactions: [1..4, 1..N_ANGLES] int = 0;
    qactions[1,1] = 1;
    qactions[2,2] = 1;
    qactions[3,4] = 1;
    qactions[4,5] = 1;

      // Build a matrix so we know the answer
    var Q = Matrix(
        [0.1, 0.2, 0.1, 0.4, 0.5],
        [0.3, 0.1, 0.9, 0.8, 0.1],
        [0.6, 0.5, 0.6, 0.3, 0.1],
        [0.4, 0.7, 0.5, 0.7, 0.4] );
    var qp = new QLearningPolicy(nActions=nActions, nStates=nStates);
    qp.Q = Q;

    qstate[3] = 1;  // Just doing state 3 now.
    assertIntArrayEquals(msg="Standard Policy gives first row of options"
      , expected=[1,0,0,0,0]
      , actual=p.f(me=dog, options=qactions, state=qstate));
    var rc = rp.f(me=dog, options=qactions, state=qstate);
    assertIntEquals(msg="Random Policy returns the correct dimension",expected=N_ANGLES, actual=rc.size);

    var ftpc = ftp.f(me=dog, options=qactions, state=qstate);
    assertIntArrayEquals(msg="Follow Target takes min angle option", expected=[0,0,0,1,0], actual=ftpc);

    var qchoice = qp.f(me=dog, options=qactions, state=qstate);
    assertIntArrayEquals(msg="QLearn Correct choice is taken", expected=[0,1,0,0,0], actual=qchoice);
      return this.tearDown(t);
  }

  proc testServos() {
    var t = this.setUp("Servos");
    var motionServo = new Servo(tiler=angler);
    dog.add(motionServo);
    dog.act([1,0,0,0,0]);
    assertRealApproximates(msg="Dog moved to correct x", expected=22.5729, actual=dog.position.x, error=1e-03);
    assertRealApproximates(msg="Dog moved to correct y", expected=23.2366, actual=dog.position.y, error=1e-03);
    // Now give larger option to check on servo subsetting
    dog.act([1,0,0,0,0,1,1,1]);
    assertRealApproximates(msg="Dog moved to correct x (overloaded option)", expected=20.1459, actual=dog.position.x, error=1e-03);
    assertRealApproximates(msg="Dog moved to correct y (overloaded option)", expected=21.4733, actual=dog.position.y, error=1e-03);
    this.tearDown(t=t);
  }

  proc testPresentOptions() {
    var t = this.setUp("Present Options");

    catAngleSensor.target = cat;
    var motionServo = new Servo(tiler=angler),
        sim = new Environment(name="simulation amazing", epochs=10, steps=5),
        followCatPolicy = new FollowTargetPolicy(sensor=catAngleSensor),
        optAnswer1 = eye(N_ANGLES, int);

    sim.world = new World(width=WORLD_WIDTH, height=WORLD_HEIGHT);


    dog.policy=followCatPolicy;
    dog.add(motionServo);
    var (options, state) = sim.presentOptions(dog);
    assertIntArrayEquals(msg="State is correct from Present Options", expected=[0,0,0,1,0], actual=state);
    dog.add(new Servo(tiler=hundredYardTiler));
    var (options2, state2) = sim.presentOptions(dog);
    assertIntEquals(msg="Options 2 has the correct n rows", expected=35, actual=options2.shape[1]);
    assertIntEquals(msg="Options 2 has the correct n cols", expected=12, actual=options2.shape[2]);
    //writeln("options 2\n", options2);
    this.tearDown(t=t);
  }

  proc run() {
    super.run();
    //testRunDefault();
    //testTilers();
    //testSensors();
    //testServos();
    //testAgentRelativeMethods();
    //testBuildSim();
    //testDogChaseCat();     // just errors
    testPolicies();
    //testPresentOptions();
    return 0;
  }
}

proc main() {
  var t = new RelchTest(verbose=false);
  var ret = t.run();
  t.report();
  return ret;
}
