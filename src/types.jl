# Optimisation parameters
mutable struct Options{F <: Function}
    f::F                    # Function to optimise
    N::Int64                # Dimension of x
    Ns::Int64               # Number of cycles before step length adjustment
    Nt::Int64               # Number of cycles before temperature reduction/termination check
    Ne::Int64               # Number of temperature reductions without increase > tol before terminating
    lb::Vector{Float64}     # Lower bound of x
    ub::Vector{Float64}     # Upper bound of x 
    R::Float64              # Temperature reduction factor
    c::Vector{Float64}      # Step length adjustment factor
    max::Bool               # Maximise/minimise function
    tol::Float64            # Tolerance of improvement on cost
    max_eval::Int64         # Maximum number of evaluations before termination
    print_status::Bool      # true if print status at each temp reduction
end
# Default constructor
function Options(;func=f, 
                  N=9, 
                  Ns=20,
                  Nt=10,
                  Ne=4,
                  lb=repeat([-10.0], N),
                  ub=repeat([10.0], N),
                  R=0.75,
                  c=repeat([2.0], N),
                  max=false,
                  tol=1e-6,
                  max_eval=1_000_000,
                  print_status=false)

    return Options(func, N, Ns, Nt, Ne, lb, ub, R, c, max, tol, max_eval, print_status)
end

# Result of optimisation 
mutable struct Result
    fopt::Float64
    xopt::Vector{Float64}
    terminate::Symbol           # Termination code
    n_moves::Int64              # Total number of moves
    n_accepted::Int64           # Total number of accepted points
    n_optimums::Int64           # Total number of global optimums found

    Result(fopt, xopt) = new(fopt, xopt, :none, 0, 0, 0)
end
# Default constructor
function Result(;fopt=3208,
                 xopt=repeat([2.0], 9))    
    return Result(fopt, copy(xopt))
end

# Current state of optimisation 
mutable struct State
    f::Float64                   # Current f
    x::Vector{Float64}           # Current x
    v::Vector{Float64}           # Current step length
    T::Float64                   # Current temperature
    n_accepted::Vector{Float64}  # Number of accepted points for current step length (reset after every step length adjustment)
    ftemp::Float64
    xtemp::Vector{Float64}

    State(f, x, v, T) = new(f, x, v, T, zeros(Int64, length(x)), 0.0, zeros(length(x)))
end
# Default constructor
function State(;f=3208,
                x=repeat([2.0], 9),
                v=repeat([2.0], 9),
                T=1.0)
    return State(f, copy(x), copy(v), T)
end

Base.copy(state::State) = State(state.f, state.x, state.v, state.T)
Base.copy(result::Result) = Result(result.fopt, result.xopt)
Base.copy(options::Options) = Options(options.f, options.N, options.Ns, options.Nt, options.Ne, options.lb, options.ub, options.R, options.c, options.max, options.tol, options.max_eval, options.print_status)

Base.show(io::IO, state::State) = print(io, 
"State: 
    f: $(state.f)
    x: $(state.x)
    v: $(state.v)
    T: $(state.T)"
)

# function Base.show(io::IO, state::State)
#     compact = get(io, :compact, false)

#     if compact
#         print(io, 
#         "State:
#             f: $(state.f)
#             x: [$(state.x[1]), $(state.x[2]), ... , $(state.x[end - 1]), $(state.x[end])]
#             v: [$(state.v[1]), $(state.v[2]), ... , $(state.v[end - 1]), $(state.v[end])]
#             T: $(state.T)"
#         )
#     else
#         print(io, 
#         "State: 
#             f: $(state.f)
#             x: $(state.x)
#             v: $(state.v)
#             T: $(state.T)"
#         )
#     end
# end

# Base.show(io::IO, ::MIME"text/plain", state::State) = print(io, state)
        
Base.show(io::IO, result::Result) = print(io, 
"Result:
    fopt: $(result.fopt)
    xopt: $(result.xopt)
    n moves: $(result.n_moves)
    n accepted: $(result.n_accepted)
    n optimums: $(result.n_optimums)")

Base.show(io::IO, options::Options) = print(io, 
"Options:
    f: $(options.f)
    N: $(options.N)
    Ns: $(options.Ns)
    Nt: $(options.Nt)
    Ne: $(options.Ne)
    lb: $(options.lb)
    ub: $(options.ub)
    R: $(options.R)
    c: $(options.c)
    max: $(options.max)
    tol: $(options.tol)
    max_eval: $(options.max_eval)
    print_status: $(options.print_status)")    
