use Chingon;

/*
 Probably too abstract
 */
class World {
  proc init() { }
}

/*
Will have rewards and stuff eventually
 */
class GridWorld : GameBoard {
  var absorbingStates: BiMap;

  proc init(r:int) {
    super.init(r=r);
    this.absorbingStates = new BiMap();
    this.absorbingStates.add("B2", -1);
    this.absorbingStates.add("B4", -1);
    this.absorbingStates.add("C4", -1);
    this.absorbingStates.add("D1", -1);
    this.absorbingStates.add("D4", 1);
    this.complete();
  }
}


class Episode {
  var id: int,
      path: [1..0] string,
      value: int;
  proc init(id: int) {
    this.id = id;
  }

  proc finalState() {
    return this.path[this.path.domain.last];
  }

  proc writeThis(f) {
    f <~> "Episode %n had final state %s for value %n".format(this.id, this.finalState(), this.value);
  }
}
