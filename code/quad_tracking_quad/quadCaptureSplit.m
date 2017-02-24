function [vf, runtime]=quadCaptureSplit(gN, dt, accuracy)
%% Input: grid, target, time
if nargin < 1
  gN = 21;
end

t0 = 0;
tMax = 70;
if nargin < 2
  dt = 1;
end
tau = t0:dt:tMax;

if nargin<3
  accuracy = 'low';
end

if nargin <4
  gMinX = [-5; -5];
  gMaxX = [5; 5];
  gMinY = [-5; -5];
  gMaxY = [5; 5];
  g_NX = gN*ones(length(gMinX),1);
  g_NY = gN*ones(length(gMinY),1);
  gX = createGrid(gMinX,gMaxX, g_NX, [], true);
  gY = createGrid(gMinY,gMaxY, g_NY, [], true);
%     g_min = [-5; -5; -5; -5];
%   g_max = [5; 5; 5; 5];
%   g_N = gN*ones(length(g_min),1);
%   g = createGrid(g_min,g_max, g_N, [], true);
end

%% make initial data
ignoreDims = 2;
center = [0 0];

dataX0 = zeros(gX.shape);
for i = 1 : gX.dim
  if(all(i ~= ignoreDims))
    dataX0 = dataX0 + (gX.xs{i} - center(i)).^2;
  end
end
dataX0 = -sqrt(dataX0);


 ignoreDims = 2;
 center = [0 0];
 dataY0 = zeros(gY.shape);
 for i = 1 : gY.dim
   if(all(i ~= ignoreDims))
     dataY0 = dataY0 + (gY.xs{i} - center(i)).^2;
   end
 end
 dataY0 = -sqrt(dataY0);

%% visualize initial data
f1 = figure(1);
clf
%[g02D, data02D] = proj(g, data0, [0 1 0 1], 'min');
subplot(1,2,1)
hX = surfc(gX.xs{1}, gX.xs{2}, dataX0);
xlabel('x')
ylabel('v_x')
subplot(1,2,2)
hY = surfc(gY.xs{1}, gY.xs{2}, dataY0);
xlabel('y')
ylabel('v_y')
figure(1)

%% Input: Problem Parameters
aMax = [3 3];
aMin = -aMax;

bMax = [.5 .5];
bMin = -bMax;

dMax = [.1 .1];
dMin = -dMax;

uMax = [bMax(1) aMax(1) bMax(2) aMax(2)];
uMin = [bMin(1) aMin(1) bMin(2) aMin(2)];
uMode = 'max';
dMode = 'min';

%% Input: SchemeDatas
Xdims = 1:2;
Ydims = 3:4;

sD_X.dynSys = Quad4D2DCAvoid(zeros(2,1), uMax, uMin, dMax, dMin, Xdims);
sD_Y.dynSys = Quad4D2DCAvoid(zeros(2,1), uMax, uMin, dMax, dMin, Ydims);

%dims = [1:4];
%schemeData.dynSys = Quad4D2DCAvoid(zeros(4,1), uMax, uMin, dMax, dMin, dims);


sD_X.uMode = uMode;
sD_Y.uMode = uMode;
sD_X.dMode = dMode;
sD_Y.dMode = dMode;

sD_X.grid = gX;
sD_Y.grid = gY;

sD_X.accuracy = accuracy;
sD_Y.accuracy = accuracy;
%schemeData.dMode = dMode;
%schemeData.grid = g;
%schemeData.accuracy = accuracy;

%% Run
tic;
%extraArgs.visualize = 'true';
%extraArgs.stopInit = [0,0,0,0];
%extraArgs.keepLast = true;
%extraArgs.visualize = true;
%extraArgs.deleteLastPlot = true;
% extraArgs.plotData.projpt = 0;
% extraArgs.plotData.plotDims = [1 1 1 0];
extraArgs.stopConverge = 1;
extraArgs.targets = dataX0;
[dataX, tau] = HJIPDE_solve(dataX0, tau, sD_X, 'none', extraArgs);
extraArgs.targets = dataY0;
[dataY, tau] = HJIPDE_solve(dataY0, tau, sD_Y, 'none', extraArgs);

%[data, tau] = ...
%  HJIPDE_solve(data0, tau, schemeData, 'none',extraArgs);
runtime = toc;

%% Reconstruct
%     vfs - Self-contained (decoupled) value functions
%              .gs:     cell structure of grids
%              .tau:    common time vector
%              .datas:  cell structure of SC datas (value function look-up
%                       tables)
%              .dims: dimensions of each value function (cell}

vfs.gs = {[gX],[gY]};
vfs.tau = tau;
vfs.datas = {dataX, dataY};
vfs.dims = {[1,2];[3,4]};
vf = reconSC(vfs, [gMinX; gMinY], [gMaxX; gMaxY],'full');

%% Save 
% if ndims(data) > 4
%   data = min(data,[],5);
% end
% save(['CDC_pl3_abs_target_' num2str(g.N(1)) 'x' num2str(g.N(1)) '_'...
%   num2str(tMax) 'sec_' schemeData.accuracy 'acc_Goal.mat'],...
%   'data','g','tau','runtime','-v7.3');
end