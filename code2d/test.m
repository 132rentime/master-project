% A script for testing various components of the finite element solver for
% two-dimensional Poisson.

clc
clear variables
clear variables -global
close all

%% Preliminar test: function vs handle function

x = randn(1e6,1);

tstart = tic;
for i = 1:1e6
    y = 1;
end
dt = toc(tstart);
fprintf('Direct function: %5.5f\n',dt)

fun = @(t) 1;
tstart = tic;
for i = 1:1e6
    y = fun(x(i));
end
dt = toc(tstart);
fprintf('Handle function: %5.5f\n',dt)

tstart = tic;
for i = 1:1e6
    if isfloat(1)
        y = 1;
    end
end
dt = toc(tstart);
fprintf('%5.5f\n',dt)

%% Test buildMesh2d and plotMesh2d

%[mesh,model] = buildMesh2d('rectangle');
%[mesh,model] = buildMesh2d('rectangle', 'base',2, 'height',3);
%[mesh,model] = buildMesh2d('rectangle', 'base',2, 'height',3, 'angle',pi/4);
[mesh,opt] = buildMesh2d('rectangle', 'base',2, 'height',3, 'angle',-pi/4);

plotMesh2d(mesh)

%% Test first version of LinearPoisson2dFEP1

%[mesh,u] = LinearPoisson2dFEP1('rectangle', 'base',2, 'height',3, 'angle',-pi/4);
%plotMesh2d(mesh)

%% Test full version of LinearPoisson2dFEP1

[mesh,u] = LinearPoisson2dFEP1(@K1, @f1, 'D',@BC1, 'D',@BC1, 'D',@BC1, 'D',@BC1, ...
     'rectangle', 'base',10, 'height',10, 'angle',pi/10);
%[mesh,u,A,rhs] = LinearPoisson2dFEP1(@K1, @f2, 'D',@BC2, 'D',@BC0, 'D',@BC2, 'D',@BC0, ...
%    'rectangle', 'origin',[1 0]', 'Hmax',0.04);

close all
plotSolution2d(mesh,u)
