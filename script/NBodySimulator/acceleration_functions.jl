
using BenchmarkTools, NBodySimulator
using StaticArrays

const SUITE = BenchmarkGroup();


using NBodySimulator: gravitational_acceleration!, gather_bodies_initial_coordinates

let SUITE=SUITE
    G = 6.67e-11 # m^3/kg/s^2
    N = 200 # number of bodies/particles
    m = 1.0 # mass of each of them
    v = 10.0 # mean velocity
    L = 20.0 # size of the cell side

    bodies = generate_bodies_in_cell_nodes(N, m, v, L)
    g_parameters = GravitationalParameters(G)
    system = PotentialNBodySystem(bodies, Dict(:gravitational => g_parameters))
    tspan = (0.0, 1.0)
    simulation = NBodySimulation(system, tspan)

    u0, v0, n = gather_bodies_initial_coordinates(simulation)
    dv = zero(v0)
    i = 1

    b = @benchmarkable gravitational_acceleration!(dv, $u0, $i, $N, $bodies,
        $g_parameters) setup=(dv=zero($v0)) evals=1

    SUITE["gravitational"] = b
end


using NBodySimulator: pairwise_electrostatic_acceleration!, obtain_data_for_electrostatic_interaction

let SUITE=SUITE
    n = 200
    bodies = ChargedParticle[]
    L = 20.0
    m = 1.0
    q = 1.0
    count = 1
    dL = L / (ceil(n^(1 / 3)) + 1)
    for x = dL / 2:dL:L, y = dL / 2:dL:L, z = dL / 2:dL:L
        if count > n
            break
        end
        r = SVector(x, y, z)
        v = SVector(.0, .0, .0)
        body = ChargedParticle(r, v, m, q)
        push!(bodies, body)
        count += 1
    end

    k = 9e9
    τ = 0.01 * dL / sqrt(2 * k * q * q / (dL * m))
    t1 = 0.0
    t2 = 1000 * τ

    potential = ElectrostaticParameters(k, 0.45 * L)
    system = PotentialNBodySystem(bodies, Dict(:electrostatic => potential))
    pbc = CubicPeriodicBoundaryConditions(L)
    simulation = NBodySimulation(system, (t1, t2), pbc)

    i = 1
    u0, v0, n = gather_bodies_initial_coordinates(simulation)
    dv = zero(v0)

    qs, ms, indxs, exclude = obtain_data_for_electrostatic_interaction(simulation.system)

    b = @benchmarkable pairwise_electrostatic_acceleration!(dv, $u0, $i, length($indxs), $qs, $ms,
        $exclude, $potential, $pbc) setup=(dv=zero($v0)) evals=1

    SUITE["coulomb"] = b
end


using NBodySimulator: magnetostatic_dipdip_acceleration!

let SUITE=SUITE
    n = 200
    bodies = MagneticParticle[]
    L = 20.0
    m = 1.0
    count = 1
    dL = L / (ceil(n^(1 / 3)) + 1)
    for x = dL / 2:dL:L, y = dL / 2:dL:L, z = dL / 2:dL:L
        if count > n
            break
        end
        r = SVector(x, y, z)
        v = SVector(.0, .0, .0)
        mm = rand(SVector{3})
        body = MagneticParticle(r, v, m, mm)
        push!(bodies, body)
        count += 1
    end

    μ_4π = 1e-7
    t1 = 0.0  # s
    t2 = 1.0 # s
    τ = (t2 - t1) / 100

    parameters = MagnetostaticParameters(μ_4π)
    system = PotentialNBodySystem(bodies, Dict(:magnetic => parameters))
    simulation = NBodySimulation(system, (t1, t2))

    i = 1
    u0, v0, n = gather_bodies_initial_coordinates(simulation)
    dv = zero(v0)

    b = @benchmarkable magnetostatic_dipdip_acceleration!(dv, $u0, $i, $n, $bodies,
        $parameters) setup=(dv=zero($v0)) evals=1

    SUITE["magnetic_dipole"] = b
end


using NBodySimulator: obtain_data_for_lennard_jones_interaction, pairwise_lennard_jones_acceleration!

let SUITE=SUITE
    T = 120.0 # K
    T0 = 90.0 # K
    kb = 8.3144598e-3 # kJ/(K*mol)
    ϵ = T * kb
    σ = 0.34 # nm
    ρ = 1374/1.6747# Da/nm^3
    N = 200
    m = 39.95# Da = 216 # number of bodies/particles
    L = (m*N/ρ)^(1/3)#10.229σ
    R = 0.5*L
    v_dev = sqrt(kb * T / m)
    bodies = generate_bodies_in_cell_nodes(N, m, v_dev, L)

    τ = 0.5e-3 # ps or 1e-12 s
    t1 = 0.0
    t2 = 2000τ

    lj_parameters = LennardJonesParameters(ϵ, σ, R)
    lj_system = PotentialNBodySystem(bodies, Dict(:lennard_jones => lj_parameters));

    pbc = CubicPeriodicBoundaryConditions(L)
    simulation = NBodySimulation(lj_system, (t1, t2), pbc, kb)

    ms, indxs = obtain_data_for_lennard_jones_interaction(lj_system)
    u0, v0, n = gather_bodies_initial_coordinates(simulation)
    dv = zero(v0)
    i = 1

    b = @benchmarkable pairwise_lennard_jones_acceleration!(dv, $u0, $i, $indxs, $ms,
        $lj_parameters, $simulation.boundary_conditions) setup=(dv=zero($v0)) evals=1

    SUITE["lennard_jones"] = b
end


using NBodySimulator: harmonic_bond_potential_acceleration!, obtain_data_for_harmonic_bond_interaction

let SUITE=SUITE
    T = 370 # K
    T0 = 275 # K
    kb = 8.3144598e-3 # kJ/(K*mol)
    ϵOO = 0.1554253*4.184 # kJ
    σOO = 0.3165492 # nm
    ρ = 997/1.6747# Da/nm^3
    mO = 15.999 # Da
    mH = 1.00794 # Da
    mH2O = mO+2*mH
    N = 200
    L = (mH2O*N/ρ)^(1/3)
    R = 0.9 # ~3*σOO
    Rel = 0.49*L
    v_dev = sqrt(kb * T /mH2O)
    τ = 0.5e-3 # ps
    t1 = 0τ
    t2 = 5τ # ps
    k_bond = 1059.162*4.184*1e2 # kJ/(mol*nm^2)
    k_angle = 75.90*4.184 # kJ/(mol*rad^2)
    rOH = 0.1012 # nm
    ∠HOH = 113.24*pi/180 # rad
    qH = 0.41
    qO = -0.82
    k = 138.935458 #
    bodies = generate_bodies_in_cell_nodes(N, mH2O, v_dev, L)
    jl_parameters = LennardJonesParameters(ϵOO, σOO, R)
    e_parameters = ElectrostaticParameters(k, Rel)
    spc_parameters = SPCFwParameters(rOH, ∠HOH, k_bond, k_angle)
    pbc = CubicPeriodicBoundaryConditions(L)
    water = WaterSPCFw(bodies, mH, mO, qH, qO,  jl_parameters, e_parameters, spc_parameters);
    simulation = NBodySimulation(water, (t1, t2), pbc, kb);

    ms, neighbouhood = obtain_data_for_harmonic_bond_interaction(simulation.system, spc_parameters)
    u0, v0, n = gather_bodies_initial_coordinates(simulation)
    dv = zero(v0)
    i = 1

    b = @benchmarkable harmonic_bond_potential_acceleration!(dv, $u0, $i, $ms, $neighbouhood,
        $spc_parameters) setup=(dv=zero($v0)) evals=1

    SUITE["harmonic_bond"] = b
end


using NBodySimulator: valence_angle_potential_acceleration!, obtain_data_for_lennard_jones_interaction

let SUITE=SUITE
    T = 370 # K
    T0 = 275 # K
    kb = 8.3144598e-3 # kJ/(K*mol)
    ϵOO = 0.1554253*4.184 # kJ
    σOO = 0.3165492 # nm
    ρ = 997/1.6747# Da/nm^3
    mO = 15.999 # Da
    mH = 1.00794 # Da
    mH2O = mO+2*mH
    N = 200
    L = (mH2O*N/ρ)^(1/3)
    R = 0.9 # ~3*σOO
    Rel = 0.49*L
    v_dev = sqrt(kb * T /mH2O)
    τ = 0.5e-3 # ps
    t1 = 0τ
    t2 = 5τ # ps
    k_bond = 1059.162*4.184*1e2 # kJ/(mol*nm^2)
    k_angle = 75.90*4.184 # kJ/(mol*rad^2)
    rOH = 0.1012 # nm
    ∠HOH = 113.24*pi/180 # rad
    qH = 0.41
    qO = -0.82
    k = 138.935458 #
    bodies = generate_bodies_in_cell_nodes(N, mH2O, v_dev, L)
    jl_parameters = LennardJonesParameters(ϵOO, σOO, R)
    e_parameters = ElectrostaticParameters(k, Rel)
    spc_parameters = SPCFwParameters(rOH, ∠HOH, k_bond, k_angle)
    pbc = CubicPeriodicBoundaryConditions(L)
    water = WaterSPCFw(bodies, mH, mO, qH, qO,  jl_parameters, e_parameters, spc_parameters);
    simulation = NBodySimulation(water, (t1, t2), pbc, kb);

    ms, indxs = obtain_data_for_lennard_jones_interaction(simulation.system)
    u0, v0, n = gather_bodies_initial_coordinates(simulation)
    dv = zero(v0)
    i = 1

    b = @benchmarkable valence_angle_potential_acceleration!(dv, $u0,
        3 * ($i - 1) + 2, 3 * ($i - 1) + 1, 3 * ($i - 1) + 3, $ms,
        $spc_parameters) setup=(dv=zero($v0)) evals=1

    SUITE["valence_angle"] = b
end


r = run(SUITE)

minimum(r)


memory(r)

