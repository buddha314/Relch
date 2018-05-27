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

    proc reset() {
      this.resetAgents();
    }

    proc resetAgents() {
      for agent in this.world.agents do agent.reset();
    }

    //proc presentOptions(agent: Agent) {
    proc presentOptions(agent) {
      /* Constructing options is kinda hard, right now just 1 for every
         element of the sensors */
      var optDom: domain(2),
          options: [optDom] int;

      for s in 1..agent.servos.size {
        if s > 1 {
          halt("No more than one servo supported at the moment");
        }
        var servo = agent.servos[s];
        if servo: MotionServo != nil {
          var opts = this.world.getMotionServoOptions(agent=agent, servo=servo:MotionServo);
          writeln(" env opts ", opts.domain);
          optDom = opts.domain;
          options = opts;
        }
      }

      // Right now, this just constructs the state from the Agent as a pass
      // through.  Soon it will make decisions;
      //writeln("building state for ", agent.name);
      //var state = buildAgentState(agent=agent);
      var state = this.world.buildAgentState(agent=agent);
      //var state: [1..3] int = [0, 0, 1];

      //writeln("exiting presentOptions");
      return (options, state);
    }


    /*
    This should probably be a class;
    Yes, this is a King Gizzard reference
     */
    proc robotStop() {
      for agent in this.world.agents  {
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
      //for agent in this.agents {
      for agent in this.world.agents {
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
          for agent in this.world.agents{
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
            //agent.act(choice);
            // DM rewards
            //writeln("\t\tstepping");
            //var (nextState, reward, done) = this.step(erpt=erpt, agent=agent, action=choice);
            var (nextState, reward, done) = this.world.step(erpt=erpt, agent=agent, action=choice);
            // Add the memory
            try! agent.add(new Memory(state=nextState, action=choice, reward=reward));
            if done {
              agent.done = true;
              break;
            }
            // Return A
            yield agent.DTO();
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
        for agent in this.world.agents {
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
