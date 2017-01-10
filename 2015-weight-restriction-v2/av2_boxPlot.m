aircraft = '737-800';
dataset = 'cmip5';
rcp = 'historical';

% load modeled data
load(['wr-' aircraft '-' dataset '-' rcp '.mat']);
load(['tr-' aircraft '-' dataset '-' rcp '.mat']);
wrModel = weightRestriction;
trModel = totalRestriction;

% load observations
load(['wr-' aircraft '-obs-.mat']);
wrObs = weightRestriction;

airports = {'PHX', 'LGA', 'DCA', 'DEN'};

% C = [wrObs{2}(2,:), wrModel{2}{1}(2,:), wrObs{3}(2,:), wrModel{3}{1}(2,:)];
% Cgroup = [zeros(size(wrObs{2}(2,:))), ones(size(wrModel{2}{1}(2,:))), 2 .* ones(size(wrObs{3}(2,:))), 3 .* ones(size(wrModel{3}{1}(2,:)))];

C1 = [wrObs{2}(2,:), wrModel{2}{1}(2,:)]; 
C2 = [wrObs{3}(2,:), wrModel{3}{1}(2,:)];
Cgroup1 = [zeros(size(wrObs{2}(2,:))), ones(size(wrModel{2}{1}(2,:)))];
Cgroup2 = [2 .* ones(size(wrObs{3}(2,:))), 3 .* ones(size(wrModel{3}{1}(2,:)))];

fig = figure('Color', [1,1,1]);

subplot(1, 4, 1);
hold on;

b1 = boxplot(C1, Cgroup1, 'Labels', {'LGA-obs', 'LGA-model'}, 'LabelOrientation', 'inline', 'Symbol', 'ko', 'Widths', [0.2], 'Colors', 'kk');
ylabel('Payload restriction (1000s lbs)', 'FontSize', 30);
set(gca, 'FontSize', 30);
%txt = findobj(gca, 'Type', 'text');
%set(txt(1:end), 'VerticalAlignment', 'cap');
%set(txt, 'FontSize', 30);
boxplot(D, {reshape(repmat('A':'F',2,1),12,1) repmat((1:2)',6,1)} ,'factorgap',10,'color','rk')


subplot(1, 4, 2);
hold on;
axis off;

b2 = boxplot(C2, Cgroup2, 'Labels', {'DCA-obs', 'DCA-model'}, 'LabelOrientation', 'inline', 'Symbol', 'bo', 'Widths', [0.2], 'Colors', 'bb');
txt = findobj(gca, 'Type', 'text');
set(txt(1:end), 'VerticalAlignment', 'middle');
set(txt, 'FontSize', 30);

% b1 = boxplot(C, Cgroup, 'Labels', {'LGA-obs', 'LGA-model', 'DCA-obs', 'DCA-model'}, 'Symbol', 'ko', 'Widths', [0.2], 'Colors', boxColors);
% ylabel('Payload restriction (1000s lbs)', 'FontSize', 30);
% set(gca, 'FontSize', 30);
% 
% txt = findobj(gca, 'Type', 'text');
% set(txt(1:end), 'VerticalAlignment', 'middle');
% set(txt, 'FontSize', 30);

% trace1 = struct(...
%   'y', [wrObs{2}(2,:), wrModel{2}{1}(2,:)], ...
%   'x', [zeros(size(wrObs{2}(2,:))), ones(size(wrModel{2}{1}(2,:)))], ...
%   'name', 'LGA', ...
%   'marker', struct('color', '#3D9970'), ...
%   'type', 'box');
% trace2 = struct(...
%   'y', [wrObs{3}(2,:), wrModel{3}{1}(2,:)], ...
%   'x', [2 .* ones(size(wrObs{3}(2,:))), 3 .* ones(size(wrModel{3}{1}(2,:)))], ...
%   'name', 'DCA', ...
%   'marker', struct('color', '#FF4136'), ...
%   'type', 'box');
% data = {trace1, trace2};
% layout = struct(...
%     'yaxis', struct(...
%       'title', 'normalized moisture', ...
%       'zeroline', false), ...
%     'boxmode', 'group');
% response = plotly(data, struct('layout', layout, 'wr_737800', 'box-grouped', 'fileopt', 'overwrite'));
% plot_url = response.url


