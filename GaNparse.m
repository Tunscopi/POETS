%% Title: Parse.m File
% Entry point 
% Description: helps parse our .xlsx data files for faster & efficient data analysis
% Author: Poets HU
%%
function GaNparse(filename)

% 1. Setup
close all;

if (nargin == 0)
    fprintf('Using recently used file:\n');
    filepath = evalin('base', 'eval(''recentlyUsedFile'')');
    
else
    filepath = strcat('Data/',filename,'.xlsx');
end

if ~exist(filepath,'file')
    errorMessage = sprintf('Error: %s does not exist in the search path folders.', filepath);
		uiwait(warndlg(errorMessage));
		return;
end

% We've found a data file to use
assignin('base','recentlyUsedFile',filepath);
fprintf(filepath);
fprintf('\n\n')
 
%% 2. Extract data into local variables
headerspace = 2;
noLoadValues = 6;
noDataValues = 2402;

assignin('base','noDataValues',noDataValues);
assignin('base','headerspace',headerspace);


% 2.1 experiment parameters
param_Vin = xlsread(filepath,1,'B3'); 
isTrial = strfind(filename, 'trial');
if (param_Vin > 45)
   noLoadValues = 7;
end
if ~isempty(isTrial)
   noLoadValues = 4;
end
assignin('base','noLoadValues',noLoadValues);

param_Vmeas = xlsread(filepath,1,strcat('D',int2str(headerspace+1),':','D',int2str(headerspace+noLoadValues))); 
param_loadValues = xlsread(filepath,1,strcat('E',int2str(headerspace+1),':','E',int2str(headerspace+noLoadValues))); 
param_Imeas = xlsread(filepath,1,strcat('G',int2str(headerspace+1),':','G',int2str(headerspace+noLoadValues))); 

newXpoints = linspace(1,2400,24);

% pre-allocate memory for speed + efficiency
raw_t1_t = zeros(noLoadValues, noDataValues-headerspace);
raw_t1_h = zeros(noLoadValues, noDataValues-headerspace);
raw_t2_t = zeros(noLoadValues, noDataValues-headerspace);
raw_t2_h = zeros(noLoadValues, noDataValues-headerspace);
spY_t1_t = zeros(noLoadValues, (noDataValues-2)/100);
spY_t1_h = zeros(noLoadValues, (noDataValues-2)/100);
spY_t2_t = zeros(noLoadValues, (noDataValues-2)/100);
spY_t2_h = zeros(noLoadValues, (noDataValues-2)/100);
sm_t1_t = zeros(noLoadValues, (noDataValues-2)/100);
sm_t1_h = zeros(noLoadValues, (noDataValues-2)/100);
sm_t2_t = zeros(noLoadValues, (noDataValues-2)/100);
sm_t2_h = zeros(noLoadValues, (noDataValues-2)/100);
amb_temp = zeros(noLoadValues, noDataValues-headerspace);
Vmeas = zeros(noLoadValues, noDataValues-headerspace);
Imeas = zeros(noLoadValues, noDataValues-headerspace);
mean_t1_h = zeros(1, noLoadValues);
mean_t1_h = zeros(1, noLoadValues);
mean_t2_h = zeros(1, noLoadValues);
mean_t2_h = zeros(1, noLoadValues);
sd_t1_t = zeros(1, noLoadValues);
sd_t2_t = zeros(1, noLoadValues);
sd_t1_h = zeros(1, noLoadValues);
sd_t2_h = zeros(1, noLoadValues);
xshift = 0:((noDataValues-2)/100)-1;
gt1 = zeros(noLoadValues, (noDataValues-2)/100);
gt2 = zeros(noLoadValues, (noDataValues-2)/100);
%H1vec = zeros(noLoadValues);
%H2vec = zeros(noLoadValues);
%dT1vec = zeros(noLoadValues);
%dT2vec = zeros(noLoadValues);

% 2.2 data
% parallelize operation 

if ~strncmp(char(java.lang.System.getProperty('java.version')), '', 1)
    % Provided machine runs off the JVM (Matlab launches JVM in client mode by default) 
    % this should work.
    machineNumCores = java.lang.Runtime.getRuntime().availableProcessors; 
else
    % If JVM is disabled, this should suffice. 
    % NB: JVM is preferred b/c it gives you no. of logical cores (usually more than no. of physical cores)
    % hence, speeds up your computation.
    machineNumCores = feature('numcores'); 
end

if isempty(gcp('nocreate'))
    parpool(machineNumCores);
end

tic()
parfor sheetIndex = 1:noLoadValues
    % transistor1
    raw_t1_t(sheetIndex,:) = xlsread(filepath,sheetIndex+1,strcat('H',int2str(headerspace+1),':','H',int2str(noDataValues)));     
    raw_t1_h(sheetIndex,:) = abs(xlsread(filepath,sheetIndex+1,strcat('K',int2str(headerspace+1),':','K',int2str(noDataValues))));
    
    % transistor2
    raw_t2_t(sheetIndex,:) = xlsread(filepath,sheetIndex+1,strcat('I',int2str(headerspace+1),':','I',int2str(noDataValues)));     
    raw_t2_h(sheetIndex,:) = abs(xlsread(filepath,sheetIndex+1,strcat('L',int2str(headerspace+1),':','L',int2str(noDataValues))));
    
    % ambient temperature
    amb_temp(sheetIndex,:) = abs(xlsread(filepath,sheetIndex+1,strcat('D',int2str(headerspace+1),':','D',int2str(noDataValues))));
    
    % experiment recorded voltages and currents
    Vmeas(sheetIndex,:) = abs(xlsread(filepath,sheetIndex+1,strcat('E',int2str(headerspace+1),':','E',int2str(noDataValues))));     
    Imeas(sheetIndex,:) = abs(xlsread(filepath,sheetIndex+1,strcat('F',int2str(headerspace+1),':','F',int2str(noDataValues))));     
    
    
    % smoothed values
    spY_t1_t(sheetIndex,:) = spline(1:2400, raw_t1_t(sheetIndex,:), newXpoints);
    spY_t1_h(sheetIndex,:) = spline(1:2400, raw_t1_h(sheetIndex,:), newXpoints);
    spY_t2_t(sheetIndex,:) = spline(1:2400, raw_t2_t(sheetIndex,:), newXpoints);
    spY_t2_h(sheetIndex,:) = spline(1:2400, raw_t2_h(sheetIndex,:), newXpoints);

    sm_t1_t(sheetIndex,:) = smooth(spY_t1_t(sheetIndex,:));
    sm_t1_h(sheetIndex,:) = smooth(spY_t1_h(sheetIndex,:));    
    sm_t2_t(sheetIndex,:) = smooth(spY_t2_t(sheetIndex,:));
    sm_t2_h(sheetIndex,:) = smooth(spY_t2_h(sheetIndex,:));
    
    % temperature gradients
    gt1(sheetIndex,:) = gradient(sm_t1_t(sheetIndex,:));
    gt2(sheetIndex,:) = gradient(sm_t2_t(sheetIndex,:));
    
    % averages
    mean_t1_t(1,sheetIndex) = abs(mean(raw_t1_t(sheetIndex,:)));
    mean_t1_h(1,sheetIndex) = abs(mean(raw_t1_h(sheetIndex,:)));
    mean_t2_t(1,sheetIndex) = abs(mean(raw_t2_t(sheetIndex,:)));
    mean_t2_h(1,sheetIndex) = abs(mean(raw_t2_h(sheetIndex,:)));
    
    % standard deviation
    sd_t1_t(1,sheetIndex) = std(raw_t1_t(sheetIndex,:));
    sd_t2_t(1,sheetIndex) = std(raw_t2_t(sheetIndex,:));
    sd_t1_h(1,sheetIndex) = std(raw_t1_h(sheetIndex,:));
    sd_t2_h(1,sheetIndex) = std(raw_t2_h(sheetIndex,:));
    
end
parfor loadIndex = 1:noLoadValues
   H1vec(loadIndex) = sm_t1_h(loadIndex,1);
   H2vec(loadIndex) = sm_t2_h(loadIndex,1);
   dT1vec(loadIndex) = gt1(loadIndex,1);
   dT2vec(loadIndex) = gt2(loadIndex,1);
end
fprintf('parse time: %.1f(s)\n', toc);

% turn off parpool cluster
%delete(gcp('nocreate'))
    
%% perform various arithmetic & plot operations on parsed data available in workspace 
disp('Ready...');
keyboard

end


%% 3. Utility plot visualization functions
function plBoth(y1data,y2data,titleLabel)
           
    noDatapoints = evalin('base', 'eval(''noDataValues'')');
    header = evalin('base', 'eval(''headerspace'')');
    timePoints = linspace(1,noDatapoints-header,noDatapoints-header);
    
    fig = figure;
    assignin('base','FigHandle',fig);
    plot(timePoints, y1data, timePoints, y2data)
    xlabel('H-Field  H');

    if (nargin <= 2)
        titleLabel = strcat('Temperature Vs. Magnetic Field');
    end
    
    title(titleLabel)
    
    grid on
    ylabel('Temperature  ^{0}F');
    legend('Data1','Data2')
end

function plvLoad(ydata,ylabelStr)
    loadValues = [20,5,2.5,1.66,1.25,1.11,1.25,1.66,2.5,5,20];
    plot(loadValues, ydata)
    
    hold on
    grid on
    xlabel('Load L');
    
    if (nargin == 1)
        ylabel(ylabelStr);
    end
    
    legend('Data1','Data2')
end

function pl2Values()

end

% save plots to the Figs folder
function sv(titleLabel)
    if (nargin == 0)
        titleLabel = evalin('base', 'eval(''filepath'', ''titleLabel'')');
    end
    
    FigH = evalin('base', 'eval(''FigHandle'')');
    
    title(titleLabel)
    set(FigH, 'Position', [100 100 150 150]);
    saveas(FigH,strcat('Figs/', titleLabel, '.png'));
    fprintf('successfully saved to Figs folder');
    close all;
end

% add other functions to plot against load, etc
% ofcourse desired plot values can also be done from the command window
