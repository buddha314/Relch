use Relch,
    Charcoal;

class RelchTest : UnitTest {

  proc init(verbose:bool) {
    super.init(verbose=verbose);
    this.complete();
  }

  proc testStep() {
    var sim = new Environment(name="steppin out", epochs=1, steps=2);
    var action: [1..3] int = [1,0,0];
    var bond = new Agent(name="Bond, James Bond", position=new Position(x=7, y=7));
    bond.policy = new RandomPolicy();
    var (state, reward, done, position) = sim.step(agent=bond, action=action);
    assertRealEquals(msg="Default reward is 10.0", expected=10.0, actual = reward);
    assertBoolEquals(msg="Default done is false", expected=false, actual = done);
  }

  proc testRunDefault() {
    var sim = new Environment(name="steppin out", epochs=2, steps=3);
    var bond = new Agent(name="Bond, James Bond", position=new Position(x=7, y=7));
    bond.policy = new RandomPolicy();
    sim.add(bond);
    sim.run();
  }

  proc testTilers() {
    var hundredYardTiler = new LinearTiler(nbins=7, x1=0, x2=100, overlap=0.1, wrap=true);
    var eo:[1..7] int = [1,1,0,0,0,0,0];
    var eo2:[1..7] int = [1,0,0,0,0,0,0];
    var eo3:[1..7] int = [1,0,0,0,0,0,1];
    assertIntArrayEquals(msg="LinearTiler correctly sees overlaps", expected=eo, actual=hundredYardTiler.bin(14.2));
    assertIntArrayEquals(msg="LinearTiler correctly sees non-overlaps", expected=eo2, actual=hundredYardTiler.bin(3.14));
    assertRealApproximates(msg="LinearTiler correcly unbins x", expected=7.14286, actual=hundredYardTiler.unbin(eo));
    assertIntArrayEquals(msg="LinearTiler correctly sees right wrap correctly", expected=eo3, actual=hundredYardTiler.bin(100.05));
    assertIntArrayEquals(msg="LinearTiler correctly sees left wrap correctly", expected=eo3, actual=hundredYardTiler.bin(0.05));
    assertIntArrayEquals(msg="LinearTiler correctly sees left wrap correctly (negative)", expected=eo3, actual=hundredYardTiler.bin(-0.05));

    var whiteBoyTyler = new LinearTiler(nbins=7, x1=0, x2=100, overlap=0.1, wrap=false);
    assertIntArrayEquals(msg="White boys can't wrap", expected=eo2, actual=whiteBoyTyler.bin(-0.05));

    var na = 5;
    var angler = new AngleTiler(nbins=na, overlap=0.05);
    var ao:[1..na] int = [1,0,0,0,1];
    var ao2:[1..na] int = [0,0,1,0,0];
    var ao3:[1..na] int = [0,0,0,0,1];
    assertIntArrayEquals(msg="Angler sees -pi correctly", expected=ao, actual=angler.bin(-pi));
    assertIntArrayEquals(msg="Angler sees origin correctly", expected=ao2, actual=angler.bin(0));
    assertRealApproximates(msg="Angler unbins correctly", expected=2.51327, actual=angler.unbin(ao3));
  }

  proc testSensors() {

    const WORLD_WIDTH: int = 800,
          WORLD_HEIGHT: int = 500;
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

    var hundredYardTiler = new LinearTiler(nbins=7, x1=0, x2=100, overlap=0.1, wrap=true),
        angler = new AngleTiler(nbins=7, overlap=0.05),
        s1 = new Sensor(name="s1");
    s1.add(hundredYardTiler);
    s1.add(angler);
    s1.target = aflocka;
    var s1out: [1..14] int = [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0];
    var s2out: [1..14] int = [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0];
    assertIntArrayEquals("Sensor 1 picks up angle and distance", expected=s1out, actual=s1.v(mike, aflocka.findCentroid(sim.agents)));
    assertIntArrayEquals("Sensor 1 picks up angle and distance to gord"
      , expected=s2out, actual=s1.v(mike, gord));

    var dog = new Agent(name="dog", position=new Position(x=25, y=25));
    var nn = aflocka.findPositionOfNearestMember(dog, sim.agents);
    assertRealEquals("Sensor finds that mike is closest to dog (x)", expected=100.0,actual=nn.x);
    assertRealEquals("Sensor finds that mike is closest to dog (y)", expected=100.0,actual=nn.y);
    var nm = aflocka.findNearestMember(dog, sim.agents);
    assertStringEquals("Sensor finds that mike is closest to dog (agent)", expected="mike",actual=nm.name);
    return 0;
  }

  proc testAgentRelativeMethods() {
    var catSensor = new Sensor(name="find the cat", size=7);
    var dogSensor = new Sensor(name="find the dog", size=7);
    var is: [1..0] Sensor;
    var ws: [1..0] Sensor;
    is.push_back(catSensor);
    ws.push_back(catSensor);
    var dog = new Agent(name="dog", position=new Position(x=25, y=25));
    var cat = new Agent(name="cat", position=new Position(x=50, y=50));
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

    cat.moveAlong(pi/6);
    assertRealApproximates(msg="Cat moved along pi/6 (x)", expected=52.5981, actual=cat.position.x, error=1e-03);
    assertRealApproximates(msg="Cat moved along pi/6 (y)", expected=1.5, actual=cat.position.y);
  }

  proc testBuildSim() {
    const WORLD_WIDTH: int = 800,
          WORLD_HEIGHT: int = 500;
    var sim = new Environment(name="simulation amazing", epochs=10, steps=10);
    sim.world = new World(width=WORLD_WIDTH, height=WORLD_HEIGHT);

    /* Build some sensor arrays */
    var ifs:[1..0] Sensor,
        wfs:[1..0] Sensor;

    var dog = new Agent(name="dog", position=new Position(x=25, y=25));
    var cat = new Agent(name="cat", position=new Position(x=50, y=50));

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
  }

  proc testDogChaseCat() {
    const WORLD_WIDTH: int = 800,
          WORLD_HEIGHT: int = 500;
    var sim = new Environment(name="simulation amazing", epochs=10, steps=5);
    sim.world = new World(width=WORLD_WIDTH, height=WORLD_HEIGHT);

    var dog = new Agent(name="dog", position=new Position(x=25, y=25)),
        cat = new Agent(name="cat", position=new Position(x=50, y=50)),
        hundredYardTiler = new LinearTiler(nbins=7, x1=0, x2=100, overlap=0.1, wrap=true),
        angler = new AngleTiler(nbins=7, overlap=0.05),
        whereDatCat = new Sensor(name="Where Dat Cat?");

    whereDatCat.target = cat;
    whereDatCat.add(hundredYardTiler);
    whereDatCat.add(angler);
    dog.add(whereDatCat);
    dog.policy = new RandomPolicy();

    var motionServo = new MotionServo(tiler=angler);
    dog.add(motionServo);

    /* Note, dog has no sensors for this test */
    for e in 1..25 {
      //writeln("whereDatCat? ", whereDatCat.v(me=dog, you=cat));
      var option = whereDatCat.v(me=dog); // This is wrong, that is sensor output
      var opt = option[8..14];
      dog.act(opt);
      if dist(dog, cat) < 1.2 {
        assertIntEquals(msg="Dog stops chasing cat at epoch 16", expected=16, actual=e);
        break;
      }
    }

    /* Now run it with the policy, probably won't converge */
    /* Get doggy back at the starting line */
    dog.position.x = 25;
    dog.position.y = 25;
    sim.add(dog);
    for a in sim.run() {
      writeln(a);
    }
  }

  proc testPolicies() {
      var p = new Policy();
      var rp = new RandomPolicy();

      var cat = new Agent(name="cat", position=new Position(x=50, y=50)),
          whereDatCat = new Sensor(name="Where Dat Cat?");
      whereDatCat.target = cat;

      var tfp = new FollowTargetPolicy(sensor=whereDatCat);
      //writeln("target position: ", tfp.sensor.target);

      var nActions: int = 4,
          nStates :int = 5;
      var qp = new QLearningPolicy(nActions=nActions, nStates=nStates);
      var qstate: [1..nStates] int = 0,
          qactions = eye(nActions, int);

      // Build a matrix so we know the answer
      var Q = Matrix(
          [0.1, 0.2, 0.1, 0.4, 0.5],
          [0.3, 0.1, 0.9, 0.8, 0.1],
          [0.6, 0.5, 0.6, 0.3, 0.1],
          [0.4, 0.7, 0.5, 0.7, 0.4] );
      qp.Q = Q;

      qstate[3] = 1;  // Just doing state 3 now.
      qactions[3,3] = 0;
      var pc = p.f(options=qactions, state=qstate);
      var rc = rp.f(options=qactions, state=qstate);

      var choice = qp.f(options=qactions, state=qstate);
      var c:[1..4] int = [0,1,0,0]; // Should pick the second option, it has max of 3rd Q col
      assertIntArrayEquals(msg="Correct choice is taken", expected=c, actual=choice);
      return 0;
    }

  proc run() {
    super.run();
    testStep();
    testRunDefault();
    testTilers();
    testSensors();
    testAgentRelativeMethods();
    testBuildSim();
    testDogChaseCat();
    testPolicies();
    return 0;
  }
}

proc main() {
  var t = new RelchTest(verbose=false);
  var ret = t.run();
  t.report();
  return ret;
}
