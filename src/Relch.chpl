/* Documentation for Relch */
module Relch {
  use worlds;
  //use qlearn;
  //use frozenLake;
  config const N_EPISODES: int,
               LEARNING_RATE: real,
               DISCOUNT_FACTOR: real,
               LEARNING_STEPS: int;

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

   proc readWriteThis(f) {
     f <~> "state, action, reward:  %8s  %8s  %{#.###}".format(this.state, this.action, this.reward);
   }
  }
}
