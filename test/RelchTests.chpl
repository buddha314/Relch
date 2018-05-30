use Relch,
    NumSuch,
    LinearAlgebra,
    Charcoal;

class RelchTest : UnitTest {

  const WORLD_WIDTH: int = 800,
        WORLD_HEIGHT: int = 500,
        N_ANGLES: int = 5,
        N_DISTS: int = 7,
        N_EPOCHS: int = 3,
        N_STEPS: int = 5;

  /* We use these again and again for testing */
  var env = new Environment(name="simulating amazing!"),
      world = new BoxWorld(width=WORLD_WIDTH, height=WORLD_HEIGHT),
      dog: BoxWorldAgent,
      cat: BoxWorldAgent,
      maze = new Maze(width=10, height=10, wrap=true);


  proc setUp(name: string = "setup") {
    env = new Environment(name="simulating amazing!");
    world = new BoxWorld(width=WORLD_WIDTH, height=WORLD_HEIGHT, wrap=false);
    dog = world.addAgent(name="dog", position=new Position2D(x=25, y=25));
    cat = world.addAgent(name="cat", position=new Position2D(x=150, y=150));
    //world.addAgentSensor(agent=dog, target=cat, sensor=world.getDefaultDistanceSensor());
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

  proc testSensors() {
    var t = this.setUp("Sensors");
    var catAngleSensor = world.getDefaultAngleSensor();
    world.addAgentSensor(agent=dog, target=cat, sensor=catAngleSensor);
    var sensor = world.agents[1].sensors[1],
        me = world.agents[sensor.meId],
        you = world.agents[sensor.youId];

    assertIntArrayEquals(msg="Dog's first sensor gives correct array"
      ,expected=[0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0]
      ,actual=sensor.v(me, you));

    world.addAgentSensor(agent=dog, target=cat, sensor=world.getDefaultDistanceSensor());
    world.addAgentServo(agent=dog, sensor=catAngleSensor, servo=world.getDefaultMotionServo());
    var angleSensor = world.agents[1].sensors[2];
    assertIntArrayEquals(msg="Dog's angle sensor gives correct array"
      ,expected=[0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      ,actual=angleSensor.v(me, you));

    this.tearDown(t);
  }

  proc testBoxWorld() {
    var t = this.setUp("Box World");
    env.addWorld(world);
    var catAngleSensor = world.getDefaultAngleSensor();
    dog = world.addAgentSensor(agent=dog, target=cat, sensor=catAngleSensor): BoxWorldAgent;
    dog = world.setAgentTarget(agent=dog, target=cat, sensor=catAngleSensor): BoxWorldAgent;
    dog = world.addAgentSensor(agent=dog, target=cat
      ,sensor=world.getDefaultDistanceSensor(), reward=world.getDefaultProximityReward()): BoxWorldAgent;
    dog = world.addAgentServo(agent=dog, sensor=catAngleSensor, servo=world.getDefaultMotionServo());

    var optAnswer = Matrix(
     [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
     [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
     [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
     [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
     [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
     [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0],
     [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0],
     [0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0],
     [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],
     [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
     [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
     [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]);

     var stateAnswer = Vector(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
     var (options, currentState) = env.presentOptions(agent=dog);
     assertIntArrayEquals(msg="Dog has correct options", expected=optAnswer, actual=options);

     //writeln("dog currentState ", currentState);
     assertIntArrayEquals(msg="Dog has correct state", expected=stateAnswer, actual=currentState);

     var choice = dog.choose(options, currentState);
     assertIntArrayEquals(msg="Dog has correct choice"
       , expected=[0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0], actual=choice);
     var (nextState, reward, done) = world.step(erpt=new EpochReport(id=1), agent=dog, action=choice);
     assertBoolEquals(msg="Dog is not done", expected=false, actual=done);
     assertRealApproximates(msg="Dog x has moved", expected=27.5238, actual=dog.position.x, error=1e-4);
     assertIntEquals(msg="Dog state is not empty", expected=39, actual = nextState.size);
     assertRealEquals(msg="Dog gets a negativiy biscuit", expected=-1.0, actual=reward);
     // Note, the dog moves at speed 3 but the bins are larger than that,
     //  so there does not appear to be a difference in state.
     assertIntArrayEquals(msg="Dog have moved but state has not", expected=stateAnswer, actual=nextState);
     //writeln("dog next state: ", nextState-stateAnswer);

     // Crank up the speed to see the tiling change
     dog.speed = 50;
     var (nextStateFast, rewardFast, doneFast) = world.step(erpt=new EpochReport(id=2), agent=dog, action=choice);
     assertRealApproximates(msg="Dog y has moved fast", expected=53.654, actual=dog.position.y, error=1e-4);
     var stateAnswerFast = Vector(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
     assertIntArrayEquals(msg="Dog have moved fast and state changed", expected=stateAnswerFast, actual=nextStateFast);

     this.tearDown(t);
  }

  proc testBoxWorldSim() {
    var t = this.setUp("Box World Sim");
    var catAngleSensor = world.getDefaultAngleSensor(),
        dogSensor = world.getDefaultAngleSensor();

    world = env.addWorld(world);
    assertBoolEquals(msg="World is still correct type", expected=false, actual=world:BoxWorld == nil);
    assertStringEquals(msg="Dog is first agent", expected="dog", actual=world.agents[1].name);
    assertStringEquals(msg="Cat is second agent", expected="cat", actual=world.agents[2].name);

    dog = world.addAgentSensor(agent=dog, target=cat, sensor=catAngleSensor): BoxWorldAgent;
    dog = world.setAgentTarget(agent=dog, target=cat, sensor=catAngleSensor): BoxWorldAgent;
    dog = world.addAgentSensor(agent=dog, target=cat
      ,sensor=world.getDefaultDistanceSensor(), reward=world.getDefaultProximityReward()): BoxWorldAgent;
    dog = world.addAgentServo(agent=dog, sensor=catAngleSensor, servo=world.getDefaultMotionServo());

    // Set up the cat
    cat = world.addAgentServo(agent=cat, sensor=dogSensor, servo=world.getDefaultMotionServo()): BoxWorldAgent;
    cat = world.setAgentTarget(agent=cat, target=dog, sensor=dogSensor, avoid=true): BoxWorldAgent;

    //dog = world.setAgentTarget(agent=dog, target=cat, sensor=catAngleSensor): BoxWorldAgent;
    //dog = world.addAgentServo(agent=dog, sensor=catAngleSensor, servo=world.getDefaultMotionServo()): BoxWorldAgent;

    for e in env.run(epochs=2, steps=3) do writeln(e);
    this.tearDown(t);
  }

  proc testMaze() {
    var t = this.setUp("Maze World");
    env.addWorld(maze);
    var pos = new MazePosition(cellId=1);
    var theseus = maze.addAgent(name="theseus", position=new MazePosition(1)),
        csense = maze.getDefaultCellSensor();

    var exitReward = new Reward(value=10, penalty=-1);
    var exitState:[1..1, 1..100] int=0;
    exitState[1,11]=1;
    exitReward = exitReward.buildTargets(targets=exitState);

    theseus = maze.addAgentSensor(agent=theseus, target=new SecretAgent()
      , sensor=csense, reward=exitReward);

    exitReward.finalize();
    theseus = maze.addAgentServo(agent=theseus, servo=maze.getDefaultMotionServo()
      ,sensor=csense);
    maze.setAgentPolicy(agent=theseus, policy=new RandomPolicy());

    var optAnswer = Matrix( [0,0,0,0],[0,1,0,0], [0,0,0,1] ),
        stateAnswer: [1..100] int = 0;
    stateAnswer[1] = 1;

    var (options, currentState) = env.presentOptions(theseus);
    assertIntArrayEquals(msg="Theseus has correct options", expected=optAnswer, actual=options );
    assertIntArrayEquals(msg="Theseus has correct state", expected=stateAnswer, actual=currentState);
    //writeln("theseus position: ", theseus.position);
    //writeln("theseus state: ", currentState);

    var choice = theseus.choose(options, currentState);
    assertIntEquals(msg="Theseus choice is 4 long", expected=4, actual=choice.size);
    //writeln("maze choice: ", choice);
    // Since Theseus is using a random policy, we force his choice for the test
    var (nextState, reward, done) = world.step(erpt=new EpochReport(id=1), agent=theseus, action=[0,0,0,1]);
    assertRealEquals(msg="Theseus gets reward for stepping south", expected=10.0, actual=reward);
    assertBoolEquals(msg="Theseus ain't done yet", expected=true, actual=done);
    var nextStateAnswer: [1..100] int = 0;
    nextStateAnswer[11] = 1;
    assertIntArrayEquals(msg="Theseus has take the correct step", expected=nextStateAnswer, actual=nextState);


    this.tearDown(t);
  }

  proc run() {
    super.run();
    testWorldProperties();
    testSensors();
    testServos();
    testBoxWorld();
    testBoxWorldSim();
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
