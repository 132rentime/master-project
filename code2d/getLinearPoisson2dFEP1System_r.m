function [A, rhs] = getLinearPoisson2dFEP1System_r(geometry, domain, mesh, ...
    K, f, BCs_t, BCs_v, BCe_t, BCe_v, BCn_t, BCn_v, BCw_t, BCw_v)
    % Shortcuts
    nodes = mesh.nodes;  elems = mesh.elems;
    Nn = mesh.getNumNodes();  Ne = mesh.getNumElems();
    
    % Store gradients of basis functions on reference triangle
    gr1 = [-1 -1]';  gr2 = [1 0]';  gr3 = [0 1]';
    
    % Quadrature nodes and weights
    % A three-points Gauss quadrature rule is used, but it may easily
    % changed by accordingly changed the nodes and the weights
    q1 = [1/6 1/6]';  q2 = [2/3 1/6]';  q3 = [1/6 2/3]';
    w1 = 1/3;  w2 = 1/3;  w3 = 1/3;
    
    % Allocate memory for the stiffness matrix and right-hand side
    A = zeros(Nn,Nn);  rhs = zeros(Nn,1);
    
    % For the sake of efficiency, the implementation is tailored on each
    % geometry the solver can handle
    if strcmp(geometry,'rectangle')
        % Shortcuts
        orig = domain.origin;  b = domain.base;  h = domain.height;  
        alpha = domain.angle;
        
        % Precompute the Jacobian of the map from the reference to the
        % physical domain, its inverse and its determinant
        R = [cos(alpha) -sin(alpha); sin(alpha) cos(alpha)];
        S = [b 0; 0 h];  iS = [1/b 0; 0 1/h];
        Jpsi = R*S;  iJpsi = iS*R';  dJpsi = b*h;
                
        % Go through all elements of the mesh
        for n = 1:Ne
            % Extract the vertices of the triangle
            ia = elems(1,n);   ib = elems(2,n);   ic = elems(3,n);
            va = nodes(:,ia);  vb = nodes(:,ib);  vc = nodes(:,ic);

            % Compute Jacobian of the map from reference to current
            % triangle, its inverse and its determinant
            Jphi  = [vb(1)-va(1) vc(1)-va(1); vb(2)-va(2) vc(2)-va(2)];
            dJphi = abs((vb(1)-va(1))*((vc(2)-va(2))) - (vc(1)-va(1))*(vb(2)-va(2)));
            iJphi = [vc(2)-va(2) va(1)-vc(1); va(2)-vb(2) vb(1)-va(1)]/dJphi;

            % Compute iJphi * iJpsi
            M = iJphi * iJpsi;

            % Map quadrature nodes onto the physical (i.e. original) domain
            p1 = Jpsi*(Jphi*q1 + va) + orig;
            p2 = Jpsi*(Jphi*q2 + va) + orig;
            p3 = Jpsi*(Jphi*q3 + va) + orig;

            % Compute entries of the stiffness matrix onto the reference triangle
            A11 = dJphi * dJpsi * gr1'* M * (w1*K(p1) + w2*K(p2) + w3*K(p3))' * M' * gr1;
            A12 = dJphi * dJpsi * gr1'* M * (w1*K(p1) + w2*K(p2) + w3*K(p3))' * M' * gr2;
            A13 = dJphi * dJpsi * gr1'* M * (w1*K(p1) + w2*K(p2) + w3*K(p3))' * M' * gr3;
            A22 = dJphi * dJpsi * gr2'* M * (w1*K(p1) + w2*K(p2) + w3*K(p3))' * M' * gr2;
            A23 = dJphi * dJpsi * gr2'* M * (w1*K(p1) + w2*K(p2) + w3*K(p3))' * M' * gr3;
            A33 = dJphi * dJpsi * gr3'* M * (w1*K(p1) + w2*K(p2) + w3*K(p3))' * M' * gr3;

            % Assemble stiffness matrix
            A(ia,ia) = A(ia,ia) + A11;  
            A(ia,ib) = A(ia,ib) + A12;  A(ib,ia) = A(ib,ia) + A12;
            A(ia,ic) = A(ia,ic) + A13;  A(ic,ia) = A(ic,ia) + A13;
            A(ib,ib) = A(ib,ib) + A22;
            A(ib,ic) = A(ib,ic) + A23;  A(ic,ib) = A(ic,ib) + A23;
            A(ic,ic) = A(ic,ic) + A33;

            % Compute entries of the right-hand side onto the reference triangle
            b1 = (w1*f(p1)*(1-p1(1)-p1(2)) + w2*f(p2)*(1-p2(1)-p2(2)) + ...
               w3*f(p3)*(1-p3(1)-p3(2))) * dJpsi * dJphi;
            b2 = (w1*f(p1)*p1(1) + w2*f(p2)*p2(1) + w3*f(p3)*p3(1)) * dJpsi * dJphi;
            b3 = (w1*f(p1)*p1(2) + w2*f(p2)*p2(2) + w3*f(p3)*p3(2)) * dJpsi * dJphi;

            % Assemble right-hand side
            rhs(ia) = rhs(ia) + b1;  rhs(ib) = rhs(ib) + b2;  rhs(ic) = rhs(ic) + b3;
        end
        
        % Apply boundary conditions
        h = 0.5*(mesh.hmin+mesh.hmax);  TOL = 1e-15;
        for i = 1:Nn
            if (-TOL < nodes(2,i) && nodes(2,i) < TOL)        % South edge
                A(i,:) = 0;  A(i,i) = h;
                rhs(i) = h * BCs_v(Jpsi*nodes(:,i) + orig);
            elseif (1-TOL < nodes(2,i) && nodes(2,i) < 1+TOL) % North edge
                A(i,:) = 0;  A(i,i) = h;
                rhs(i) = h * BCn_v(Jpsi*nodes(:,i) + orig);
            elseif (-TOL < nodes(1,i) && nodes(1,i) < TOL)    % West edge
                A(i,:) = 0;  A(i,i) = h;
                rhs(i) = h * BCw_v(Jpsi*nodes(:,i) + orig);
            elseif (1-TOL < nodes(1,i) && nodes(1,i) < 1+TOL) % East edge
                A(i,:) = 0;  A(i,i) = h;
                rhs(i) = h * BCe_v(Jpsi*nodes(:,i) + orig);
            end
        end
    end
end