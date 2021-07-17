# Completes Nt loops of loopNs!, beginning at current optimum
@inline function loopNt!(current::State, result::Result, options::Options)
    current.f = result.fopt
    current.x .= result.xopt
    @inbounds for _ in 1:options.Nt
        # loopNs and adjust search space
        loopNs!(current, result, options)
        adjust_step!(current, options)

        # Reset accepted points for search space
        current.n_accepted .= 0
    end

    return nothing
end

# Parallel version of loopNt!, communicates among processes at end of each Ns loop too update search space
@inline function paraloopNt!(current::State, result::Result, options::Options)
    current.f = result.fopt
    current.x .= result.xopt
    @inbounds for _ in 1:options.Nt
        # loopNs, collect results and adjust search space
        @everywhere workers() SimulatedAnnealing.loopNs!(current, result, options)
        collect_results!(current, result)
        adjust_step!(current, options)

        # Reset accepted points for search space
        current.n_accepted .= 0
        
        # Send updated search space and results to workers
        result.n_moves += options.N * options.Ns
        @everywhere workers() current, result = $current, $result
    end

    return nothing
end


# Complete Ns loops of loopN! 
@inline function loopNs!(current::State, result::Result, options::Options)
    @inbounds for _ in 1:options.Ns
        loopN!(current, result, options)
    end

    return nothing
end 

# Pertub each dimension of x independently and accept/reject new point
@inline function loopN!(current::State, result::Result, options::Options)
    @inbounds for i in 1:options.N
        # Perturb current x along dimension i and evaluate new point
        current.xtemp .= current.x
        perturb!(current.xtemp, current.v, i)

        # Check if new point in bounds - if not pick random point in bounds
        check_bounds!(current, options)

        # Evaluate function at new point
        current.ftemp = (2 * options.max - 1) * options.f(current.xtemp)

        # Decide whether to accept point or not
        decision(current) && update_state!(current, result, i)

        # Record if new global optimum
        current.f > result.fopt && update_result!(result, current)

        # Increment number of moves
        result.n_moves += 1

        # Check number of moves
        result.n_moves ≥ options.max_eval && (result.terminate = :maxeval)

    end

    return nothing 
end

# Adjust step length based on number of accepted points
function adjust_step!(current::State, options::Options)
    current.n_accepted ./= options.Ns  # Ratio of accepted points
    current.v .= criteria.(current.v, current.n_accepted, options.c)

    return nothing
end

# Criteria aims to keep a 50% acceptance rate
function criteria(v, accepted, c)
    accepted < 0.0 || accepted > 1.0 ? error("Accepted points out of bounds $accepted") : nothing 
    if accepted > 0.6
        v = v * (1 + c * (accepted - 0.6) / 0.4)
    elseif accepted < 0.4
        v = v / (1 + c * (0.4 - accepted) / 0.4)
    end

    return v
end

# Perturbs x by an random amount (-1.0 to 1.0) * step length for ith dimension
perturb!(x, v, i) = x[i] = x[i]  + (2 * rand() - 1) * v[i]

# Check new point in bounds, otherwise pick random point in bounds
function check_bounds!(current::State, options::Options)
    @inbounds for i in 1:options.N
        if current.xtemp[i] < options.lb[i] || current.xtemp[i] > options.ub[i]
            current.xtemp[i] = options.lb[i] + (options.ub[i] - options.lb[i]) * rand()
        end
    end

    return nothing
end


# Decide whether to accept new point or not
decision(current::State) = current.ftemp > current.f ? true : metropolis(current)

# Metropolis criterion: accept with probability 1 if f > fopt, or accept with probability = exp(f-fopt / T)
metropolis(current::State) = rand() < exp((current.ftemp - current.f) / current.T)

# Reduce temperature 
reduce_temp!(current::State, options::Options) = current.T *= options.R

# Update current struct
function update_state!(current::State, result::Result, i)
    current.f = current.ftemp
    current.x .= current.xtemp
    current.n_accepted[i] += 1.0
    result.n_accepted += 1

    return nothing
end

function update_state!(current::State, trial::State)
    current.f = trial.f
    current.x .= trial.x
end


# Update result struct
function update_result!(result::Result, current::State)
    result.fopt = current.f
    result.xopt .= current.x
    result.n_optimums += 1

    return nothing
end

# Collect results from workers and update search space and result
function collect_results!(current::State, result::Result)
    for w in workers()
        trial = @getfrom w current

        # Update current if greater optimum found
        trial.f > current.f && update_state!(current, trial)

        # Update result if greater optimum found
        trial.f > result.fopt && update_result!(result, trial)

        # Update number of accepted point
        current.n_accepted .+= trial.n_accepted
        result.n_accepted += sum(trial.n_accepted)
    end
        
end

# Termination criteria for stopping optimisation
check_termination(result::Result) = result.terminate !== :none


# Check if improvement less than tolerance
check_improvement!(bests, result::Result, tol) = all((result.fopt .- bests) .< tol) && (result.terminate = :converge)


##### Printing functions
function print_intitial(current::State, options::Options, parallel)
    println("Starting values for simulated annealing:
            Initial f: $(current.f)
            Initial x: $(current.x)
            Initial step length: $(current.v)
            Lower bounds on x: $(options.lb)
            Upper bounds on x: $(options.ub)
            Initial temperature: $(current.T)
            Maximise function: $(options.max)
            N: $(options.N), Ns: $(options.Ns), Nt: $(options.Nt), tol: $(options.tol), max evaluations: $(options.max_eval)
            Parallel evaluation: $parallel")
end

function print_status(current::State, result::Result, options::Options)
    println("Result after temperature reduction: 
             f: $(options.max ? result.fopt : -result.fopt)
             x: $(result.xopt)
             Step length: $(current.v),
             Moves: $(result.n_moves), accepted: $(result.n_accepted), optimums: $(result.n_optimums)
             ")
end 

function print_termination(current::State, result::Result, options::Options)
    println("Simulated annealing reached termination criteria:
             Criteria: $(result.terminate)
             Optimum f found: $(result.fopt)
             Optimum x found: $(result.xopt)
             Final step length: $(current.v)
             Final temperature: $(current.T)
             Number of moves: $(result.n_moves), accepted: $(result.n_accepted), optimums: $(result.n_optimums)
             ")

end

##### Test function
# Multidimensional Rosenbrock, optimum at repeat([1], N)
f(x) = begin
    sleep(0.001)
    [100 * (x[i + 1] - x[i]^2)^2 + (1 - x[i])^2 for i ∈ 1:length(x) - 1] |> sum
end
# Initialise structs to optimise n dimension rosenbrock
function init(n)
    x₀ = rand(n)
    options = Options(func=f, N=n)
    current = State(f=f(x₀), x=x₀, v=options.ub - options.lb)
    result = Result(f(x₀), x₀)

    return current, result, options
end