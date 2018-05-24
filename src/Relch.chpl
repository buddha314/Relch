/* Documentation for Relch */
module Relch {
  use Math, NumSuch;
  use agents, policies, physics, rewards, dtos, worlds, boxWorld, mazeWorld;

  /* Modeled after the AIGym Class: https://github.com/openai/gym/tree/master/gym/envs#how-to-create-new-environments-for-gym* */
  class Environment {
    var name: string,
        currentStep: int,
        world: World;

    proc init(name: string) {
      this.name=name;
      this.currentStep = 1;
    }

    proc init(name: string, world:World) {
      this.init(name=name);
      this.world = world;
    }


    /*
     This needs to return these things:
     1. The new state (e.g. relative positions to other objects), [] int
     2. Reward: real
     3. Done: bool, should the simumlation stop now?
     4. New Position: In several sims, the actual position is not part of the state space
        so use this to give the agent his new position
     */
    proc step(erpt: EpochDTO, agent: Agent, action:[] int) {
        var state: [1..agent.sensorDimension()] int = buildAgentState(agent=agent);
        var reward = this.dispenseReward(agent=agent, state=state);
        var done: bool = this.areYouThroughYet(erpt=erpt, agent=agent, any=true);  // Yes, this is a Steve Martin reference
        agent.currentStep += 1;
        return (state, reward, done);
    }

    proc reset() {
      this.resetAgents();
    }

    proc resetAgents() {
      for agent in this.agents do this.resetAgent(agent);
    }
    proc resetAgent(agent: Agent) {
      agent.currentStep = 1;
      agent.position = agent.initialPosition;
      agent.done = false;
      //for sensor in agent.policy.sensors {
      for sensor in agent.sensors {
        sensor.done = false;
      }
      for reward in agent.rewards do reward.accomplished = false;
    }

    proc presentOptions(agent: Agent) {
      /* Constructing options is kinda hard, right now just 1 for every
         element of the sensors */

      var options: [1..0, 1..0] int;
      for s in 1..agent.servos.size {
        if s > 1 {
          halt("No more than one servo supported at the moment");
        }
        var servo = agent.servos[s];
        options = this.world.getMotionServoOptions(agent=agent, servo=servo);
      }

      // Right now, this just constructs the state from the Agent as a pass
      // through.  Soon it will make decisions;
      //writeln("building state for ", agent.name);
      var state = buildAgentState(agent=agent);
      //var state: [1..3] int = [0, 0, 1];

      //writeln("exiting presentOptions");
      return (options, state);
    }

    /*
     This is here so ultimately the environment can edit the sensors
     */
    proc buildAgentState(agent: Agent) {
      //writeln("building state for ", agent.name);

      var state: [1..agent.sensorDimension()] int;
      for sensor in agent.sensors {
          ref you = this.perceivables[sensor.targetId];
          //writeln("me ", agent);
          //writeln("you ", you);
          //writeln("sensor: ", sensor);
          var a:[sensor.stateIndexStart..sensor.stateIndexEnd] int = sensor.v(me=agent, you=you);
          state[a.domain] = a;
      }
      //writeln("exiting build state for ", agent.name);
      return state;
    }

    proc dispenseReward(agent: Agent, state: [] int) {
      var r: real = 0.0;
      for reward in agent.rewards {
        r += reward.f(state);
      }
      return r;
    }

    // If any sensor is done, you are done
    // Otherwise all sensors must be done
    proc areYouThroughYet(erpt: EpochDTO, agent: Agent, any: bool = true) {
      var r: bool = false;
      //if this.currentStep >= this.steps then r = true;
      if any {
        for reward in agent.rewards {
          if reward.accomplished then erpt.winner = agent.name;
          if reward.accomplished then return true;
        }
      }
      return r;
    }

    /*
    This should probably be a class;
    Yes, this is a King Gizzard reference
     */
    proc robotStop() {
      for agent in this.agents  {
        if agent.done then return true;
      }
      return false;
    }

    /*
      Does the actual simulation
     */
    iter run(epochs: int, steps: int) : DTO {
      if this.world == nil {
        halt("No world set, aborting");
      }
      var finalized: bool = true;
      for agent in this.agents {
        //writeln("finalizing ", agent.name);
        if !agent.finalized {
          finalized = finalized && agent.finalize();
        }
        if !agent.finalized then halt("Agent ", agent.name, " cannot be finalized, halting.");
      }
      for i in 1..epochs {
        var erpt = new EpochDTO(id=i);
        //writeln("starting epoch ", i);
        var keepSteppin: bool = true,
            step: int = 1;
        //for step in 1..steps {
        while keepSteppin {
          var sr = new StepReport(epoch=i, step=step);
        //writeln("\tstarting step ", step);
          for agent in this.agents{
            //writeln("\t\tagent: ", agent);
            if agent.done then continue;
            agent.currentStep = step;
            // DM presents options
            //writeln("\t\tpresenting options");
            var (options, currentState) = this.presentOptions(agent);
            //if agent.name == "dog" then writeln(options);
            // A chooses an action
            //writeln("\t\tagent choosing");
            var choice = agent.choose(options, currentState);
            //writeln("\t\tagent acting");
            agent.act(choice);
            // DM rewards
            //writeln("\t\tstepping");
            var (nextState, reward, done) = this.step(erpt=erpt, agent=agent, action=choice);
            // Add the memory
            try! agent.add(new Memory(state=nextState, action=choice, reward=reward));
            if done {
              agent.done = true;
              break;
            }
            // Return A
            yield new AgentDTO(agent);
          }
          //writeln(sr);
          if this.robotStop() {
            keepSteppin = false;
          }
          step += 1;
          if steps > 0 && step >= steps then keepSteppin = false;
        }
        erpt.steps = step;
        step = 0;
        for agent in this.agents {
          //writeln("larnin!");
          agent.learn();
        }
        this.reset();
        yield erpt;
      }
    }
  }

  class StepReport {
    var epoch: int,
        step: int;
    proc init(epoch:int, step:int) {
      this.epoch = epoch;
      this.step = step;
    }

    proc readWriteThis(f) {
      f <~>
      "epoch: " <~> this.epoch <~>
      " step: " <~> this.step <~> "\n";
    }
  }

}
