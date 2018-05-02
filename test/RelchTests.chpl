use Relch,
    Charcoal;

class RelchTest : UnitTest {

  proc init(verbose:bool) {
    super.init(verbose=verbose);
    this.complete();
  }

  proc testTilers() {
    var hundredYardTiler = new LinearTiler(nbins=7, x1=0, x2=100, overlap=0.1, wrap=false);
    writeln(hundredYardTiler.bins);
    assertIntEquals("Blank test", expected=1, actual=1);
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
