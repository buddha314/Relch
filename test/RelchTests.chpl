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

  proc testAgentRelativeMethods() {
    var catSensor = new Sensor(size=7);
    var dogSensor = new Sensor(size=7);
    var is: [1..0] Sensor;
    var ws: [1..0] Sensor;
    is.push_back(catSensor);
    ws.push_back(catSensor);
    var dog = new Agent(name="dog"
      , internalSensors=is, worldSensors=ws
      , position=new Position(x=25, y=25));
    var cat = new Agent(name="cat"
      , internalSensors=is, worldSensors=ws
      , position=new Position(x=50, y=50));
    var d: real = 35.3553;
    assertRealApproximates(msg="Distance from dog to cat is correct"
      , expected=d, actual=dog.distanceFromMe(cat)
      , error=1.0e-3);
    //writeln(dog.distanceFromMe(cat));
  }

  proc run() {
    super.run();
    testTilers();
    testAgentRelativeMethods();
    return 0;
  }
}

proc main() {
  var t = new RelchTest(verbose=false);
  var ret = t.run();
  t.report();
  return ret;
}
