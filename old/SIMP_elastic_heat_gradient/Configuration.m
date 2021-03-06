classdef Configuration
    
    properties
        % --------------------------------------
        % %% Settings
        % --------------------------------------------
        
        
        nelx = 40; % 40 # of elements in the x direcction
        nely = 20; % 18 number of elements in the y direction
        penal = 3; % penality used for the SIMP method
        rmin = 2; % smoothing radius for sensitivity smoothing.
        % Optimization mode and configurations
        mode =4; % 1 = topology only, 2 = material optimization only. 3 = both,4 = meso only. 5 = meso-structure testing
        referenceTemperature = 0; % for thermal expansion, assume that there is not strain when at this temperature.
        addThermalExpansion = 0; % Set to 1 to incorporate thermal expansion
        timestep = 0.1; % time step for the volume fraction update algorithm
        volFractionDamping = 0.1;
        iterationsPerPlot = 5;
        w1 = 0; % weight elastic for multi-objective
        w2;
        voidMaterialDensityCutOff = 0.3; % everything below this density is considered void.
        % Plotting information
        doPlotVolFractionDesignVar = 0;
        doPlotTopologyDesignVar = 0;
        doPlotHeat = 0;
        doPlotHeatSensitivityTopology = 0;
        doPlotStress = 0;
        doPlotFinal = 0;
        doPlotMetrics = 0;
        doSaveDesignVarsToCSVFile = 0; % set to 1 to write plotFinal csv file instead
        v1 = 0.2; % amount of material 1 to use. default to 20%
        v2 = 0.2; % amount of material 2 to use. default to 20%
        totalVolume; % = v1+v2;
        iterationNum=0; %  used for parallel computing.
        maxFEACalls = 50;
        maxMasterLoops = 15;
        terminationAverageCount = 4; % the average change over this number of iterations must be below the termination criteria
        terminationCriteria = 0.01; % if the normalized average change over  terminationAverageCount of iterations is below this value then termainted. ie. 1% change
        % not much faster.
        useGPU = 0; % set to 1 to try to solve matrix using gpu
        % -----------------
        % Use different mixture rules for effective elastic properteis
        % 1. Simple linear interpolation, Vigot rule of miztures E = w(E1)*(1-w)*E2
        % 2. Hashin�Shtrikam law (average of upper and lower boundary)
        % 3. Reuss -rule, 1/E = w/E1+(1-w)/E2 (not implemented yet)
        % 4. Mori and Tanaka, metal ceramic composite
        % ---------------------
        elasticMaterialInterpMethod = 1;
        % -----------------
        % Use different mixture rules for effective Heat properteis
        % 1. Simple linear interpolation, Vigot rule of miztures E = w(E1)*(1-w)*E2
        % 3. Reuss -rule, 1/E = w/E1+(1-w)/E2 (not implemented yet)
        % 4. Kingery's, metal ceramic composite
        % 5. Hashin�Shtrikam law (average of upper and lower boundary)
        % ---------------------
        heatMaterialInterpMethod = 1;
        
        
        loadingCase = 111; % left clamped
        
        % --------------
        % Meso tiling info
        %--------------
        numTilesX = 3;
        numTilesY = 3;
        sensitivityTile = 5; % use this tile to calcualte the sensitivity
        plotSensitivityWhilerunning = 0;
       
        
    end
    
    methods        
        function obj = Configuration()
            % Constructor.
        end
        
        function [obj]= UpdateVolTargetsAndObjectiveWeights(obj)
            % Do not allow w1 to be zero. Divide by zero messes stuff up.
            if(obj.w1 ==0)
                obj.w1=0.00001;
            end
            obj.w2  = 1- obj.w1; % weight heat transfer
            obj.totalVolume = obj.v1+obj.v2;
        end        
    end
end