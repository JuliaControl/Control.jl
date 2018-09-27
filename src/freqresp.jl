"""sys_fr = freqresp(sys, w)

Evaluate the frequency response of a linear system

`w -> C*((iw*im -A)^-1)*B + D`

of system `sys` over the frequency vector `w`."""
function freqresp(sys::LTISystem, w_vec::AbstractVector{S}) where {S<:Real}
    # Create imaginary freq vector s
    if !iscontinuous(sys)
        Ts = sys.Ts == -1 ? 1.0 : sys.Ts
        s_vec = exp.(w_vec*(im*Ts))
    else
        s_vec = im*w_vec
    end
    Tsys = numeric_type(sys)
    T = promote_type(typeof(zero(Tsys)/norm(one(Tsys))), ComplexF32, S)
    sys_fr = Array{T}(length(w_vec), noutputs(sys), ninputs(sys))

    if isa(sys, StateSpace)
        sys = _preprocess_for_freqresp(sys)
    end


    for i=1:length(s_vec)
        # TODO : This doesn't actually take advantage of Hessenberg structure
        # for statespace version.
        sys_fr[i, :, :] .= evalfr(sys, s_vec[i])
    end

    return sys_fr
end

# Implements algorithm found in:
# Laub, A.J., "Efficient Multivariable Frequency Response Computations",
# IEEE Transactions on Automatic Control, AC-26 (1981), pp. 407-408.
function _preprocess_for_freqresp(sys::StateSpace)
    if isempty(sys.A) # hessfact does not work for empty matrices
        return sys
    end
    Tsys = numeric_type(sys)
    TT = promote_type(typeof(zero(Tsys)/norm(one(Tsys))), Float32)

    A, B, C, D = sys.A, sys.B, sys.C, sys.D
    F = hessfact(A)
    H = F[:H]::Matrix{TT}
    T = full(F[:Q])
    P = C*T
    Q = T\B
    StateSpace(H, Q, P, D, sys.Ts)
end


#_preprocess_for_freqresp(sys::TransferFunction) = sys.matrix
#function _preprocess_for_freqresp(sys::TransferFunction)
#    map(sisotf -> _preprocess_for_freqresp(sisotf), sys.matrix)
#end

#_preprocess_for_freqresp(sys::SisoTf) = sys

"""
`evalfr(sys, x)` Evaluate the transfer function of the LTI system sys
at the complex number s=x (continuous-time) or z=x (discrete-time).

For many values of `x`, use `freqresp` instead.
"""
function evalfr(sys::StateSpace{T0}, s::Number) where {T0}
    T = promote_type(T0, typeof(one(T0)*one(typeof(s))/(one(T0)*one(typeof(s)))))
    try
        R = s*I - sys.A
        sys.D + sys.C*((R\sys.B)::Matrix{T})  # Weird type stability issue
    catch
        fill(convert(T, Inf), size(sys))
    end
end

function evalfr(G::TransferFunction{<:SisoTf{T0}}, s::Number) where {T0}
    T = promote_type(T0, typeof(one(T0)*one(typeof(s))/(one(T0)*one(typeof(s)))))
    fr = Array{T}(size(G))
    for j = 1:ninputs(G)
        for i = 1:noutputs(G)
            fr[i, j] = evalfr(G.matrix[i, j], s)
        end
    end
    return fr
end

"""
`F(s)`, `F(omega, true)`, `F(z, false)`

Notation for frequency response evaluation.
- F(s) evaluates the continuous-time transfer function F at s.
- F(omega,true) evaluates the discrete-time transfer function F at exp(i*Ts*omega)
- F(z,false) evaluates the discrete-time transfer function F at z
"""
function (sys::TransferFunction)(s)
    evalfr(sys,s)
end

function (sys::TransferFunction)(z_or_omega::Number, map_to_unit_circle::Bool)
    @assert !iscontinuous(sys) "It makes no sense to call this function with continuous systems"
    if map_to_unit_circle
        isreal(z_or_omega) ? evalfr(sys,exp(im*z_or_omega.*sys.Ts)) : error("To map to the unit circle, omega should be real")
    else
        evalfr(sys,z_or_omega)
    end
end

function (sys::TransferFunction)(z_or_omegas::AbstractVector, map_to_unit_circle::Bool)
    @assert !iscontinuous(sys) "It makes no sense to call this function with continuous systems"
    vals = sys.(z_or_omegas, map_to_unit_circle)# evalfr.(sys,exp.(evalpoints))
    # Reshape from vector of evalfr matrizes, to (in,out,freq) Array
    out = Array{eltype(eltype(vals)),3}(length(z_or_omegas), size(sys)...)
    for i in 1:length(vals)
        out[i,:,:] .= vals[i]
    end
    return out
end

"""`mag, phase, w = bode(sys[, w])`

Compute the magnitude and phase parts of the frequency response of system `sys`
at frequencies `w`

`mag` and `phase` has size `(length(w), ny, nu)`"""
function bode(sys::LTISystem, w::AbstractVector)
    resp = freqresp(sys, w)
    return abs.(resp), rad2deg.(unwrap!(angle.(resp),1)), w
end
bode(sys::LTISystem) = bode(sys, _default_freq_vector(sys, :bode))

"""`re, im, w = nyquist(sys[, w])`

Compute the real and imaginary parts of the frequency response of system `sys`
at frequencies `w`

`re` and `im` has size `(length(w), ny, nu)`"""
function nyquist(sys::LTISystem, w::AbstractVector)
    resp = freqresp(sys, w)
    return real(resp), imag(resp), w
end
nyquist(sys::LTISystem) = nyquist(sys, _default_freq_vector(sys, :nyquist))

"""`sv, w = sigma(sys[, w])`

Compute the singular values of the frequency response of system `sys` at
frequencies `w`

`sv` has size `(length(w), max(ny, nu))`"""
function sigma(sys::LTISystem, w::AbstractVector)
    resp = freqresp(sys, w)
    nw, ny, nu = size(resp)
    sv = Array{Float64}(nw, min(ny, nu))
    for i=1:nw
        sv[i, :] = svdvals(resp[i, :, :])
    end
    return sv, w
end
sigma(sys::LTISystem) = sigma(sys, _default_freq_vector(sys, :sigma))

function _default_freq_vector(systems::Vector{T}, plot::Symbol) where T<:LTISystem
    min_pt_per_dec = 60
    min_pt_total = 200
    nsys = length(systems)
    bounds = Array{Float64}(2, nsys)
    for i=1:nsys
        # TODO : For now we ignore the feature information. In the future,
        # these can be used to improve the frequency vector near features.
        bounds[:, i] = _bounds_and_features(systems[i], plot)[1]
    end
    w1 = minimum(bounds)
    w2 = maximum(bounds)
    nw = round(Int, max(min_pt_total, min_pt_per_dec*(w2 - w1)))
    return exp10.(range(w1, stop=w2, length=nw))
end
_default_freq_vector(sys::LTISystem, plot::Symbol) = _default_freq_vector(
        LTISystem[sys], plot)




function _bounds_and_features(sys::LTISystem, plot::Symbol)
    # Get zeros and poles for each channel
    if plot != :sigma
        zs, ps = zpkdata(sys)
        # Compose vector of all zs, ps, positive conjugates only.
        zp = vcat([vcat(i, j) for (i, j) in zip(zs, ps)]...)
        zp = zp[imag(zp) .>= 0.0]
    else
        # For sigma plots, use the MIMO poles and zeros
        zp = [tzero(sys); pole(sys)]
    end
    # Get the frequencies of the features, ignoring low frequency dynamics
    fzp = log10.(abs.(zp))
    fzp = fzp[fzp .> -4]
    fzp = sort!(fzp)
    # Determine the bounds on the frequency vector
    if !isempty(fzp)
        w1 = floor(fzp[1] - 0.2)
        w2 = ceil(fzp[end] + 0.2)
        # Expand the range for nyquist plots
        if plot == :nyquist
            w1 -= 1
            w2 += 1
        end
    else
        w1 = 0
        w2 = 2
    end
    return [w1, w2], zp
end
