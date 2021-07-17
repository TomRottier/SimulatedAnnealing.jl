module SimulatedAnnealing

using Distributed:Worker
using Distributed, ParallelDataTransfer

include("types.jl")
include("functions.jl")

export Options, Result, State, sa!


function sa!(current::State, result::Result, options::Options)
    # Check if running on multiple proccesses
    parallel = nworkers() > 1

    # Check number of workers is multiple of Ns
    rem(options.Ns, nworkers()) !== 0 && error("Number of workers must be multiple of Ns")

    # Print intial status
    print_intitial(current, options, parallel)

    # Negate inital f if trying to minimise
    !options.max && (current.f *= -1, result.fopt *= -1)

    # Initialise workers
    if parallel
        @everywhere workers() begin 
            current, result, options = $current, $result, $options
            options.Ns /= nworkers()    # Divide Ns equally between workers
        end
    end

    # Initialise best array
    bests = Vector{Float64}(undef, options.Ne)
    bests .= -Inf       # Always maximising so -Inf lowest possible

    # Simulated annealing loop
    while true
        # Get previous bests to check for termination
        bests = circshift(bests, 1)
        bests[1] = result.fopt

        # Main loop
        parallel ? paraloopNt!(current, result, options) : loopNt!(current, result, options)

        # Get results and check improvement
        check_improvement!(bests, result, options.tol)

        # Terminate or reduce temperature
        check_termination(result) ? break : reduce_temp!(current, options)
        
        # Print results after temperature reduction
        options.print_status && print_status(current, result, options)

        println(bests)
    end

    # Negate f if trying to minimise
    !options.max && (result.fopt *= -1)

    # Terminated
    print_termination(current, result, options)

    return nothing
end

end