using Test, Distributed

addprocs(4)
@everywhere begin
    using SimulatedAnnealing, ParallelDataTransfer
    # current, result, options = State(), Result(), Options(Ns=5)
end
# println(result)

current, result, options = SimulatedAnnealing.init(4)
options.print_status = true
@time sa!(current, result, options)


@testset verbose = true "All" begin
    
# Test collect_results!
# @testset verbose = true "collect_results" begin
#     current.x = [2.5,2.5,2.5,2.5]; current.f = -options.f(current.x)
#     result.fopt = current.f; result.xopt = current.x
#     @everywhere [2] current.x, current.f = [2,2,2,2], -options.f([2,2,2,2])
#     @everywhere [3] current.x, current.f = [3,3,3,3], -options.f([3,3,3,3])
#     @everywhere [4] current.x, current.f = [4,4,4,4], -options.f([4,4,4,4])
#     @everywhere [5] current.x, current.f = [5,5,5,5], -options.f([5,5,5,5])

#     SimulatedAnnealing.collect_results!(current, result)
#     @test all(current.x .== [2,2,2,2])
# 




end