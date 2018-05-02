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

  }

  proc run() {
    super.run();
    testTilers();
    return 0;
  }
}

proc main() {
  var t = new RelchTest(verbose=false);
  var ret = t.run();
  t.report();
  return ret;
}
