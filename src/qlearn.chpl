use NumSuch,
    Random;

config const nSteps: int = 3,
             learningRate: real = 0.01,
             discountFactor: real = 0.5;

var states: [1..0] string,
    actions: [1..0] string;

states.push_back("rainy");
states.push_back("cloudy");
states.push_back("sunny");
actions.push_back("umbrella");
actions.push_back("none");

var rstates = states;
var ractions = actions;


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
  for step in 1..nSteps {
    shuffle(rstates);
    var state = rstates[1];
    var action = policy(state);
    updateQ(state, action, 3.0);
  }
  report();
  return 0;
}

proc updateQ(state: string, action: string, reward: real) {
    const m = Q.rowMax(state);
    var r = (1-learningRate) * Q.get(state, action) + learningRate * (reward + discountFactor * m);
    Q.set(state, action, w=r);
}

/*
 If there is no information around this action, pick a random one
 */
proc policy(state: string) {
  var action: string;
  var i = Q.rowArgMax(state)[2];
  if i > 0 {
    action = actions[i];
  } else {
    shuffle(ractions);
    action = ractions[1];
  }
  return action;
}

proc report() {
  writeln("about to report");
  for state in states {
    const action = actions[Q.rowArgMax(state)[2]];
    writeln(" ** state best action %s -> %s (%r)".format(state, action, Q.get(state, action)));
  }
}
