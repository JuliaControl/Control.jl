"""
    add_disturbance(sys::AbstractStateSpace{Continuous}, Ad::AbstractMatrix, Cd::AbstractMatrix)

See CSS pp. 144

# Arguments:
- `sys`: System to augment
- `Ad`: The dynamics of the disturbance
- `Cd`: How the disturbance states affect the states of `sys`. This matrix as the shape (sys.nx, size(Ad, 1))

See also `add_low_frequency_disturbance, add_resonant_disturbance`
"""
function add_disturbance(sys::AbstractStateSpace{Continuous}, Ad::AbstractMatrix, Cd::AbstractMatrix)
    A,B,C,D = ControlSystems.ssdata(sys)
    T = eltype(A)
    nx,nu,ny = sys.nx,sys.nu,sys.ny
    Ae = [A Cd; zeros(T, size(Ad, 1), nx) Ad]
    Be = [B; zeros(T, size(Ad, 1), nu)]
    Ce = [C zeros(T, ny, size(Ad, 1))]
    De = D
    ss(Ae,Be,Ce,De)
end

function add_low_frequency_disturbance(sys::AbstractStateSpace{Continuous}, Ai::Integer)
    nx,nu,ny = sys.nx,sys.nu,sys.ny
    Cd = zeros(nx, 1)
    Cd[Ai] = 1
    add_disturbance(sys, zeros(1,1), Cd)
end

function add_low_frequency_disturbance(sys::AbstractStateSpace{Continuous})
    Cd = sys.B
    add_disturbance(sys, zeros(1,1), Cd)
end

function add_resonant_disturbance(sys::AbstractStateSpace{Continuous}, ω, ζ, Ai::Integer)
    nx,nu,ny = sys.nx,sys.nu,sys.ny
    Cd = zeros(nx, 2)
    Cd[Ai, 1] = 1
    Ad = [-ζ -ω; ω -ζ]
    add_disturbance(sys, Ad, Cd)
end


using ControlSystems.DemoSystems
sys = DemoSystems.resonant()


sys2 = add_low_frequency_disturbance(sys, 2)
sys25 = add_low_frequency_disturbance(sys)
sys3 = add_resonant_disturbance(sys, 1, 0.5, 1)



ss([0], [0], [1], 1)*sys

sys + ss([0.0], [0], [1], 1)