function [data,tau,sD,teb]=P4D_Q2D_RS(gN, visualize)

if nargin < 1
  gN = [55; 55; 25; 25];
end

if nargin < 2
  visualize = true;
end

%% Grid and cost

% Grid Bounds
gMin = [-1.5; -1.5; -pi; -5];
gMax = [ 1.5;  1.5;  pi; 5];

% createGrid takes in grid bounds, grid number, and periodic dimensions
sD.grid = createGrid(gMin, gMax, gN, 3);

% Cost Function
data0 = sD.grid.xs{1}.^2 + sD.grid.xs{2}.^2;

% obstacles
extraArgs.obstacles = -data0;  %%%%%%%%%%%%%%%%%%%%

if visualize
  % to visualize initial function over 2D grid, project onto 2D
  [g2D, data02D] = proj(sD.grid,data0,[0 0 1 1],[0 2]);
  
  figure(1)
  clf
  subplot(1,2,1)
  
  % plot data02D over grid in x and y
  surf(g2D.xs{1}, g2D.xs{2}, sqrt(data02D))
end

%% Dynamical system

% min and max turn rate for tracker
uMin = -8;
uMax = 8;

% min and max velocities for planner (in x and y)
pMin = [-.5; -.5];
pMax = [.5; .5];

% min and max disturbance for wind (in x and y) 
dMax = [0; 0];
dMin = [0; 0];

% max and min acceleration of tracker
aMin = -5;
aMax = 5;

% number of dimensions in the system
dims = 1:4;

% create dynamic system
sD.dynSys = P4D_Q2D_Rel([], uMin, uMax, pMin, pMax, dMin, dMax, aMin, aMax, dims);

%% Other Parameters

% is tracker minimizing or maximizing?
sD.uMode = 'min';

% is planner minimizing or maximizing?
sD.dMode = 'max';

% how high accuracy?
sD.accuracy = 'low';

if visualize
  % set visualize to true
  extraArgs.visualize = true;
  
  % set slice of function to visualize
  extraArgs.RS_level = 2; 
  
  % figure number
  extraArgs.fig_num = 2;
  f = figure(2);
  set(f, 'Position', [400 400 450 400]);
  extraArgs.plotData.plotDims = [1 1 0 0];
  extraArgs.plotData.projpt = [0 2];
  
  % delete previous time step's plot
  extraArgs.deleteLastPlot = false;
end

% time step
dt = 0.1;

% Max time
tMax = .75;

% Vector of times
tau = 0:dt:tMax;

% stop when function has converged
extraArgs.stopConverge = true;

% converges when function doesn't change by more than dt each time step
extraArgs.convergeThreshold = dt;

% solve backwards reachable set
[data, tau] = HJIPDE_solve(data0, tau, sD, 'none', extraArgs); %%%%%%%%%%%%%%%%%%%%%%

% largest cost along all time (along the entire 5th dimension which is
% time)
data = max(data,[],5); %%%%%%%%%%%%%%%%%%%%%%%%%%%

if visualize
  figure(1)
  subplot(1,2,2)
  [g2D, data2D] = proj(sD.grid, data, [0 0 1 1], [0 2]);
  s = surf(g2D.xs{1}, g2D.xs{2}, sqrt(data2D));
  
  %Level set for tracking error bound
  lev = min(min(s.ZData));
  
  f = figure(2);
  clf
  set(f, 'Position', [360 278 560 420]);
  alpha = .2;
  small = .05;
  
  levels = [.5, .75, 1];  
  
  [g3D, data3D] = proj(sD.grid,data,[0 0 0 1], 2);%'max');
  [~, data03D] = proj(sD.grid,data0,[0 0 0 1], 2);
  
  
  for i = 1:3
      subplot(2,3,i)
      h0 = visSetIm(g3D, sqrt(data03D), 'blue', levels(i)+small);
      h0.FaceAlpha = alpha;
      hold on
      h = visSetIm(g3D, sqrt(data3D), 'red', levels(i));
      axis([-levels(3)-small levels(3)+small ...
        -levels(3)-small levels(3)+small -pi pi])
    if i == 2
      title(['t = ' num2str(tau(end)) ' s'])
    end
      axis square
  end
  
  for i = 4:6
      subplot(2,3,i)
      h0 = visSetIm(g2D, sqrt(data02D), 'blue', levels(i-3)+small);
      hold on
      h = visSetIm(g2D, sqrt(data2D), 'red', levels(i-3));
      axis([-levels(3)-small levels(3)+small ...
        -levels(3)-small levels(3)+small])
      title(['R = ' num2str(levels(i-3))])
      axis square
          
  set(gcf,'Color','white')
end

%tracking error bound
teb = sqrt(min(data(:))) + 0.05;

%lev = 0.4408;
lev = lev + 0.03;

if visualize
    figure(3)
    clf
    h0 = visSetIm(g2D, sqrt(data02D), 'blue', lev+small);
    hold on
    h = visSetIm(g2D, sqrt(data2D), 'red', lev);
    title(['Tracking Error Bound R = ' num2str(lev)])
    axis square
end

end
