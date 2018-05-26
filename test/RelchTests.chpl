use Relch,
    NumSuch,
    Charcoal;

class RelchTest : UnitTest {

  const WORLD_WIDTH: int = 800,
        WORLD_HEIGHT: int = 500,
        N_ANGLES: int = 5,
        N_DISTS: int = 7,
        N_EPOCHS: int = 3,
        N_STEPS: int = 5;

  /* We use these again and again for testing */
  var sim = new Environment(name="simulating amazing!"),
      world = new BoxWorld(width=WORLD_WIDTH, height=WORLD_HEIGHT),
      dog: BoxWorldAgent,
      cat: BoxWorldAgent,
      maze = new Maze(width=10, height=10, wrap=true);

  /*
  var hundredYardTiler = new LinearTiler(nbins=N_DISTS, x1=0, x2=100, overlap=0.1, wrap=true),
      angler = new AngleTiler(nbins=N_ANGLES, overlap=0.05),
      sim = new Environment(name="simulating awesome!"),
      boxWorld = new BoxWorld(width=WORLD_WIDTH, height=WORLD_HEIGHT),
      drizella = new StepTiler(nbins=N_STEPS),
      whiteBoyTyler = new LinearTiler(nbins=N_DISTS, x1=0, x2=100, overlap=0.1, wrap=false), // Does not wrap
      aSensor = new AngleSensor(name="s1", tiler=angler),
      dSensor = new DistanceSensor(name="d1", tiler=hundredYardTiler),
      catAngleSensor = new AngleSensor(name="find the cat", tiler=angler),
      catDistanceSensor = new DistanceSensor(name="find the cat", tiler=hundredYardTiler),
      dogAngleSensor = new AngleSensor(name="find the dog", tiler=angler),
      dogDistanceSensor = new DistanceSensor(name="find the dog", tiler=hundredYardTiler),
      fitBit = new StepSensor(name="fit bit", steps=N_STEPS),
      motionServo = new Servo(tiler=angler),
      dory = new Agent(name="Dory", position=new Position2D(x=17, y=23), maxMemories = 3);
  */

  proc setUp(name: string = "setup") {
    /*
    hundredYardTiler = new LinearTiler(nbins=N_DISTS, x1=0, x2=100, overlap=0.1, wrap=true);
    angler = new AngleTiler(nbins=N_ANGLES, overlap=0.05);
    drizella = new StepTiler(nbins=N_STEPS);
    whiteBoyTyler = new LinearTiler(nbins=N_DISTS, x1=0, x2=100, overlap=0.1, wrap=false); // Does not wrap
    dog = new Agent(name="dog", position=new Position2D(x=25, y=25));
    cat = new Agent(name="cat", position=new Position2D(x=50, y=50));
    aSensor = new AngleSensor(name="s1", tiler=angler);
    dSensor = new DistanceSensor(name="d1", tiler=hundredYardTiler);
    catAngleSensor = new AngleSensor(name="find the cat", tiler=angler);
    catDistanceSensor = new DistanceSensor(name="find the cat", tiler=hundredYardTiler);
    dogAngleSensor = new AngleSensor(name="find the dog", tiler=angler);
    dogDistanceSensor = new DistanceSensor(name="find the dog", tiler=hundredYardTiler);
    fitBit = new StepSensor(name="fit bit", steps=N_STEPS);
    sim = new Environment(name="simulating awesome!");
    boxWorld = new BoxWorld(width=WORLD_WIDTH, height=WORLD_HEIGHT);
    motionServo = new Servo(tiler=angler);
    dory = new Agent(name="Dory", position=new Position2D(x=17, y=23), maxMemories = 3);
    */

    sim = new Environment(name="simulating amazing!");
    world = new BoxWorld(width=WORLD_WIDTH, height=WORLD_HEIGHT, wrap=false);
    dog = world.addAgent(name="dog", position=new Position2D(x=25, y=25));
    cat = world.addAgent(name="cat", position=new Position2D(x=150, y=150));
    world.addAgentSensor(agent=dog, target=cat, sensor=world.getDefaultDistanceSensor());
    maze = new Maze(width=10, height=10, wrap=true);
    return super.setUp(name);
  }

  proc tearDown(ref t: Timer) {
    return super.tearDown(t);
  }

  proc init(verbose:bool) {
    super.init(verbose=verbose);
    this.complete();
  }

  proc testWorldProperties() {
    var t= this.setUp("World Properties");
    assertBoolEquals(msg="Point outside the world", expected=false
      ,actual=world.isValidPosition(new Position2D(x=WORLD_WIDTH+10, y=WORLD_HEIGHT+10)));
    assertBoolEquals(msg="Point outside the world", expected=true
          ,actual=world.isValidPosition(new Position2D(x=WORLD_WIDTH-10, y=WORLD_HEIGHT-10)));

    assertRealEquals(msg="Dog has correct x position", expected=25, actual=dog.position.x);
    assertRealEquals(msg="Cat has correct x position", expected=150, actual=cat.position.x);
    this.tearDown(t);
  }

  proc testBuildSim() {
    var t = this.setUp("Build a Basic BoxWorld Sim");
    assertStringEquals(msg="Dog is first agent", expected="dog", actual=world.agents[1].name);
    assertStringEquals(msg="Cat is second agent", expected="cat", actual=world.agents[2].name);
    this.tearDown(t);
  }

  proc testSensors() {
    var t = this.setUp("Sensors");
    //writeln(world.agents[1].sensors);
    var sensor = world.agents[1].sensors[1],
        me = world.agents[sensor.meId],
        you = world.agents[sensor.youId];
    assertIntArrayEquals(msg="Dog's first sensor gives correct array"
      ,expected=[0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      ,actual=sensor.v(me, you));

    world.addAgentSensor(agent=dog, target=cat, sensor=world.getDefaultAngleSensor());
    var angleSensor = world.agents[1].sensors[2];
    assertIntArrayEquals(msg="Dog's angle sensor gives correct array"
      ,expected=[0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0]
      ,actual=angleSensor.v(me, you));

    this.tearDown(t);
  }

  proc testServos() {
    var t = this.setUp("Servos");
    // New servo
    dog = world.addAgentServo(agent=dog, servo=new MotionServo(), sensor=world.getDefaultAngleSensor());
    var servo=dog.servos;

    var options = world.getMotionServoOptions(agent=dog, servo=dog.servos[1]: MotionServo);
    assertIntEquals(msg="Interior point has 12 options", expected=12, actual=options.shape[1]);
    dog.position = new Position2D(x=0, y=25);
    var options2 = world.getMotionServoOptions(agent=dog, servo=dog.servos[1]: MotionServo);
    assertIntEquals(msg="Boundary point has only 6 options", expected=6, actual=options2.shape[1]);

    this.tearDown(t);
  }

  proc testMaze() {
    var t = this.setUp("Maze World");
    var pos = new MazePosition(cellId=1);
    var theseus = maze.addAgent(name="theseus", position=new MazePosition(1)),
        csense = maze.getDefaultCellSensor();

    theseus = maze.addAgentSensor(agent=theseus, target=new SecretAgent(), sensor=csense);
    theseus = maze.addAgentServo(agent=theseus, servo=maze.getDefaultMotionServo()
      ,sensor=csense);

    var options = maze.getMotionServoOptions(agent=theseus, servo=theseus.servos[1]);
    writeln(options);
    var state = maze.buildAgentState(theseus);
    writeln(state);
    var (opts, currentState) = maze.presentOptions(theseus);
    /*
    var mm = maze.getDefaultMotionServo();
    writeln(theseus.position);
    mm.f(agent=theseus, choice=[1,0,0,0]);
    writeln(theseus.position); */

    this.tearDown(t);
  }

  proc run() {
    super.run();
    testWorldProperties();
    testBuildSim();
    testSensors();
    testServos();
    testMaze();
    //testTilers();
    //testWorld();
    //testAgentRelativeMethods();
    //testMemory();
    //testPresentOptions();
    //testRewards();
    //testPolicies();
    //testRunDefault();
    return 0;
  }
}

proc main() {
  var t = new RelchTest(verbose=false);
  var ret = t.run();
  t.report();
  return ret;
}
