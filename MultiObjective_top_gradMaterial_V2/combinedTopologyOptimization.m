function combinedTopologyOptimization(useInputArgs, w1text, iterationNum,macro_meso_iteration)
% input args, useInputArgs = 1 if to use the input args
% w1 weight1 for weighted objective.
% iterationNum, used to know where to output files.
close all
% h = figure(1);hh = figure(2);
% set(h,'visible','off');
% set(hh,'visible','off');

% --------------------------------------
% %% Settings
% --------------------------------------------
settings = Configuration;
settings.macro_meso_iteration = macro_meso_iteration;
settings.mode =10;
% 1 = topology only,
% 2 = material optimization only.
% 3 = both mateiral vol fraction and topology
% 4 = meso testing only.
% 5 = test saving macro structure info to .csv file80s.  meso-structure
% 6.= Testing reading .csv files and designing each meso structure
% 7= testing recombinging the meso structure designs.
% 8= modes 6 and 7 combined
% 10 = everything working!!!



settings.elasticMaterialInterpMethod = 2; % Hashin�Shtrikam law (average of upper and lower boundary)
settings.heatMaterialInterpMethod = 5; % Hashin�Shtrikam law (average of upper and lower boundary)

% target volumes of material 1 and 2
settings.v1 = 0.1;
settings.v2 = 0.3;



% This is as the new way, but try to make compatible with old
% Each design var controls several elements. 1= true, 0= false
settings.doUseMultiElePerDV = 0;
settings.averageMultiElementStrain = 0;
settings.singleMesoDesign = 0;
settings.mesoplotfrequency = 1;
settings.parallel = 1;
settings.mesoAddAdjcentCellBoundaries =1;

if(settings.singleMesoDesign ==1)
    settings.v1 = 0.4;
    settings.v2 = 0;
end

% if using input args, then override some configurations.
% if using input args, then running on the cluster, so use high resolution,
% otherwise use low resolution
if(str2num(useInputArgs) ==1)
    settings.nelx = 50;
    settings.nely = 50;
    settings.numXElmPerDV=1;
    settings.numYElmPerDV=1;
    
    settings.nelxMeso = 20; %35;
    settings.nelyMeso =20; %35;
    settings.w1 = 1; % do not set to zero, instead set to 0.0001. Else we will get NA for temp2
    settings.iterationNum = 0;
    settings.doSaveDesignVarsToCSVFile = 0;
    settings.doPlotFinal = 0;
    %  settings.terminationCriteria =0.1; % 10%
    settings.terminationCriteria =0.001; % 3%
    
    
    settings.parallel = 1;
    settings.numWorkerProcess = 8; % set to the number of nodes requested.
    settings.doPlotVolFractionDesignVar = 0;
    settings.doPlotTopologyDesignVar = 0;
    settings.doPlotHeat = 0;
    settings.doPlotHeatSensitivityTopology = 0;
    settings.doPlotStress = 0;
    settings.doPlotFinal = 0;
    settings.doSaveDesignVarsToCSVFile = 1; % set to 1 to write to csv file instead
    settings.maxFEACalls = 350;
    settings.maxMasterLoops = 500; % make it so, the fea maxes out first.
else
    
    settings.nelx = 50;
    settings.nely = 50;
    settings.numXElmPerDV=1;
    settings.numYElmPerDV=1;
    
    settings.nelxMeso = 20; %35;
    settings.nelyMeso =20; %35;
    settings.w1 = 1; % do not set to zero, instead set to 0.0001. Else we will get NA for temp2
    settings.iterationNum = 0;
    settings.doSaveDesignVarsToCSVFile = 0;
    settings.doPlotFinal = 1;
    %  settings.terminationCriteria =0.1; % 10%
    settings.terminationCriteria =0.001; % 3%
    
end

settings= settings.UpdateVolTargetsAndObjectiveWeights();
settings
onlyTopChangeOnFirstIteration = 1; % 1 = true, 0 = false;
% material properties Object
matProp = MaterialProperties;

% ---------------------------------
% Initialization of varriables
% ---------------------------------
designVars = DesignVars(settings);
fractionCurrent_V1Local =0;
if(settings.doUseMultiElePerDV ==1)
    % ------------------------------
    % Multiple design vars per element.
    % ------------------------------
    settings = settings.CalculateDesignVarsPerFEAelement();
    designVars.x(1:settings.numVarsY,1:settings.numVarsX) = settings.totalVolume; % artificial density of the elements
    designVars.w(1:settings.numVarsY,1:settings.numVarsX)  = 1; % actual volume fraction composition of each element
    designVars.temp1(1:settings.numVarsY,1:settings.numVarsX) = 0;
    designVars.temp2(1:settings.numVarsY,1:settings.numVarsX) = 0;
    %designVars.complianceSensitivity(1:settings.nely,1:settings.nelx) = 0;
    if (settings.doPlotStress == 1)
        designVars.totalStress(1:settings.numVarsY,1:settings.numVarsX) = 0;
    end
    designVars.g1elastic(1:settings.numVarsY,1:settings.numVarsX) = 0;
    designVars.g1heat(1:settings.numVarsY,1:settings.numVarsX) = 0;
    
else
    % ------------------------------
    % Normal case, 1 design var per element
    % ------------------------------
    designVars.x(1:settings.nely,1:settings.nelx) = settings.totalVolume; % artificial density of the elements
    designVars.w(1:settings.nely,1:settings.nelx)  = 1; % actual volume fraction composition of each element
    designVars.temp1(1:settings.nely,1:settings.nelx) = 0;
    designVars.temp2(1:settings.nely,1:settings.nelx) = 0;
    %designVars.complianceSensitivity(1:settings.nely,1:settings.nelx) = 0;
    if (settings.doPlotStress == 1)
        designVars.totalStress(1:settings.nely,1:settings.nelx) = 0;
    end
    designVars.g1elastic(1:settings.nely,1:settings.nelx) = 0;
    designVars.g1heat(1:settings.nely,1:settings.nelx) = 0;
end

designVars = designVars.CalcIENmatrix(settings);
designVars =  designVars.CalcElementLocation(settings);
designVars = designVars.PreCalculateXYmapToNodeNumber(settings);
designVars = designVars.CalcElementXYposition(settings);

masterloop = 0;
FEACalls = 0;
status=0;

% macro_meso_iteration = 1;

if ( settings.mode == 1 || settings.mode == 3 || settings.mode == 10 || settings.mode ==5)
    matProp=  matProp.ReadConstitutiveMatrixesFromFiles(  settings);
end

if ( settings.mode == 10)
    designVars= ReadXMacroFromCSV( settings,designVars);
end

xx= settings.nelx;
yy = settings.nely;
if(settings.doUseMultiElePerDV) % if elements per design var.
    settings = settings.CalculateDesignVarsPerFEAelement();
    xx = settings.numVarsX;
    yy = settings.numVarsY;
end

% START ITERATION
while status == 0  && masterloop<=settings.maxMasterLoops && FEACalls<=settings.maxFEACalls
    masterloop = masterloop + 1;
    
    % --------------------------------
    % Topology Optimization
    % --------------------------------
    if ( settings.mode == 1 || settings.mode == 3 || settings.mode == 10 || settings.mode ==5)
        
        if(settings.macro_meso_iteration==1 || (onlyTopChangeOnFirstIteration == 0))
            for loopTop = 1:1
                designVars = designVars.CalculateSensitivies(settings, matProp, masterloop);
                [vol1Fraction, vol2Fraction] =  designVars.CalculateVolumeFractions(settings);
                
                FEACalls = FEACalls+1;
                % normalize the sensitivies  by dividing by their max values.
                temp1Max =-1* min(min(designVars.temp1));
                designVars.temp1 = designVars.temp1/temp1Max;
                temp2Max = -1* min(min(designVars.temp2));
                designVars.temp2 = designVars.temp2/temp2Max;
                
                designVars.dc = settings.w1*designVars.temp1+settings.w2*designVars.temp2; % add the two sensitivies together using their weights
                
                % FILTERING OF SENSITIVITIES
                
                [designVars.dc]   = check(xx,yy,settings.rmin,designVars.x,designVars.dc);
                % DESIGN UPDATE BY THE OPTIMALITY CRITERIA METHOD
                [designVars.x]    = OC(xx,yy,designVars.x,settings.totalVolume,designVars.dc, designVars, settings);
                % PRINT RESULTS
                %change = max(max(abs(designVars.x-designVars.xold)));
                disp([' FEA calls.: ' sprintf('%4i',FEACalls) ' Obj.: ' sprintf('%10.4f',designVars.c) ...
                    ' Vol. 1: ' sprintf('%6.3f', vol1Fraction) ...
                    ' Vol. 2: ' sprintf('%6.3f', vol2Fraction) ...
                    ' Lambda.: ' sprintf('%6.3f',designVars.lambda1  )])
                
                densitySum = sum(sum(designVars.x));
                designVars.storeOptimizationVar = [designVars.storeOptimizationVar;designVars.c, designVars.cCompliance, designVars.cHeat,vol1Fraction,vol2Fraction,fractionCurrent_V1Local,densitySum];
                
                p = plotResults;
                p.plotTopAndFraction(designVars,  settings, matProp, FEACalls); % plot the results.
                status = TestForTermaination(designVars, settings);
                if(status ==1)
                    m = 'break in topology'
                    break;
                end
            end
        end
    end
    
    % exit the master loop if we termination criteria are true.
    if(status ==1)
        m = 'exiting master (break in topology)'
        break;
    end
    
    % --------------------------------
    % Volume fraction optimization
    % --------------------------------
    if ( settings.mode ==2 || settings.mode ==3 || settings.mode == 10 || settings.mode ==5)
        for loopVolFrac = 1:1
            designVars = designVars.CalculateSensitivies( settings, matProp, masterloop);
            FEACalls = FEACalls+1;
            
            % for j = 1:5
            [vol1Fraction, vol2Fraction] =  designVars.CalculateVolumeFractions(settings);
            
            totalVolLocal = vol1Fraction+ vol2Fraction;
            fractionCurrent_V1Local = vol1Fraction/totalVolLocal;
            targetFraction_v1 = settings.v1/(settings.v1+settings.v2);
            
            % Normalize the sensitives.
            temp1Max = max(max(abs(designVars.g1elastic)));
            designVars.g1elastic = designVars.g1elastic/temp1Max;
            temp2Max = max(max(abs(designVars.g1heat)));
            designVars.g1heat = designVars.g1heat/temp2Max;
            
            g1 = settings.w1*designVars.g1elastic+settings.w2*designVars.g1heat; % Calculate the weighted volume fraction change sensitivity.
            G1 = g1 - designVars.lambda1 +1/(designVars.mu1)*( targetFraction_v1-fractionCurrent_V1Local); % add in the lagrangian
            designVars.w = designVars.w+settings.timestep*G1; % update the volume fraction.
            
            designVars.w = max(min( designVars.w,1),0);    % Don't allow the    vol fraction to go above 1 or below 0
            designVars.lambda1 =  designVars.lambda1 -1/(designVars.mu1)*(targetFraction_v1-fractionCurrent_V1Local)*settings.volFractionDamping;
            
            
            % PRINT RESULTS
            %change = max(max(abs(designVars.x-designVars.xold)));
            densitySum = sum(sum(designVars.x));
            designVars.storeOptimizationVar = [designVars.storeOptimizationVar;designVars.c, designVars.cCompliance, designVars.cHeat,vol1Fraction,vol2Fraction,fractionCurrent_V1Local,densitySum];
            p = plotResults;
            p.plotTopAndFraction(designVars, settings, matProp,FEACalls ); % plot the results.
            
            
            disp([' FEA calls.: ' sprintf('%4i',FEACalls) ' Obj.: ' sprintf('%10.4f',designVars.c) ...
                ' Vol. 1: ' sprintf('%6.3f', vol1Fraction) ...
                ' Vol. 2: ' sprintf(    '%6.3f', vol2Fraction) ...
                ' Lambda.: ' sprintf('%6.3f',designVars.lambda1  )])
            % obj.storeOptimizationVar = [obj.storeOptimizationVar;obj.c,  obj.cCompliance, obj.cHeat ];
            status = TestForTermaination(designVars, settings);
            if(status ==1)
                m = 'break in vol fraction'
                break;
            end
        end
        
        
    end
end

if ( settings.mode ==2 || settings.mode ==3 || settings.mode == 10 || settings.mode ==5)
    folderNum = settings.iterationNum;
    if(1==1)
        [~, t2] = size(settings.loadingCase);
        
        for loadcaseIndex = 1:t2
            %             loadcase = settings.loadingCase(loadcaseIndex);
            p.plotTopAndFraction(designVars, settings, matProp,FEACalls ); % plot the results.
            plotStrainField(settings,designVars,folderNum,loadcaseIndex)
            nameGraph = sprintf('./gradTopOptimization%fwithmesh%i_load%i.png', settings.w1,settings.macro_meso_iteration,loadcaseIndex);
            print(nameGraph,'-dpng');
            hi=  figure(1);
            cla(hi);
        end
    end
    
    
    outname = sprintf('./out%i/storeOptimizationVarMacroLoop%i.csv',folderNum,settings.macro_meso_iteration);
    csvwrite(outname,designVars.storeOptimizationVar);
    status
end
% ---------------------------------------------
%
%         MESO DESIGN TESTING, MODE = 4
%         debugging meso design only
%
% ---------------------------------------------
% For testing only
if(settings.mode ==4) % meso-structure design
    TestMesoDesign(designVars,settings,matProp);
end

% ---------------------------------------------
%
%         SAVE MACRO PROBLEM TO CSV FILES = MODE 5
%         the macro problem must actually run, so the macro topology and
%         vol fraction must also have an  || settings.mode ==5
%
% ---------------------------------------------

if(settings.mode ==5  || settings.mode ==10)
    % write the displacement field to a .csv
    SaveMacroProblemStateToCSV(settings,designVars,matProp);
end


% ---------------------------------------------
%
%         LOOP OVER MACRO ELEMENTS AND DESIGN MESO STRUCTURE = MODE 6
%
% ---------------------------------------------
if(settings.mode ==6 ||settings.mode ==8 || settings.mode ==10)
    % the design var object is huge, so I want to garbage collect after
    % saving the important data to disk (.csv files).
    clear designVars
    
    
    if(settings.doUseMultiElePerDV==1) % if elements per design var.
        ne =  settings.numVarsX*settings.numVarsY;
    else
        ne = settings.nelx*settings.nely; % number of elements
        %SavedDmatrix = zeros(ne,9);
    end
    
    checkedElements = CalculateCheckedElements(ne, settings);
    allelements = 1:ne;
    nonCheckedElements = setdiff(allelements, checkedElements);
    
    if(settings.parallel==1)
        % Set up parallel computing.
        myCluster = parcluster('local');
        myCluster.NumWorkers = settings.numWorkerProcess;
        saveProfile(myCluster);
        myCluster
        
        poolobj = gcp('nocreate'); % If no pool,create new one.
        if isempty(poolobj)
            parpool('local',4)
            poolsize = 4;
        else
            poolsize = poolobj.NumWorkers;
        end
        poolsize
        
        % --------------------------------------------------
        % loop over the macro elements and design a meso structure,
        %  parallel using parfor
        % --------------------------------------------------
        parfor_progress(ne);
        
        [~,numElementsInChecked] = size(checkedElements);
        parfor  e = 1:numElementsInChecked
%             checkedElements = CalculateCheckedElements(ne, settings);
            elocal = checkedElements(e);
            settingscopy = settings; % need for parfor loop.
            settingscopy.useAjacentLocal = 0;
            MesoDesignWrapper(settingscopy,elocal, ne,matProp);
            parfor_progress;
        end
        [~, NumElementsInnonCheckedElements ]= size(nonCheckedElements);
        parfor  e = 1:NumElementsInnonCheckedElements
            elocal = nonCheckedElements(e);
            settingscopy = settings; % need for parfor loop.
            settingscopy.useAjacentLocal = 1;
            MesoDesignWrapper(settingscopy,elocal, ne,matProp);
            parfor_progress;
        end
        parfor_progress(0);
        
    else
        % --------------------------------------------------
        % loop over the macro elements and design a meso structure,
        % no parallel
        % --------------------------------------------------
     
        if(settings.singleMesoDesign~= 1)
               settings.mesoplotfrequency = 50;
            for  e = checkedElements
                settingscopy = settings; % need for parfor loop.
                settingscopy.useAjacentLocal = 0;
                MesoDesignWrapper(settingscopy,e, ne,matProp);
            end
            
               settings.mesoplotfrequency = 50;
            for  e = nonCheckedElements
                settingscopy = settings; % need for parfor loop.
                settingscopy.useAjacentLocal = 1;
                MesoDesignWrapper(settingscopy,e, ne,matProp);
            end
        end
        
        if(settings.singleMesoDesign == 1)
            SingleMesoStuctureWrappe(settings, ne,matProp);
        end
        
    end % end parallel
    clear designVarsMeso
end

% -------------------------------------
% Generate macro-meso complete structure.
% 7 is for testing the recombining of the meso structures.
%
% Loop over the elements and get the design fields, and make one
% huge array showing the actual shape of the structure, tile the
% -------------------------------------
if(settings.mode ==7||settings.mode ==8  || settings.mode ==10 )
    close all
    p = plotResults;
    
    %     mesoSettings = settings;
    %     mesoSettings.nelx = settings.nelxMeso;
    %     mesoSettings.nely = settings.nelyMeso;
    temp= settings.mesoAddAdjcentCellBoundaries;
    settings.mesoAddAdjcentCellBoundaries=0;
    [designVarsMeso, mesoSettings] = GenerateDesignVarsForMesoProblem(settings,1);
    settings.mesoAddAdjcentCellBoundaries=temp;
    
    mesoSettings.doUseMultiElePerDV =settings.doUseMultiElePerDV;
    numTilesX=settings.numTilesX;
    numTilesY = settings.numTilesY;
    
    
    if(settings.doUseMultiElePerDV==1) % if elements per design var.
        settings = settings.CalculateDesignVarsPerFEAelement();
        ne =  settings.numVarsX*settings.numVarsY;
        totalX=settings.numVarsX*mesoSettings.nelx*numTilesX;
        totalY=settings.numVarsY*mesoSettings.nely*numTilesY;
        completeStruct = zeros(totalY,totalX);
    else
        % Generate huge area
        totalX=settings.nelx*mesoSettings.nelx*numTilesX;
        totalY=settings.nely*mesoSettings.nely*numTilesY;
        
        completeStruct = zeros(totalY,totalX);
        ne = settings.nelx*settings.nely; % number of elements
    end
    
    %     xaverage = zeros(mesoSettings.nely,mesoSettings.nelx);% [];
    if(settings.singleMesoDesign)
        temp1average = zeros(mesoSettings.nely,mesoSettings.nelx);% [];
        %         if(settings.macro_meso_iteration>1)
        %              outname = sprintf('./out%i/singleMesoD_mesoMacro%i.csv',folderNum,macro_meso_iteration);
        %            csvwrite(outname, D_homog);
        folderNum=settings.iterationNum;
        elementNumber=1
        outname = sprintf('./out%i/densityfield%iforElement%i.csv',folderNum,settings.macro_meso_iteration,elementNumber);
        savedX=csvread(outname);
        
        %         end
    end
    count = 1;
    
    
    for e = 1:ne
        fprintf('element %i of %i\n',e,ne);
        macroElementProps = GetMacroElementPropertiesFromCSV(settings,e);
        % Check if void
        if(macroElementProps.density>settings.voidMaterialDensityCutOff)
            if(settings.singleMesoDesign ~=1)
                x=GetMesoUnitCellDesignFromCSV(settings,e);
            else
                x = savedX;
            end
            yShift = (macroElementProps.yPosition-1)*mesoSettings.nely*numTilesY+1;
            xShift = (macroElementProps.xPosition-1)*mesoSettings.nelx*numTilesX+1;
            designVarsMeso.x = x;
            designVarsMeso=TileMesoStructure(mesoSettings, designVarsMeso);
            completeStruct(yShift:(yShift+mesoSettings.nely*numTilesY-1),xShift:(xShift+mesoSettings.nelx*numTilesX-1))=designVarsMeso.xTile;
            
        end
    end
    
    %           subplot(2,2,3);
     plotname = sprintf('complete structure %i',settings.macro_meso_iteration);
    p.PlotArrayGeneric( completeStruct, plotname)
    rgbSteps = 100;  caxis([0,1]);
    map = colormap; % current colormap
    middPoint = floor(rgbSteps/4);
    map(1:middPoint,:) = [ones(middPoint,1),ones(middPoint,1),ones(middPoint,1)];
    for zz =    middPoint:rgbSteps
        map(zz,:) = [0,               1- zz/rgbSteps, 0.5];
    end
    colormap(map)
    %     colorbar
    freezeColors
    nameGraph = sprintf('./completeStucture%f_macroIteration_%i.png', settings.w1,settings.macro_meso_iteration);
    print(nameGraph,'-dpng', '-r800')
     outname = sprintf('./completeStucture%f_macroIteration_%i.csv', settings.w1,settings.macro_meso_iteration);
      csvwrite(outname,completeStruct);
    
    % Write ascii STL from gridded data
    %     [X,Y] = deal(1:40);             % Create grid reference
    %     X = 1:totalX;
    %     Y = 1:totalY;
    %     Z = completeStruct*100;                  % Create grid height
    %     nameGraph = sprintf('./stl%f_macroIteration_%i.stl', settings.w1,settings.macro_meso_iteration);
    %     stlwrite(nameGraph,X,Y,Z,'mode','binary')
    
    
end




% test for termaination of the function.
% normalize the objectives, compare to a moving average. If moving average
% below target, then return 1
% if not terminated, then return 0
function status = TestForTermaination(designVars, settings)
status = 0;
y2 = designVars.storeOptimizationVar(:,2); % Elastic Compliance

t = settings.terminationAverageCount;
if(size(y2)<(t+3))
    return;
end


y3 = designVars.storeOptimizationVar(:,3); % Heat Compliance
y4 = designVars.storeOptimizationVar(:,4); % material 1
y5 = designVars.storeOptimizationVar(:,5); % material 2

avg_y2 = FindAvergeChangeOfLastValue(y2,settings); % elastic objective
avg_y3 = FindAvergeChangeOfLastValue(y3,settings); % heat objective
avg_y4 = FindAvergeChangeOfLastValue(y4,settings); % material 1
avg_y5 = FindAvergeChangeOfLastValue(y5,settings); % material 2




tt = settings.terminationCriteria;
if(        avg_y2<tt ...
        && avg_y3<tt ...
        && avg_y4<tt ...
        && avg_y5<tt)
    status=1;
    % print the vars to screen
    [avg_y2 avg_y3 avg_y4 avg_y5 ]
end



