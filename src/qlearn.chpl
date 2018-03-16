use NumSuch,
    Random;

var states: [1..0] string,
    actions: [1..0] string,
    //nSteps: int = 100,
    nSteps: int = 3,
    learningRate: real = 0.01,
    discountFactor: real = 0.5;

states.push_back("rainy");
states.push_back("cloudy");
states.push_back("sunny");
actions.push_back("umbrella");
actions.push_back("none");
var Q = new NamedMatrix(rownames=states, colnames=actions);
Q.set("rainy", "umbrella", 1);
Q.set("rainy", "none", -1);
Q.set("sunny", "umbrella", -1);
Q.set("sunny", "none", 1);

class Qoutcome {
  var agent: int,
      state: string,
      action: string,
      reward: real;

  proc init(agent:int =1, state:string, action:string, reward: real) {
    this.agent = agent;
    this.state = state;
    this.action = action;
    this.reward = reward;
  }
}

proc qlearn() {
  writeln("Q.X!\n",Q.X);
  var rstates = states;
  var ractions = actions;
  for step in 1..nSteps {
    shuffle(rstates);
    var state = rstates[1];
    //var action = ractions[1];
    var action = actions[Q.rowArgMax(state)];
    writeln("starting at state %s".format(state));
    updateQ(state, action, 3.0);
  }
  writeln("Q.X!\n",Q.X);
  return 0;
}

proc updateQ(state: string, action: string, reward: real) {
    const m = Q.rowMax(state);
    var r = (1-learningRate) * Q.get(state, action) + learningRate * (reward + discountFactor * m);
    Q.set(state, action, w=r);
}
