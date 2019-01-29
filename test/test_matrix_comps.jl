@testset "test_matrix_comps" begin
A = [-0.21 0.2; 0.2 -0.21]
B = 0.01*[1 0; 0 1]
C = [1 0; 0 1]
D = 0
sys = ss(A,B,C,D)
sysr, G = balreal(sys)

@test gram(sysr, :c) ≈ G
@test gram(sysr, :o) ≈ G
@test sort(pole(sysr)) ≈ sort(pole(sys))

sysb,T = ControlSystems.balance_statespace(sys)
Ab,Bb,Cb,T = ControlSystems.balance_statespace(A,B,C)

@test Ab*T ≈ T*A
@test Bb ≈ T*B
@test Cb*T ≈ C

@test sysb.A ≈ Ab

@test ControlSystems.balance_transform(A,B,C) ≈ ControlSystems.balance_transform(sys)

W = [1 0; 0 1]
@test covar(sys, W) ≈ [0.002560975609756 0.002439024390244; 0.002439024390244 0.002560975609756]
D2 = [1 0; 0 1]
@test covar(ss(A,B,C,D2, 1), W) ≈ [1.000110108378310 -0.000010098377310; -0.000010098377310 1.000110108378310]
# Direct term means infinite covariance
@test covar(ss(A,B,C,D2), W) ≈ [Inf Inf; Inf Inf]

# No noise on second output should give finite variance
@test covar(ss(A,B,C,[1 0; 0 0]), W) ≈ [Inf Inf; Inf 0.002560975609756]

# Unstable system has inf covar
@test covar(ss([1 0; 0 1],B,C,0), W) == [Inf Inf; Inf Inf]

# Discrete system can have direct term
@test covar(ss(A,B,C,D2,0.1),W) ≈ [1.00011010837831 -1.0098377309782909e-5; -1.0098377309782909e-5 1.00011010837831]

# TODO test in Julia 0.7 to see if supported
# # Test special matrices
As = sparse(A)
Bs = sparse(B)
Cs = sparse(C)
Asb,Bsb,Csb,Ts = ControlSystems.balance_statespace(As,Bs,Cs) #Error no LAPACK function
#
# @test Abs*Ts ≈ Ts*As
# @test Bbs ≈ Ts*Bs
# @test Cbs*Ts ≈ Cs

# Test special values
Ar = rationalize.(A)
Br = rationalize.(B)
Cr = rationalize.(Float64.(C))    # When did ever rationalize work on Int?
Arb,Brb,Crb,Tr = ControlSystems.balance_statespace(Ar,Br,Cr)

@test Arb*Tr ≈ Tr*Ar
@test Brb ≈ Tr*Br
@test Crb*Tr ≈ Cr

Tr = randn(2,2)
syst = similarity_transform(sys, Tr)
@test sys.A*Tr ≈ Tr*syst.A
@test sys.B ≈ Tr*syst.B
@test sys.C*Tr ≈ syst.C

sys = ss(eye_(2), ones(2), ones(1,2), 0, 1)
sysi = ControlSystems.innovation_form(sys, I, I)
@test sysi.A ≈ [-3.5 -4.5; 1.5 2.5]
@test sysi.B ≈ [4.5; -1.5]

end
