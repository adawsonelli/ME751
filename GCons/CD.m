classdef CD
    %CD implements the Coordinate Difference constraint,
    %using the r-p formulation. The CD constraint exists
    %between 2 points on 2 different bodies:
    %   -point P on body i 
    %   -point Q on body j
    %the CD constraint specifies that for the given coordinate in the set
    %[x,y,z], the difference between that coordinates value for point P and
    %Point Q assumes a specified value 
        
    
    properties
        fisFunction;
        ID;              %should the ID be used to populate the jacobian?
        DOFremoved = 1;  %DOF removed
        constType;       % 'd' specifies driving, 'k' specifies kinematic
        bodyi;           %body I
        bodyj;           %body J
        Pi;              %index of point P on body i, which participates in constraint
        Qj;              %index of point Q on body J, which participates in constraint
        Ft;              %forcing function, constraint is driven in nozero, kinematic if otherwise
        Ftdot;           %derivative of forcing function
        Ftddot;          %2nd derivative of forcing function
        COI;             %coordinate of interest, specified as from the set ['x','y','z']
        c;               %coordinate of interest as a vector
        t;               %local copy of the current time step
    end
    
    
    properties(Dependent)
        %these represent the outputs that a calling function
        %may request of the CD constraint, made by a getter;
        
       
        nu;              %RHS of the velocity equation
        gamma;           %RHS of the acceleration equation
        phi;             %constraint equation
        phi_ri;          %partial derivative of phi wrt ri
        phi_rj;          %partial derivative of phi wrt rj
        phi_pi;          %partial derivative of phi wrt pi
        phi_pj;          %partial derivative of phi wrt pj
      
        
    end
    
    
    methods
        %constructor
        function cd = CD(bodyi,bodyj,Pi,Qj,COI,t,Ft,Ftdot,Ftddot) %default constructor
            %ensure essential arguments are specified
             if ~exist('bodyi') || ~exist('bodyj')
                 error('must specify bodies i and j')
             end
             if ~exist('Pi', 'var') || ~exist('Qj', 'var')
                 error('must specify point indexies Pi and Qj')
             end
             
            %error if body and points not properly specified
            if ~isa(bodyi,'Body') || isa(bodyj,'Body')
                error('body i and j must be type body')
            end
            if (Pi < bodyi.nMarkers) || (Qj < bodyj.nMarkers)
                error('point index out of range')
            end
            
            %handle sparce input gracefully
            if ~exist('Ft','var')
                Ft = 0;
            end
            if ~exist('Ftdot','var')
                Ftdot = 0;
            end
            if ~exist('Ftddot','var')
                Ftddot = 0;
            end
            
            %classify constraint as as driving or kinmatic
            if Ft==0 & Ftdot==0 & ftddot==0
                constType ='k'  %kinematic
            else
                constType = 'd' %driving   
            end
            
            
            %assign input to properties
            cd.bodyi = bodyi;           %body I
            cd.bodyj = bodyj;           %body J
            cd.Pi = Pi;                 %index of point P on body i, which participates in constraint
            cd.Qj = Qj;                 %index of point Q on body J, which participates in constraint
            cd.Ft = Ft;                 %forcing function, constraint is driven in nozero, kinematic if otherwise
            cd.Ftdot = Ftdot;           %derivative of forcing function
            cd.Ftddot = Ftddot;         %2nd derivative of forcing function
            cd.COI =COI;                %coordinate of interest, specified as from the set ['x','y','z']
            cd.c = cd.COI2C(COI);       %store coordinate longterm in vector form to avoid computation
            cd.t = t;                   %present discrete time step 
        end
        
        %-----------------------getters-----------------------------------
        
        function phi = get.phi(cd)
            %phi is the constraint equation associated with this CD constraint 
            %dim phi = [1x1]
            %equation from haug __ and 9.26 p.20
            
            ri  = (cd.bodyj.r +cd.bodyj.A*cd.bodyj.markers{cd.Qj});
            rj  = (cd.bodyi.r +cd.bodyi.A*cd.bodyi.markers{cd.Pi});
            dij = rj-ri; 
            phi = cd.c'*dij  - Ft;
        end
        
        function nu = get.nu(cd)
            nu = Ftdot
        end
        
        function gamma = get.gamma(cd)
            %gamma is the RHS of the acceleration equation.
            %dim gamma = [1x1]
            %formula from S8 lecture 10.16
            gamma = cd.c'*bodyi.Bpdot(Pi)*bodyi.pdot ...
                  - cd.c'*bodyj.Bpdot(Qj)*bodyj.pdot  + ftddot;
            
            
        end
        
        function phi_ri = get.phi_ri(cd)
            %phi_ri is the partial derivative of phi wrt the positional
            %coordinates of body i. phi_ri is a [1x3] matrix if body i is
            %free (not ground) and is a [0x0] matrix if body i is ground
            %these formula were taken from S17, 9.28 lecture
            if cd.bodyi.isGround
                phi_ri = [];
            else %body is free
                phi_ri = cd.c'
            end
        end
        
        function phi_ri = get.phi_rj(cd)
            %see above for documentation
            if cd.bodyj.isGround
                phi_rj = [];
            else %body is free
                phi_rj = cd.c'
            end
        end
        
        function phi_pi = get.phi_pi(cd)
            %phi_pi is the derivative of phi wrt the orientational
            %coordinates of body i. phi_pi is a [1x4] vector when body i is
            %free, and a [0x0] vector if body i is ground. these formulas
            %were taken from S17 9.28 lecture
            if bodyi.isground
                phi_pi = [];
            else
                phi_pi = -cd.c'*bodyi.Bp(Pi);
            end
        end
        
        function phi_pj = get.phi_pj(cd)
            %look above for documentation
            if bodyj.isground
                phi_pj = [];
            else
                phi_pj = cd.c'*bodyj.Bp(Qj);
            end
            
        end
  
    end  
        
        methods (Access = private)
            function c = COI2C(COI)
                %input: 
                    %COI [string]
                %output:
                    %[3x1] unit vector
                switch COI
                    case 'x'
                        c = [1 0 0]';
                    case 'y'
                        c = [0 1 0]';
                    case 'z'
                        c = [0 0 1]';
                    otherwise
                        error('coordinate of interest improperly specified')
                end
                    
            end
                
            
        end
end
    
