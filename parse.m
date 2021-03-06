%% Title: Parse.m File
% Entry point 
% Description: helps parse our .xlsx data files obtained from MFS-3A GMW sensors for faster & efficient data analysis
% Author: Ayotunde Odejayi (Poets HU)
%%
function parse(filename)

% 1. Setup
%close all;

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
% i. configurable
steadystate_elapsed_time = 20; % in minutes
observe_point = 5;

no_samplePoints = 24;

sensitivity = 280; % in mV/mT from datasheet 
% http://www.gmw.com/magnetic_sensors/ametes/documents/Ametes_MFS-3A_Spec_18_Apr_2011.pdf

param_Vin = xlsread(filepath,1,'B3'); 
isTrial = strfind(filepath, 'trial');
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

newXpoints = linspace(1,2400,no_samplePoints);

% pre-allocate memory for speed + efficiency
raw_T1 = zeros(noLoadValues, noDataValues-headerspace);
raw_T2 = zeros(noLoadValues, noDataValues-headerspace);
temp_T2 = zeros(noDataValues);
splineY_T1 = zeros(noLoadValues, (noDataValues-2)/100);
splineY_T2 = zeros(noLoadValues, (noDataValues-2)/100);
smoothed_T1 = zeros(noLoadValues, (noDataValues-2)/100);
smoothed_T2 = zeros(noLoadValues, (noDataValues-2)/100);
gradient_T1 = zeros(noLoadValues, (noDataValues-2)/100);
gradient_T2 = zeros(noLoadValues, (noDataValues-2)/100);

Vx1 = zeros(noLoadValues, noDataValues-headerspace);
Vy1 = zeros(noLoadValues, noDataValues-headerspace);
Vz1 = zeros(noLoadValues, noDataValues-headerspace);
Vx2 = zeros(noLoadValues, noDataValues-headerspace);
Vy2 = zeros(noLoadValues, noDataValues-headerspace);
Vz2 = zeros(noLoadValues, noDataValues-headerspace);
raw_B1 = zeros(noLoadValues, noDataValues-headerspace);
raw_B2 = zeros(noLoadValues, noDataValues-headerspace);
splineY_B1 = zeros(noLoadValues, (noDataValues-2)/100);
splineY_B2 = zeros(noLoadValues, (noDataValues-2)/100);
smoothed_B1 = zeros(noLoadValues, (noDataValues-2)/100);
smoothed_B2 = zeros(noLoadValues, (noDataValues-2)/100);

mean_B1 = zeros(1, noLoadValues);
mean_B2 = zeros(1, noLoadValues);
mean_T1 = zeros(1, noLoadValues);
mean_T2 = zeros(1, noLoadValues);

amb_temp = zeros(noLoadValues, noDataValues-headerspace);
Vmeas = zeros(noLoadValues, noDataValues-headerspace);
Imeas = zeros(noLoadValues, noDataValues-headerspace);

overflowImpending = zeros(noLoadValues, 1);
temp_T2 = zeros(1, noDataValues-2);

sd_B1 = zeros(1, noLoadValues);
sd_B2 = zeros(1, noLoadValues);
sd_T1 = zeros(1, noLoadValues);
sd_T2 = zeros(1, noLoadValues);

% 2.2 data
% parallelize operation 

if ~strncmp(char(java.lang.System.getProperty('java.version')), '', 1)
    % Provided machine runs off the JVM (Matlab launches JVM in client mode by default) 
    % this should work.
    machineNumCores = java.lang.Runtime.getRuntime().availableProcessors; 
else
    % If JVM is disabled, this should suffice. 
    % NB: JVM is preferred b/c it gives you no. of logical cores (usually more than no. of physical cores)
    % hence, speeds up our computation.
    machineNumCores = feature('numcores'); 
end

if isempty(gcp('nocreate'))
    parpool(machineNumCores);
end

tic()
parfor sheetIndex = 1:noLoadValues
    % Temperature and magnetic field
    % transistor1
    raw_T1(sheetIndex,:) = xlsread(filepath,sheetIndex+1,strcat('H',int2str(headerspace+1),':','H',int2str(noDataValues)));     
    Vx1(sheetIndex,:) = xlsread(filepath,sheetIndex+1,strcat('K',int2str(headerspace+1),':','K',int2str(noDataValues)));
    Vy1(sheetIndex,:) = xlsread(filepath,sheetIndex+1,strcat('L',int2str(headerspace+1),':','L',int2str(noDataValues)));
    Vz1(sheetIndex,:) = xlsread(filepath,sheetIndex+1,strcat('M',int2str(headerspace+1),':','M',int2str(noDataValues)));

    % transistor2
    raw_T2(sheetIndex,:) = xlsread(filepath,sheetIndex+1,strcat('I',int2str(headerspace+1),':','I',int2str(noDataValues)));
    Vx2(sheetIndex,:) = xlsread(filepath,sheetIndex+1,strcat('N',int2str(headerspace+1),':','N',int2str(noDataValues)));
    Vy2(sheetIndex,:) = xlsread(filepath,sheetIndex+1,strcat('O',int2str(headerspace+1),':','O',int2str(noDataValues)));
    Vz2(sheetIndex,:) = xlsread(filepath,sheetIndex+1,strcat('P',int2str(headerspace+1),':','P',int2str(noDataValues)));    
    
    % Handle overflow from IR sensor (usually occurs at excursion point i.e L7 on transistor #2)
    if sheetIndex == 7
        temp_T2 = raw_T2(sheetIndex,:);
        for valueIndex = 1:noDataValues-2
            if (temp_T2(1, valueIndex) > 249.0 && overflowImpending(sheetIndex,1) == 0)
                overflowImpending(sheetIndex,1) = 1;
            end
            if (temp_T2(1, valueIndex) < 100.0 && overflowImpending(sheetIndex,1) == 1)
                temp_T2(1, valueIndex) = temp_T2(1, valueIndex) + 249.0;
            end
        end
        raw_T2(sheetIndex,:) = temp_T2;
    end
     
    
    % ambient temperature
    %amb_temp(sheetIndex,:) = xlsread(filepath,sheetIndex+1,strcat('D',int2str(headerspace+1),':','D',int2str(noDataValues)));
    
    % experiment recorded voltages and currents
    %Vmeas(sheetIndex,:) = xlsread(filepath,sheetIndex+1,strcat('E',int2str(headerspace+1),':','E',int2str(noDataValues)));     
    %Imeas(sheetIndex,:) = xlsread(filepath,sheetIndex+1,strcat('F',int2str(headerspace+1),':','F',int2str(noDataValues)));     
    
    
    % Total magnetic field density (Ametes MFS-3A sensor)
    raw_B1(sheetIndex,:) = sqrt(Vx1(sheetIndex,:).^2 + Vy1(sheetIndex,:).^2 + Vz1(sheetIndex,:).^2)/sensitivity;
    raw_B2(sheetIndex,:) = sqrt(Vx2(sheetIndex,:).^2 + Vy2(sheetIndex,:).^2 + Vz2(sheetIndex,:).^2)/sensitivity;
    
    % smoothed values
    splineY_T1(sheetIndex,:) = spline(1:2400, raw_T1(sheetIndex,:), newXpoints);
    splineY_B1(sheetIndex,:) = spline(1:2400, raw_B1(sheetIndex,:), newXpoints);
    splineY_T2(sheetIndex,:) = spline(1:2400, raw_T2(sheetIndex,:), newXpoints);
    splineY_B2(sheetIndex,:) = spline(1:2400, raw_B2(sheetIndex,:), newXpoints);

    smoothed_T1(sheetIndex,:) = smooth(splineY_T1(sheetIndex,:));
    smoothed_B1(sheetIndex,:) = smooth(splineY_B1(sheetIndex,:));    
    smoothed_T2(sheetIndex,:) = smooth(splineY_T2(sheetIndex,:));
    smoothed_B2(sheetIndex,:) = smooth(splineY_B2(sheetIndex,:));
    
    % temperature gradients
    gradient_T1(sheetIndex,:) = gradient(smoothed_T1(sheetIndex,:));
    gradient_T2(sheetIndex,:) = gradient(smoothed_T2(sheetIndex,:));
    
    % averages
    mean_T1(1,sheetIndex) = mean(raw_T1(sheetIndex,:));
    mean_T2(1,sheetIndex) = mean(raw_T2(sheetIndex,:));
    mean_B1(1,sheetIndex) = mean(raw_B1(sheetIndex,:));
    mean_B2(1,sheetIndex) = mean(raw_B2(sheetIndex,:));
    
    % standard deviation
    sd_T1(1,sheetIndex) = std(raw_T1(sheetIndex,:));
    sd_T2(1,sheetIndex) = std(raw_T2(sheetIndex,:));
    sd_B1(1,sheetIndex) = std(raw_B1(sheetIndex,:));
    sd_B2(1,sheetIndex) = std(raw_B2(sheetIndex,:));
    
end


% slicing immediate and steady-state values to reduce parfor communication overhead
    gradient_T1_imm = smoothed_T1(:,1);
    gradient_T2_imm = smoothed_T2(:,1);
    gradient_T1_ss = smoothed_T1(:,floor(steadystate_elapsed_time*120/((noDataValues-2)/no_samplePoints)));
    gradient_T2_ss = smoothed_T2(:,floor(steadystate_elapsed_time*120/((noDataValues-2)/no_samplePoints)));
    gradient_T1_otherpoint = smoothed_T1(:,floor(observe_point*120/((noDataValues-2)/no_samplePoints)));
    gradient_T2_otherpoint = smoothed_T2(:,floor(observe_point*120/((noDataValues-2)/no_samplePoints)));

    smoothed_B1_imm = smoothed_B1(:,1);
    smoothed_B2_imm = smoothed_B2(:,1);
    smoothed_B1_ss = smoothed_B1(:,floor(steadystate_elapsed_time*120/((noDataValues-2)/no_samplePoints)));
    smoothed_B2_ss = smoothed_B2(:,floor(steadystate_elapsed_time*120/((noDataValues-2)/no_samplePoints)));
    smoothed_B1_otherpoint = smoothed_B1(:,floor(observe_point*120/((noDataValues-2)/no_samplePoints)));
    smoothed_B2_otherpoint = smoothed_B2(:,floor(observe_point*120/((noDataValues-2)/no_samplePoints)));

    
% compute 
parfor loadIndex = 1:noLoadValues
   T1imm(loadIndex) = gradient_T1_imm(loadIndex);
   T2imm(loadIndex) = gradient_T2_imm(loadIndex);
   T1ss(loadIndex) = gradient_T1_ss(loadIndex);
   T2ss(loadIndex) = gradient_T2_ss(loadIndex);
   T1op(loadIndex) = gradient_T1_otherpoint(loadIndex);
   T2op(loadIndex) = gradient_T2_otherpoint(loadIndex);
   
   B1imm(loadIndex) = smoothed_B1_imm(loadIndex);
   B2imm(loadIndex) = smoothed_B2_imm(loadIndex);
   B1ss(loadIndex) = smoothed_B1_ss(loadIndex);
   B2ss(loadIndex) = smoothed_B2_ss(loadIndex);
   B1op(loadIndex) = smoothed_B1_otherpoint(loadIndex);
   B2op(loadIndex) = smoothed_B2_otherpoint(loadIndex);
end
fprintf('parse time: %.1f(s)\n', toc);

% turn off parpool cluster
% delete(gcp('nocreate'))
    
%% perform various arithmetic & plot operations on parsed data available in workspace 
disp('Ready...');
% We can either edit with i) parpool still live and program live or 
% instead, we can ii) save workspace and load it with all the saved variables
% i) 
% keyboard
% ii) 
workspace_file = strcat('Data/',filename);
save(workspace_file)

end
