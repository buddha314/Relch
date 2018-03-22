/* Documentation for Relch */
module Relch {
  use worlds;
  config const N_EPISODES: int,
               LEARNING_RATE: real,   // alpha
               DISCOUNT_FACTOR: real, // gamma
               LEARNING_STEPS: int,
               TRACE_DECAY: real;     // lambda

}
