type RSDA    #10.7 slide 22
  """
  A Rotational Spring-Damper-Actuator is a torque generating component which
  acts between body i and j, in proportion to the angular displacement between
  vectors bj and bi. It is frequently associated with a revolute joint
  """
  sim::Sim      #reference to the simulation data structures
  bodyi::Body   #bodyi
  bodyj::Body   #bodyj
  #ai and aj must both be parellel to revolute joint axis, and opposite in sense
  ai_head::Int64  #index of head of a on body i
  ai_tail::Int64  #index of tail of a on body i
  aj_head::Int64  #index of head of a on body j
  aj_tail::Int64  #index of tail of a on body j
  #bi and bj define the angle Θij
  bi_head::Int64  #index of head of a on body i
  bi_tail::Int64  #index of tail of a on body i
  bj_head::Int64  #index of head of a on body j
  bj_tail::Int64  #index of tail of a on body j

  k             #stiffness of the spring
  Θ₀            #resting length of the spring
  c             #damping coefficient
  h             #function handle for the actuator


  #constructor function
  function RSDA(sim::Sim,bodyi::Body,bodyj::Body,ai_head,aj_head,bi_head,bj_head,k=0,Θ₀ = 0,c = 0,h = (Θij,Θijdot,t)->0,ai_tail = 1,aj_tail = 1,bi_tail = 1, bj_tail = 1 )
    new(sim,bodyi,bodyj,ai_head,ai_tail,aj_head,aj_tail,bi_head,bi_tail,bj_head,bj_tail,k,Θ₀,c,h)
  end
end

#----------------begin functions associated with RSDA---------------------------
aibar(rsda::RSDA) = pt(rsda.bodyi, rsda.ai_head) - pt(rsda.bodyi, rsda.ai_tail)
ajbar(rsda::RSDA) = pt(rsda.bodyj, rsda.aj_head) - pt(rsda.bodyj, rsda.aj_tail)
bibar(rsda::RSDA) = pt(rsda.bodyi, rsda.bi_head) - pt(rsda.bodyi, rsda.bi_tail)
bjbar(rsda::RSDA) = pt(rsda.bodyj, rsda.bj_head) - pt(rsda.bodyj, rsda.bj_tail)

function Θij(rsda::RSDA) #9.2.31 haug , p328
  Ai = A(rsda.bodyi) ; Aj = A(rsda.bodyj)
  cΘ =  bibar(rsda)'*Ai'*Aj*bjbar(rsda)
  sΘ =  aibar(rsda)'*tilde(bibar(rsda))*Ai'*Aj*bjbar(rsda)
  cΘ = cΘ[1] ; sΘ = sΘ[1] #convert from  1x1 array to float
  if (sΘ >= 0) && (cΘ >= 0)
    Θ = asin(sΘ)
  end
  if (sΘ >= 0) && (cΘ < 0)
    Θ = pi - asin(sΘ)
  end
  if (sΘ <  0) && (cΘ < 0)
    Θ = pi - asin(sΘ)
  end
  if (sΘ <  0) && (cΘ >= 0)
    Θ = 2*pi + asin(sΘ)
  end
  return Θ
end

function Θijdot(rsda::RSDA) #11.4.14 haug p.449
  Θdot = -aibar(rsda)'*(A(rsda.bodyi)'*A(rsda.bodyj)*2*E(rsda.bodyi)*p(rsda.bodyi) - 2*E(rsda.bodyj)*pdot(rsda.bodyj))
end

"""scalar torque generated by the tsda element as a function of position, velocity, time"""
function nbar(rsda::RSDA)
  rsda.k*(Θij(rsda) - rsda.Θ₀) + rsda.c*Θijdot(rsda) + rsda.h(Θij(rsda), Θijdot(rsda), rsda.sim.t)
end

"""[3x1] torques experienced about the revolute joint axis by bodyi and bodyj"""
nbari(rsda::RSDA) = nbar(rsda)[1] *  aibar(rsda)/norm(aibar(rsda))
nbarj(rsda::RSDA) = nbar(rsda)[1] *  ajbar(rsda)/norm(aibar(rsda))  # aibar = -ajbar
