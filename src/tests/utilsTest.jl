#test cases for the utils functions:

@testset "utilTests" begin

  @testset "rotation functions" begin
    @test SE.P2A(SE.A2P(eye(3))) == eye(3)
    theta = pi/4*cos(2*0) #initial configuration
    rot = SE.Ry(pi/2)*SE.Rz(theta)
    @test SE.P2A(SE.A2P(rot)) ≈ rot
  end

  @testset "insertUL!" begin
    #insert ul tests:
    A = eye(4);
    h = [2 2; 2 2];
    SE.insertUL!(A,h,(3,3))
    result = [1 0 0 0;
              0 1 0 0;
              0 0 2 2;
              0 0 2 2 ];
    @test A == result

    #insert into a 1D matri
    q_examp = [0 0 0 0 0 0 0]'
    h = [1 2 3]'
    SE.insertUL!(q_examp,h,(1,1))
    @test q_examp == [1 2 3 0 0 0 0]'
  end

end
