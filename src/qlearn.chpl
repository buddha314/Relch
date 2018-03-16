use NumSuch,
    Random;

config const nSteps: int = 3,
             learningRate: real = 0.01,
             discountFactor: real = 0.5;

var states: [1..0] string,
    actions: [1..0] string,
    history: [1..0] Qoutcome;

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

  proc writeThis() {
    var m: string = "state, action, reward:  %8s  %8s  %{#.###}".format(this.state, this.action, this.reward);
    return m;
  }
}

proc qlearn() {
  qReport();
  for step in 1..nSteps {
    shuffle(rstates);
    var state = rstates[1];
    var action = policy(state);
    var o = new Qoutcome(state=state, action=action, reward=Q.get(state, action));
    history.push_back(o);
    updateQ(o);
  }
  report();
  return 0;
}

//proc updateQ(state: string, action: string, reward: real) {
proc updateQ(outcome: Qoutcome) {
    const j = Q.rowArgMax(outcome.state)[2];
    var m: real = 0;
    if j > 0 {
      m = Q.rowMax(j);
    }
    var r = (1-learningRate) * Q.get(outcome.state, outcome.action) + learningRate * (outcome.reward + discountFactor * m);
    Q.set(outcome.state, outcome.action, w=r);
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

proc historyReport() {
  writeln("\nHistory\n");
  for h in history {
    //h.writeThis();
    writeln(h.writeThis());
  }
}

proc qReport() {
  write("          ");
  for action in actions {
    write("%8s".format(action));
  }
  writeln();
  for state in states {
    write("%8s".format(state));
    for action in actions {
      write("    %{#.###}".format(Q.get(state, action)));
    }
    writeln();
  }
  writeln();

}

proc report() {
  writeln("about to report");
  for state in states {
    const j = Q.rowArgMax(state)[2];
    if j > 0 {
      const action = actions[Q.rowArgMax(state)[2]];
      writeln(" ** state best action %s -> %s (%n)".format(state, action, Q.get(state, action)));
    } else {
      writeln(" ** state %s has no best action".format(state));
    }
  }
  historyReport();
  qReport();
}
