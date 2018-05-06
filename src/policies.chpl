use NumSuch;

class Policy {
  proc init() {}

  proc f(options:[] int, state:[] int) { return [1]; }
}

class RandomPolicy : Policy {
  proc init() {
    super.init();
    this.complete();
  }

  proc f(options:[] int, state:[] int) {
    var c = randInt(1,options.shape[1]);
    const choice:[1..options.shape[2]] int = options[c,..];
    return choice;
  }
}

class QLearningPolicy : Policy {
  var d: domain(2),
      Q: [d] real,
      E: [d] real;

  proc init(nActions: int, nStates: int) {
    super.init();
    this.complete();
    this.d = {1..nActions, 1..nStates};
    fillRandom(this.Q);
    this.E = 0.0;
  }
  proc f(options:[] int, state:[] int) {
    /* Need to translate the options into discrete rows */
    var choices: [1..options.shape[1]] real = 0.0;
    /* The states are discrete, but the input looks like [0 0 1 0]
       meaning we are in state 3 */
    var s:int = argmax(state);
    for r in 1..options.shape[1] {
      if options[r,r] == 1 {
        choices[r] = this.Q[r,s];
      } else {
        choices[r] = 0.0;
      }
    }
    return options[argmax(choices), ..];
  }

}
