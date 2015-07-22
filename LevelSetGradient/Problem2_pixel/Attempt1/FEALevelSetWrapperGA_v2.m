function [obj, cinequality] = FEALevelSetWrapperGA_v2(zpoints)

step = 1;
[xpoints,ypoints] = meshgrid(0:step:6,0:step:2); 
zpoints_v2 = xpoints;
[xdim, ydim] = size(zpoints_v2);

if(zpoints ==1.111)
    zpoints = ones(1,xdim*ydim)*1.1;
    % zpoints = [0.7722,0.75922,0.75435,0.7519,0.78199,0.7528,0.76739,0.48071,0.49788,0.90558,0.75539,0.75453,0.49767,0.7585,0.75453,0.90833,0.5,0.48214,0.49719,0.87068,0.48033]
    zpoints = [0.80419,0.92926,0.9231,0.92713,0.82608,0.82837,0.96309,0.27148,0.43926,0.99629,0.24976,0.30176,0.26478,0.05422,0.89502,0.76891,0.44518,0.047689,0.32923,0.062045,0.10381]

    doplot = 1;
else
    doplot = 0;
end

zpoints = zpoints*4-2; % un-normalize the values. 

count = 1;
for i = 1:xdim
    zpoints_v2(i,:) = zpoints(count:ydim+count-1);
    count = count + ydim;  
end


[maxVonMisesStress, cost,maxDisplacement,strainEnergy] = FEALevelSet_2D_v8(xpoints,ypoints,zpoints_v2, doplot); % Call FEA for first time

minStrainE = 40;
maxStrainE = 500;
strainEnergyNormalized = (strainEnergy-minStrainE)/(maxStrainE-minStrainE);

weightCost = 0.6;
weightStrainE = 1-weightCost;


obj = (strainEnergyNormalized*weightStrainE ...
    + weightCost*cost)*1000; % do a weighted sum. Multiply by 1000 to scale up so we don't get close the the ending conditions for the GA. 

targetCost = 0.35;

% if the cost goes below, 0.5, then just leave the objective calc like it
% is at 0.5. 
if(cost<=targetCost)
    obj = (strainEnergyNormalized*weightStrainE ...
    + weightCost*targetCost)*1000;
end

cinequality = [cost] ;  % sstress must be below 3000, max dipslacement below 0.3


fprintf('Strain E  = %f and cost = %f  and obj = %f\n',strainEnergy, cost, obj)



