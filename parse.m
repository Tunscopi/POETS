%% Title: Parse.m File
% Entry point 
% Description: helps parse our .xlsx data files for faster & efficient data analysis
% Author: Poets HU
%%
function parse(filename)

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
noLoadValues = 11;
noDataValues = 2402;

assignin('base','noDataValues',noDataValues);
assignin('base','headerspace',headerspace);
assignin('base','noLoadValues',noLoadValues);


% 2.1 experiment parameters
Vin = xlsread(filepath,1,'B3');            
Vmeas = xlsread(filepath,1,strcat('D',int2str(headerspace+1),':','D',int2str(headerspace+noLoadValues))); 
loadValues = xlsread(filepath,1,strcat('E',int2str(headerspace+1),':','E',int2str(headerspace+noLoadValues))); 
Imeas = xlsread(filepath,1,strcat('G',int2str(headerspace+1),':','G',int2str(headerspace+noLoadValues))); 

% pre-allocate memory for speed + efficiency
c_t = zeros(noLoadValues, noDataValues-headerspace);
c_h = zeros(noLoadValues, noDataValues-headerspace);
l_t = zeros(noLoadValues, noDataValues-headerspace);
l_h = zeros(noLoadValues, noDataValues-headerspace);
d_t = zeros(noLoadValues, noDataValues-headerspace);
d_h = zeros(noLoadValues, noDataValues-headerspace);
t1_t = zeros(noLoadValues, noDataValues-headerspace);
t1_h = zeros(noLoadValues, noDataValues-headerspace);
t2_t = zeros(noLoadValues, noDataValues-headerspace);
t2_h = zeros(noLoadValues, noDataValues-headerspace);
amb_temp = zeros(noLoadValues, noDataValues-headerspace);
mean_c_h = zeros(1, noLoadValues);
mean_c_t = zeros(1, noLoadValues);
mean_d_h = zeros(1, noLoadValues);
mean_d_t = zeros(1, noLoadValues);
mean_l_h = zeros(1, noLoadValues);
mean_l_t = zeros(1, noLoadValues);
mean_t1_h = zeros(1, noLoadValues);
mean_t1_h = zeros(1, noLoadValues);
mean_t2_h = zeros(1, noLoadValues);
mean_t2_h = zeros(1, noLoadValues);

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
    % capacitor
    c_t(sheetIndex,:) = abs(xlsread(filepath,sheetIndex+1,strcat('E',int2str(headerspace+1),':','E',int2str(noDataValues))));      
    c_h(sheetIndex,:) = abs(xlsread(filepath,sheetIndex+1,strcat('O',int2str(headerspace+1),':','O',int2str(noDataValues))));
    
    % driver
    d_t(sheetIndex,:) = abs(xlsread(filepath,sheetIndex+1,strcat('F',int2str(headerspace+1),':','F',int2str(noDataValues))));      
    d_h(sheetIndex,:) = abs(xlsread(filepath,sheetIndex+1,strcat('P',int2str(headerspace+1),':','P',int2str(noDataValues))));
    
    % inductor
    l_t(sheetIndex,:) = abs(xlsread(filepath,sheetIndex+1,strcat('G',int2str(headerspace+1),':','G',int2str(noDataValues))));      
    l_h(sheetIndex,:) = abs(xlsread(filepath,sheetIndex+1,strcat('Q',int2str(headerspace+1),':','Q',int2str(noDataValues))));
    
    % transistor1
    t1_t(sheetIndex,:) = abs(xlsread(filepath,sheetIndex+1,strcat('H',int2str(headerspace+1),':','H',int2str(noDataValues))));     
    t1_h(sheetIndex,:) = abs(xlsread(filepath,sheetIndex+1,strcat('R',int2str(headerspace+1),':','R',int2str(noDataValues))));
    
    % transistor2
    t2_t(sheetIndex,:) = abs(xlsread(filepath,sheetIndex+1,strcat('I',int2str(headerspace+1),':','I',int2str(noDataValues))));     
    t2_h(sheetIndex,:) = abs(xlsread(filepath,sheetIndex+1,strcat('S',int2str(headerspace+1),':','S',int2str(noDataValues))));
    
    % ambient temperature
    amb_temp(sheetIndex,:) = abs(xlsread(filepath,sheetIndex+1,strcat('D',int2str(headerspace+1),':','D',int2str(noDataValues))));
    
    % averages
    mean_c_t(1,sheetIndex) = abs(mean(c_t(sheetIndex,:)));
    mean_c_h(1,sheetIndex) = abs(mean(c_h(sheetIndex,:)));
    mean_d_t(1,sheetIndex) = abs(mean(d_t(sheetIndex,:)));
    mean_d_h(1,sheetIndex) = abs(mean(d_h(sheetIndex,:)));
    mean_l_t(1,sheetIndex) = abs(mean(l_t(sheetIndex,:)));
    mean_l_h(1,sheetIndex) = abs(mean(l_h(sheetIndex,:)));
    mean_t1_t(1,sheetIndex) = abs(mean(t1_t(sheetIndex,:)));
    mean_t1_h(1,sheetIndex) = abs(mean(t1_h(sheetIndex,:)));
    mean_t2_t(1,sheetIndex) = abs(mean(t2_t(sheetIndex,:)));
    mean_t2_h(1,sheetIndex) = abs(mean(t2_h(sheetIndex,:)));
    
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
