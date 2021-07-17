# SimulatedAnnealing.jl

A Julia implementation of the simulated annealing algorithm for global optimisation from Corana et al. (1987).

## Method

The algorithm works by taking random moves in the solution space, accepting the point if it is uphill (for maximisation). Downhill moves will be accepted according to the current temperature and Metropolis criterion: the lower the temperature the less likely downhill moves will be accepted.

At the beginning of the optimisation the temperature is high and so it can easily accept downhill moves and escape from any local maxima. As it progresses, the temperature decreases, making it less likely to take downhill moves, and so the algorithm focuses in on the global maximum (hopefully).

The algorithm consists of three nested loops:

- N: takes a random move, within the step length, along each dimension of the solution space and evaluates this new point.

- Ns: repeats the N loop Ns times then adjusts the step length.

- Nt: repeats the Ns loop Nt times after which the termination criteria is checked and the optimisation is either terminated or the temperature is reduced.

The step length is widened when too many points are being accepted and narrowed when too many points are being rejected. The overall aim is to finish the optimisation with roughly 50% of all points accepted, see Corana et al., (1987) for more details.

This algorithm is able to run in parallel on multiple processes by splitting up the Ns loop. See Higginson et al. (2005) for more details.

## Implementation

### Overview

Begin by creating a State, Result, and Options objects. The State, Result, and Options objects hold information about the current state, the result and the options of the optimsation, respectively.

``` julia
current, result, options = State(), Result(), Options()
```

To leave all constructors empty will initialise them with their default values optimising the Rosenbrock function in 9 dimensions. A useful non-exported function `SimulatedAnnealing.init(n)` takes as an argument a number of dimensions `n` and initialises all objects to optimise the Rosenbrock function for that many dimensions.

To run the optimisation:

``` julia
sa!(current, result, options)
```

The algorithm mutates the result object. To see the results simply type:

``` julia
results.fopt    # Returns the optimal function value
results.xopt    # Returns the optimal parameters
```

### Customising the optimisation

The `Options()` constructor takes the following key word arguments:

- `f`: the function to be maximised or minmised. Required to take a single input `x` and return a scalar value.

- `N`: dimension/length of the input to `f`.

- `Ns`: number of cycles before the search space is adjusted.

- `Nt`: number of cycles before the temperature is reduced.

- `Ne`: number of successive temperature reductions without which the optimum has not increased by more than `tol` (below) then the optimisation is terminated.

- `lb`: vector of length `N` containing the lower bound for each parameter.

- `ub`: vector of length `N` containing the upper bound for each parameter.

- `R`: temperature reduction factor. After each `Nt` loop the temperature becomes: `T *= R`

- `c`: vector of length `N`, the step length adjustment factor (recommended to leave as default). See `criteria` function for how it influences the step length or Corana et al. (1987) for rationale.

- `max`: `true` or `false`, whether to maximise the function or not.

- `tol`: tolerance for terminating optimisation. See `Ne` above.

- `max_eval`: maximum number of steps/function evaluations (currently only checked after each temperature reduction).

- `print_status`: `true` or `false`, print outputs after each temperature reduction.

The `Result()` constructor takes the following key word arguments:

- `fopt`: optimum function value found.

- `xopt`: optimum parameters found.

and the following fields provide useful information once the optimisation has finished:

- `terminate`: termination code: `:success` when terminated through no improvement above `tol`, `:max_eval` when max evaluations reached.

- `n_moves`: total number of moves taken.

- `n_accepted`: total number of accepted moves.

- `n_optimums`: total number new optimums found.

The `State()` constructor takes the follwing key word arguments:

- `f`: current function value.

- `x`: vector of length `N` containing the current parameters.

- `v`: vector of length `N` containing the step lengths for each parameter.

- `T`: current temperature.

### Parallelisation

To run the optimisation in parallel:

``` julia
using Distributed

addprocs(4)     # Add number of processes
@everywhere using SimulatedAnnealing

current, result, options = State(), Result(), Options() # Initialise objects

sa!(current, result, options)
```

## References

*Corana, A., Marchesi, M., Martini, C. and Ridella, S., 1987. Minimizing multimodal functions of continuous variables with the “simulated annealing” algorithm. ACM Transactions on Mathematical Software, 13(3), pp.262-280.*

*Higginson, J. S., Neptune, R. R., & Anderson, F. C. (2005). Simulated parallel annealing within a neighbourhood for optimization of biomechanical systems. Journal of Biomechanics, 38(9), 1938–1942.*
