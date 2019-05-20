%STARTUPSAV   Startup file
%   Change the name of this file to STARTUP.M. The file 
%   is executed when MATLAB starts up, if it exists 
%   anywhere on the path.  In this example, the
%   MAT-file generated during quitting using FINISHSAV
%   is loaded into MATLAB during startup.

%   Copyright 1984-2000 The MathWorks, Inc. 

%load matlab.mat

%STARTUPSAV   Startup file
%   Change the name of this file to STARTUP.M. The file 
%   is executed when MATLAB starts up, if it exists 
%   anywhere on the path.  In this example, the
%   MAT-file generated during quitting using FINISHSAV
%   is loaded into MATLAB during startup.

%   Copyright 1984-2000 The MathWorks, Inc. 

addpath([matlabroot '\toolbox\custom']);
addpath([matlabroot '\toolbox\custom\barwitherr']);
addpath([matlabroot '\toolbox\custom\export_fig_new']);
addpath([matlabroot '\toolbox\custom\figuremaker']);
addpath([matlabroot '\toolbox\custom\mapdata']);
addpath([matlabroot '\toolbox\custom\spaceplots']);
addpath([matlabroot '\toolbox\custom\subaxis']);
addpath([matlabroot '\toolbox\custom\tightfig']);
addpath([matlabroot '\toolbox\custom\brewermap']);
addpath([matlabroot '\toolbox\custom\aboxplot']);
addpath([matlabroot '\toolbox\custom\hatchfillpkg']);
addpath([matlabroot '\toolbox\custom\plot2svg']);
addpath([matlabroot '\toolbox\custom\cbarrow']);
%addpath([matlabroot '\toolbox\custom']);


run('c:\git-ecoffel\grad-research\custom_startup.m');
%load matlab.mat