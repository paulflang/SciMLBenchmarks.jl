
using DelayDiffEq, DiffEqDevTools, DiffEqProblemLibrary.DDEProblemLibrary
DDEProblemLibrary.importddeproblems()

const prob = DDEProblemLibrary.prob_dde_DDETST_A1
const sol = solve(prob, MethodOfSteps(Vern9()); dtmax = 0.1, reltol = 1e-14, abstol = 1e-14)
const test_sol = TestSolution(sol)

using Plots
gr()
plot(sol)


function buildWorkPrecisionSet(algs, abstols, reltols; kwargs...)
    setups = [Dict(:alg => MethodOfSteps(alg)) for alg in algs]
    names = nameof.(typeof.(algs))

    WorkPrecisionSet(prob, abstols, reltols, setups;
                     names = names, appxsol = test_sol, maxiters = Int(1e5), kwargs...)
end


abstols = @. 1.0 / 10.0^(4:7)
reltols = @. 1.0 / 10.0^(1:4)
algs = [BS3(), Tsit5(), RK4(), DP5(), OwrenZen3(), OwrenZen4(), OwrenZen5()]

wp = buildWorkPrecisionSet(algs, abstols, reltols; error_estimate = :final)
plot(wp)


abstols = @. 1.0 / 10.0^(4:7)
reltols = @. 1.0 / 10.0^(1:4)
algs = [BS3(), Tsit5(), RK4(), DP5(), OwrenZen3(), OwrenZen4(), OwrenZen5()]

wp = buildWorkPrecisionSet(algs, abstols, reltols; error_estimate = :L2)
plot(wp)


abstols = @. 1.0 / 10.0^(8:11)
reltols = @. 1.0 / 10.0^(5:8)
algs = [BS3(), Tsit5(), RK4(), DP5(), OwrenZen3(), OwrenZen4(), OwrenZen5()]

wp = buildWorkPrecisionSet(algs, abstols, reltols; error_estimate = :final)
plot(wp)


abstols = @. 1.0 / 10.0^(8:11)
reltols = @. 1.0 / 10.0^(5:8)
algs = [BS3(), Tsit5(), RK4(), DP5(), OwrenZen3(), OwrenZen4(), OwrenZen5()]

wp = buildWorkPrecisionSet(algs, abstols, reltols; error_estimate = :L2)
plot(wp)


abstols = @. 1.0 / 10.0^(4:7)
reltols = @. 1.0 / 10.0^(1:4)
algs = [Vern6(), Vern7(), Vern8(), Vern9(), OwrenZen4()]

wp = buildWorkPrecisionSet(algs, abstols, reltols; error_estimate = :final)
plot(wp)


abstols = @. 1.0 / 10.0^(4:7)
reltols = @. 1.0 / 10.0^(1:4)
algs = [Vern6(), Vern7(), Vern8(), Vern9(), OwrenZen4()]

wp = buildWorkPrecisionSet(algs, abstols, reltols; error_estimate = :L2)
plot(wp)


abstols = @. 1.0 / 10.0^(8:11)
reltols = @. 1.0 / 10.0^(5:8)
algs = [Vern6(), Vern7(), Vern8(), Vern9(), OwrenZen4()]

wp = buildWorkPrecisionSet(algs, abstols, reltols; error_estimate = :final)
plot(wp)


abstols = @. 1.0 / 10.0^(8:11)
reltols = @. 1.0 / 10.0^(5:8)
algs = [Vern6(), Vern7(), Vern8(), Vern9(), OwrenZen4()]

wp = buildWorkPrecisionSet(algs, abstols, reltols; error_estimate = :L2)
plot(wp)


using DiffEqBenchmarks
DiffEqBenchmarks.bench_footer(WEAVE_ARGS[:folder], WEAVE_ARGS[:file])

