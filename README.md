# Relch

Math? $x$

Reinforcment Learning in Chapel.  Some experiments, probably won't last long but may be useful if you're trying to learn one or the other.

* [Silver Site](http://www0.cs.ucl.ac.uk/staff/d.silver/web/Teaching.html) with slides
* Maybe [this one](http://www.mnemstudio.org/path-finding-q-learning-tutorial.htm)
* Richard Sutton has [some pseudocode](http://www.incompleteideas.net/td-backprop-pseudo-code.text).
* [This talk](https://www.microsoft.com/en-us/research/video/tutorial-introduction-to-reinforcement-learning-with-function-approximation/?from=http%3A%2F%2Fresearch.microsoft.com%2Fapps%2Fvideo%2F%3Fid%3D259577) by Sutton was very useful to me.
* The Sutton and Barto book as [associated code](http://www.incompleteideas.net/book/code/code.html)  Also there is a [matlab version](http://waxworksmath.com/Authors/N_Z/Sutton/sutton.html) which is marginally more legible than Lisp
* David Silver has all of his lectures as a [Youtube Series](https://www.youtube.com/playlist?list=PL7-jPKtc4r78-wCZcQn5IqyuWhBZ8fOxT)


# Notes
I have to get handle on all these ideas in RL. I'll start with Silver's lectures.

## Glossary-ish Things

* $\gamma$ is the DISCOUNT_FACTOR
* $\alpha$ is the LEARNING_RATE
* $\lambda$ is TRACE_DECAY
* "Control" -> policies $\pi$
* A policy is a distribution of actions over states $\pi(a|s)$
* the _action-value_ function is the expected return of the state, action pair $q_{\pi}(s,a) = \mathbb{E}_{\pi}[G_t | S_t=s, A_t=a]$
* $v_*(s) = \max_{\pi}v_{\pi}(s)$
* $q_*(s,a) = \max_{\pi}q_{\pi}(s,a)$
* Bellman optimality can be applied to $v_*, \mathcal{Q}^*, V^*$.  Techniques include
  * Value iteration
  * Policy iteration
  * Q-learning
  * Sarsa
* N-step return $G_t^{(n)} = R_{t+1}+\gamma R_{t+2} + \gamma^{n-1}R_{t+n} + \gamma^nV(S_{t+n})$
  * $G_t^{\lambda} = (1-\lambda) \sum_n \lambda^{n-1} G_t^{(n)}$
  * Should be computed from episodes.
* Eligibility Traces
  * $E_0(s) = 0$
  * $E_t(s) = \gamma\lambda E(s) + \bf 1(S_t=s)$
* Model Free Control (build policy)
  * Can use $Q$ via $\pi' = \arg\max_{a\in \mathcal{A}} Q(s,a)$

## Things to Clarify

* Planning means using a model to build a policy, like game tree searching
* Off-policy vs on-policy
  * My cartoon from Sutton: "off-policy" evaulate options but take actions indepedently (e.g. randomly). "on-policy" follow the best option
  * off-policy is good for building policies and allows you to build multiple policies at once, since you are sampling the space.
  * Silver refers to off-policy as sampling from $\mu$ to learn $\pi$
* Prediction vs. Control: Silver says "evaluate vs optimize" the future
  * Optimal value given a policy vs
  * Optimal policy
* TD vs MC
* Function Approximation for large data / feature space
  * $\hat{v}(s,w) \approx v_{\pi}(s)$
  * $\hat{q}(s,a,w) \approx q_{\pi}(s,a)$
  * Uses $w$ as the parameter, can update using MC or TD methods
  * Gradient Descent vs ... ?
  * Value Function Approximation
    * MC:
    * $TD(0)$:
    * $TD(\lambda)$:
  * Action Value Approximation
    * Leads to feature vectors
      * Coarse and Tile coding
    * Linear ones are easy to update.
* Model vs. No Model
* Sutton mentioned average reward MDPs, have to get back to those.
* More on Eligibility Traces
* Bootstrapping vs. Sampling
* Online vs offline updates, math and methods
  * Offline, errors are accumulated within episode, applied in batch at end of episode.
  * Online: $TD(\lambda)$ updates at each step
* Why / when forward vs backwards $TD(\lambda)$
* When / how SARSA?
  * $Q(S,A) \leftarrow Q(S,A) + \alpha(R + \gamma Q(S',A')-Q(S,A))$

## Silver's Class

### Introduction

Some notation to get started (mostly obvious)

* $A_t$ Action at time $t$
* $O_t$ Observation at time $t$
* $R_t$ Reward at time $t$
* State is a function of history to time $t$, $S(_t) = f(H(_t))$
* He sometimes distinguishes between what the environment and the agent think of the world us $$S_t^e$$
* An Agent must have a policy $\pi$, a value function $V_{\pi}$ and a model $\mathcal{P}$ (of the environment)
  * Policy maps state to action
* Planning means having a model of the environment and does not receive feedback.  Using that to improve policy.

### Markov Decision Processes

* State fully observable.
* Almost all RL can be cast this way.
* Introduces state transition matrix $\mathcal{P}$
* Markov Reward Process is $<\mathcal{S}, \mathcal{P}, \mathcal{R}, \gamma>$
* Return $G_t = \sum_t^{\infty} \gamma^k R_{t+k+1}$
* In general $v(s) = \mathbb{E} [G_t | S_t = s]$
  * This expectation can take several forms.
* Markov Decision Process is $<\mathcal{S}, \mathcal{A}, \mathcal{P}, \mathcal{R}, \gamma>$

### Planning by Dynamic Programming

### Model Free Prediction

### Model Free Control

On-Policy update SARSA($\lambda$) update

1. Initialize $Q(S,A)$ arbitrarily.
1. $\forall$ Episodes
    1. Eligibility Trace $E(s,a)=0$, $\forall s,a$
    1. Initialize $S,A$
    1. $\forall$ steps in episode
         1. Take action $A$, observe $R, S'$
         1. Choose $A'$ from $S'$ using policy derived from $Q$, e.g. $\epsilon$-greedy
         1. $\delta \leftarrow R + \gamma Q(S',A') - Q(S,A)$
         1. $E(S,A) \leftarrow E(S,A) +1$
         1. $\forall a, s$
            1. $Q(s,a) \leftarrow Q(S,A) + \alpha \delta E(s,a)$
            1. $E(s,a) \leftarrow \gamma \lambda E(s,a)$
    1. Until $S$ is terminal

### Value Function Approximation

* Starts in the model-free context for prediction and control
* Remove the lookup table for values.  For instance $V(s)$ has an entry for every $s$
* Remove the lookup table for state-action.  For instance $Q(s,a)$ has an entry for every $(s,a)$
* Approximate value functions with a parameter $v_*(s,w) \approx v_*(s)$
  * Update $w$ using MC or TD learning
* Uses Linear combination or Neural Network for approximator, focuses on linear.
  * Incremental methods for approximator include SGD
* Leads to the notion of feature vectors

### Policy Gradient Methods

### Integrating Learning and Planning

### Exploration and Explotation

### RL in Classic Games

# Examples

Okay, maybe we can try Sutton's Grid World examined in [this paper](http://web.eecs.umich.edu/~baveja/Papers/ICML98_LS.pdf)

# Making things

You will need a filed called `local.mk` that looks something like

```
CHINGON_HOME=$(HOME)/git/chingon
NUMSUCH_HOME=$(HOME)/git/numsuch
CDO_HOME=$(HOME)/git/cdo
CDOEXTRAS_HOME=$(HOME)/git/cdo-extras
CHARCOAL_HOME=$(HOME)/git/Charcoal
BLAS_HOME=/usr/include/
```
