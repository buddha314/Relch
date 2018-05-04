use Relch,
    Charcoal;

class RelchTest : UnitTest {

  proc init(verbose:bool) {
    super.init(verbose=verbose);
    this.complete();
  }

  proc testTilers() {
    var hundredYardTiler = new LinearTiler(nbins=7, x1=0, x2=100, overlap=0.1, wrap=true);
    var eo:[1..7] int = [1,1,0,0,0,0,0];
    var eo2:[1..7] int = [1,0,0,0,0,0,0];
    var eo3:[1..7] int = [1,0,0,0,0,0,1];
    assertIntArrayEquals(msg="LinearTiler correctly sees overlaps", expected=eo, actual=hundredYardTiler.bin(14.2));
    assertIntArrayEquals(msg="LinearTiler correctly sees non-overlaps", expected=eo2, actual=hundredYardTiler.bin(3.14));
    assertIntArrayEquals(msg="LinearTiler correctly sees right wrap correctly", expected=eo3, actual=hundredYardTiler.bin(100.05));
    assertIntArrayEquals(msg="LinearTiler correctly sees left wrap correctly", expected=eo3, actual=hundredYardTiler.bin(0.05));
    assertIntArrayEquals(msg="LinearTiler correctly sees left wrap correctly (negative)", expected=eo3, actual=hundredYardTiler.bin(-0.05));

    var whiteBoyTyler = new LinearTiler(nbins=7, x1=0, x2=100, overlap=0.1, wrap=false);
    assertIntArrayEquals(msg="White boys can't wrap", expected=eo2, actual=whiteBoyTyler.bin(-0.05));

    var na = 5;
    var angler = new AngleTiler(nbins=na, overlap=0.05);
    var ao:[1..na] int = [1,0,0,0,1];
    var ao2:[1..na] int = [0,0,1,0,0];
    assertIntArrayEquals(msg="Angler sees -pi correctly", expected=ao, actual=angler.bin(-pi));
    assertIntArrayEquals(msg="Angler sees origin correctly", expected=ao2, actual=angler.bin(0));
  }

  proc TestSensors() {

    const WORLD_WIDTH: int = 800,
          WORLD_HEIGHT: int = 500;
    var sim = new Simulation(name="simulation amazing", epochs=10);
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
        s1 = new Sensor();
    s1.add(hundredYardTiler);
    s1.add(angler);
    s1.target = aflocka;
    var s1out: [1..14] int = [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0];
    assertIntArrayEquals("Sensor 1 picks up angle and distance", expected=s1out, actual=s1.v(mike, aflocka.findCentroid(sim.agents)));

    return 0;
  }

  proc testAgentRelativeMethods() {
    var catSensor = new Sensor(size=7);
    var dogSensor = new Sensor(size=7);
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
  }

  proc testBuildSim() {
    const WORLD_WIDTH: int = 800,
          WORLD_HEIGHT: int = 500;
    var sim = new Simulation(name="simulation amazing", epochs=10);
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

  proc run() {
    super.run();
    testTilers();
    TestSensors();
    testAgentRelativeMethods();
    testBuildSim();
    return 0;
  }
}

proc main() {
  var t = new RelchTest(verbose=false);
  var ret = t.run();
  t.report();
  return ret;
}
