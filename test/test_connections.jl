@testset "test_connections" begin
I2 = Matrix{Float64}(I,2,2)
## STATE SPACE ##
# CONTINUOUS
C_111 = ss([1], [2], [3], [4])
C_211 = ss(I2, [1; 2], [1 0], [0])
C_212 = ss(I2, [1; 2], I2, [0; 0])
C_221 = ss(I2, [1 0; 0 2], [1 0], [0 0])
C_222 = ss(I2, [1 0; 0 2], I2, fill(0,2,2))
C_022 = ss(4*I2)

# DISCRETE
D_111 = ss([1], [2], [3], [4], 0.005)
D_211 = ss(I2, [1; 2], [1 0], [0], 0.005)
D_212 = ss(I2, [1;2], I2, [0; 0], 0.005)
D_221 = ss(I2, [1 0; 0 2], [1 0], [0 0], 0.005)
D_222 = ss(I2, [1 0; 0 2], I2, fill(0,2,2), 0.005)
D_022 = ss(4*I2, 0.005)

@test [C_111 C_221] == ss(Matrix{Float64}(I,3,3), [2 0 0; 0 1 0; 0 0 2], [3 1 0], [4 0 0])
@test [C_111; C_212] == ss(Matrix{Float64}(I,3,3), [2; 1; 2], [3 0 0; 0 1 0; 0 0 1], [4; 0; 0])
@test append(C_111, C_211) == ss(Matrix{Float64}(I,3,3), [2 0; 0 1; 0 2], [3 0 0; 0 1 0], [4 0; 0 0])
@test [C_022 C_222] == ss(I2, [0 0 1 0; 0 0 0 2], [1 0; 0 1], [4 0 0 0; 0 4 0 0])
@test [C_022; C_222] == ss(I2, [1 0; 0 2], [0 0; 0 0; 1 0; 0 1], [4 0; 0 4; 0 0; 0 0])

@test [D_111 D_221] == ss(Matrix{Float64}(I,3,3), [2 0 0; 0 1 0; 0 0 2], [3 1 0], [4 0 0], 0.005)
@test [D_111; D_212] == ss(Matrix{Float64}(I,3,3), [2; 1; 2], [3 0 0; 0 1 0; 0 0 1], [4; 0; 0], 0.005)
@test append(D_111, D_211) == ss(Matrix{Float64}(I,3,3), [2 0; 0 1; 0 2], [3 0 0; 0 1 0], [4 0; 0 0], 0.005)
@test [D_022 D_222] == ss(I2, [0 0 1 0; 0 0 0 2], [1 0; 0 1], [4 0 0 0; 0 4 0 0], 0.005)
@test [D_022; D_222] == ss(I2, [1 0; 0 2], [0 0; 0 0; 1 0; 0 1], [4 0; 0 4; 0 0; 0 0], 0.005)

@test series(C_111, C_212) == C_212*C_111
@test parallel(C_111, C_211) == C_111 + C_211

# Errors
@test_throws ErrorException [C_111 D_111]                 # Sampling time mismatch
@test_throws ErrorException [C_111; D_111]                # Sampling time mismatch
@test_throws ErrorException append(C_111, D_111)          # Sampling time mismatch
@test_throws ErrorException [C_111 C_212]                 # Dimension mismatch
@test_throws ErrorException [C_111; C_221]                # Dimension mismatch

## TRANSFER FUNCTION ##
# CONTINUOUS
Ctf_111 = tf([1, 2], [1, 5])
Ctf_211 = tf([1, 2, 3], [1, 8, 15])
Ctf_212 = tf(vecarray(2, 1, [1, 2, 3], [1, 2]), vecarray(2, 1, [1, 8, 15], [1, 8, 15]))
Ctf_221 = tf(vecarray(1, 2, [1, 2, 3], [1, 2]), vecarray(1, 2, [1, 8, 15], [1, 8, 15]))
Ctf_222 = [Ctf_221; Ctf_221]
Ctf_022 = tf(4*I2)

# DISCRETE
Dtf_111 = tf([1, 2], [1, 5], 0.005)
Dtf_211 = tf([1, 2, 3], [1, 8, 15], 0.005)
Dtf_212 = tf(vecarray(2, 1, [1, 2, 3], [1, 2]), vecarray(2, 1, [1, 8, 15], [1, 8, 15]), 0.005)
Dtf_221 = tf(vecarray(1, 2, [1, 2, 3], [1, 2]), vecarray(1, 2, [1, 8, 15], [1, 8, 15]), 0.005)
Dtf_222 = [Dtf_221; Dtf_221]; Dtf_222.Ts = 0.005
Dtf_022 = tf(4*I2, 0.005)

s = tf("s")
@test [Ctf_111 Ctf_221] == tf(vecarray(1, 3, [1,2], [1,2,3], [0,1,2]),
    vecarray(1, 3, [1,5], [1,8,15], [1,8,15]))
@test [Ctf_111; Ctf_212] == tf(vecarray(3, 1, [1,2], [1,2,3], [0,1,2]),
    vecarray(3, 1, [1,5], [1,8,15], [1,8,15]))
@test append(Ctf_111, Ctf_211) == tf(vecarray(2, 2, [1,2], [0], [0], [1,2,3]),
    vecarray(2, 2, [1,5], [1], [1], [1,8,15]));
@test [Ctf_022 Ctf_222] == tf(vecarray(2, 4, [4], [0], [1,2,3], [0,1,2], [0], [4], [1,2,3], [0,1,2]),
    vecarray(2, 4, [1], [1], [1,8,15], [1,8,15], [1], [1], [1,8,15], [1,8,15]))
@test [Ctf_022; Ctf_222] == tf(vecarray(4, 2, [4], [0], [0], [4], [1,2,3], [0,1,2], [1,2,3], [0,1,2]),
    vecarray(4, 2, [1], [1], [1], [1], [1,8,15], [1,8,15], [1,8,15], [1,8,15]))
@test [Ctf_022 Ctf_022] == [[tf(4) 0;0 4] 4*I2]

@test [Dtf_111 Dtf_221] == tf(vecarray(1, 3, [1,2], [1,2,3], [0,1,2]),
    vecarray(1, 3, [1,5], [1,8,15], [1,8,15]), 0.005)
@test [Dtf_111; Dtf_212] == tf(vecarray(3, 1, [1,2], [1,2,3], [0,1,2]),
    vecarray(3, 1, [1,5], [1,8,15], [1,8,15]), 0.005)
@test append(Dtf_111, Dtf_211) == tf(vecarray(2, 2, [1,2], [0], [0], [1,2,3]),
    vecarray(2, 2, [1,5], [1], [1], [1,8,15]), 0.005);
@test [Dtf_022 Dtf_222] == tf(vecarray(2, 4, [4], [0], [1,2,3], [0,1,2], [0], [4], [1,2,3], [0,1,2]),
    vecarray(2, 4, [1], [1], [1,8,15], [1,8,15], [1], [1], [1,8,15], [1,8,15]), 0.005)
@test [Dtf_022; Dtf_222] == tf(vecarray(4, 2, [4], [0], [0], [4], [1,2,3], [0,1,2], [1,2,3], [0,1,2]),
    vecarray(4, 2, [1], [1], [1], [1], [1,8,15], [1,8,15], [1,8,15], [1,8,15]), 0.005)

@test series(Ctf_111, Ctf_212) == tf(vecarray(2, 1, [1,4,7,6], [0,1,4,4]),
    vecarray(2, 1, [1,13,55,75], [1,13,55,75]));
@test parallel(Ctf_111, Ctf_211) == tf([2,17,44,45], [1,13,55,75])

# Combination tf and ss
@test [C_111 Ctf_221] == [C_111 ss(Ctf_221)]
@test [C_111; Ctf_212] == [C_111; ss(Ctf_212)]
@test append(C_111, Ctf_211) == append(C_111, ss(Ctf_211))
@test [D_111 Dtf_221] == [D_111 ss(Dtf_221)]
@test [D_111; Dtf_212] == [D_111; ss(Dtf_212)]
@test append(D_111, Dtf_211) == append(D_111, ss(Dtf_211))

# Combination tfRational and sisoZpk
Czpk_111 = zpk([-2],[-5],1)
Czpk_211 = zpk([-1+sqrt(2)im,-1-sqrt(2)im], [-5,-3],1)
Czpk_212 = zpk(vecarray(2, 1, [-1+sqrt(2)im,-1-sqrt(2)im], [-2]), vecarray(2, 1, [-5,-3], [-5,-3]), [1;1])
Czpk_221 = zpk(vecarray(1, 2, [-1+sqrt(2)im,-1-sqrt(2)im], [-2]), vecarray(1, 2, [-5,-3], [-5,-3]), [1 1])
Czpk_222 = [Czpk_221; Czpk_221]
Czpk_022 = [zpk([],[],4) 0; 0 zpk([],[],4)]

#Make sure that we get a vector
arr = Array{TransferFunction{ControlSystems.SisoZpk},1}(2)
arr[1] = zpk(tf(1)); arr[2] = zpk(2);
@test [tf(1), zpk(2)] == arr
arr2 = Array{TransferFunction{ControlSystems.SisoRational},1}(2)
arr2[1] = tf(1, 0.1); arr2[2] = tf(2, 0.1);
@test [tf(1, 0.1), tf(2, 0.1)] == arr2
arr3 = Array{StateSpace,1}(3)
arr3[1] = ss(0); arr3[2] = ss(1); arr3[3] = ss(2)
@test [0, zpk(1), ss(2)] == arr3

@test Czpk_111 ≈ Ctf_111
@test Czpk_211 ≈ Ctf_211
@test Czpk_212 ≈ Ctf_212
@test Czpk_221 ≈ Ctf_221
@test Czpk_222 ≈ Ctf_222
@test Czpk_022 ≈ Ctf_022

@test Czpk_222 ≈ [Ctf_221; Czpk_221]

#This might fail depending on if minreal is used or not
@test (Czpk_211+1) ≈ (Ctf_211+1)
end
