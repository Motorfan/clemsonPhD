function main()
clear
close all

% Target PseudoStrains and Density Modes
  combinedTopologyOptimization('1', '1', '1','113', 'na'); % genrate psuedo strain and density targets
%    combinedTopologyOptimization('1', '1', '1','114', 'na'); % save psuedo strain and density targets results in data files
%   combinedTopologyOptimization('1', '1', '1','115', 'na'); % plot psuedo strain and density targets results




% Anisotrpoic
% combinedTopologyOptimization('1', '1', '1','6', 'na');
% combinedTopologyOptimization('1', '1', '1','70', 'na');
 

% Validation modes
% combinedTopologyOptimization('1', '1', '1','111', 'na');
%    combinedTopologyOptimization('1', '1', '1','112', 'na');


% Iteration 1 of topology, Exx, Eyy, rotation
% combinedTopologyOptimization('1', '1', '1','60', 'na');
% combinedTopologyOptimization('1', '1', '1','200', 'na');
%  combinedTopologyOptimization('1', '1', '1','202', 'na'); % make complete structure
% combinedTopologyOptimization('1', '1', '1','90', 'na');
%   combinedTopologyOptimization('1', '1', '1','203', 'na'); % extact macro values


% % iteration 2
% combinedTopologyOptimization('1', '1', '2','60', 'na');
% combinedTopologyOptimization('1', '1', '2','200', 'na');
% run meso design for iteration 2
% combinedTopologyOptimization('1', '1', '2','202', 'na'); % make complete structure
% combinedTopologyOptimization('1', '1', '2','203', 'na'); % extact macro values
% combinedTopologyOptimization('1', '1', '2','90', 'na');

% % iteration 3
% combinedTopologyOptimization('1', '1', '3','60', 'na');
% combinedTopologyOptimization('1', '1', '3','200', 'na');
% run meso design for iteration 2
% combinedTopologyOptimization('1', '1', '3','202', 'na'); % make complete structure
% combinedTopologyOptimization('1', '1', '3','203', 'na'); % extact macro values
% combinedTopologyOptimization('1', '1', '3','90', 'na');

% Comparing
% Run just the topology case
% combinedTopologyOptimization('1', '1', '1','1', 'na');


% annTest(1);

nelx= 15;
nely = 15;
totale=nelx*nely;

% combinedTopologyOptimization('1', '1', '1','100', '1'); % run the meso structure design to get the actual data

% % for i = 1:totale
 for i = 11:225
      combinedTopologyOptimization('1', '1', '1','100', int2str(i)); % run the meso structure design to get the actual data
 end

if(1==0)
    
    poolobj = gcp('nocreate'); % If no pool,create new one.
    if isempty(poolobj)
        parpool('local', 3)
        poolsize = 3;
    else
        poolsize = poolobj.NumWorkers;
    end
    poolsize
    
    
    
    parfor i = 1:225
        combinedTopologyOptimization('1', '1', '2','100', int2str(i)); % run the meso structure design to get the actual data
    end
end



end