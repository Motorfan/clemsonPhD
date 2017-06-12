function []=GenerateRhoFunctionOfExxEyy(config)
close all
% p = plotResults;
DV = DesignVars(config);
ne = config.nelx*config.nely; % number of elements

%--------------------------------------------
% Get the density field
%--------------------------------------------
macro_meso_iteration = config.macro_meso_iteration;
%macroElementProps = macroElementProp;
% macroElementProps.elementNumber = e;
folderNum = config.iterationNum;
% GET the saved element to XY position map (needed for x and w vars retrival)
outname = sprintf('./out%i/elementXYposition%i.csv',folderNum,macro_meso_iteration);
elementXYposition=csvread(outname);
% Get the density field
outname = sprintf('./out%i/SIMPdensityfield%i.csv',folderNum,macro_meso_iteration);
xxx = csvread(outname);



% Get the Exx field
outname = sprintf('./out%i/ExxValues%i.csv',folderNum,macro_meso_iteration);
ExxMacro = csvread(outname);

% Get the Eyy field
outname = sprintf('./out%i/EyyValues%i.csv',folderNum,macro_meso_iteration);
EyyMacro =csvread(outname);

% Get the Theta field
outname = sprintf('./out%i/ThetaValues%i.csv',folderNum,macro_meso_iteration);
ThetaMacro = csvread(outname);



matProp=MaterialProperties;
DV.x = xxx;
rhoArray = [];
ExxArray = [];
EyyArray = [];
thetaArray=[];
MacroExxColumn=[];
MacroEyyColumn=[];
MacroThetaColumn=[];
RhoColumn=[];

if(config.validationModeOn==1)
    ne= config. validationGridSizeNelx ^3;
end
ne

if 1==1
    for e = 1:ne %ne:-1:1
        strangeResultsFlag=0;
        fprintf('element %i of %i\n',e,ne);
        macroElementProps.elementNumber=e;
        elementNumber=e;
        if(config.validationModeOn==0)
            % ---------------
            %    Multiscale topology optimization case.
            % ---------------
            results = elementXYposition(macroElementProps.elementNumber,:);
            macroElementProps.yPos = results(1);
            macroElementProps.xPos = results(2);
            
            
            macroElementProps.densitySIMP = xxx(macroElementProps.yPos,macroElementProps.xPos );
            ActualThetaValue = ThetaMacro(macroElementProps.yPos,macroElementProps.xPos );
            ActualExx = ExxMacro(macroElementProps.yPos,macroElementProps.xPos );
            ActualEyy = EyyMacro(macroElementProps.yPos,macroElementProps.xPos );
        elseif(config.validationModeOn==1)
            % ---------------
            %    Meso Validation Case
            % ---------------
            macroElementProps.yPos = 1;
            macroElementProps.xPos = e;
            macroElementProps.densitySIMP =1;
            ActualThetaValue = ThetaMacro(e );
            ActualExx = ExxMacro(e );
            ActualEyy = EyyMacro(e);
            
            numValues = config.validationGridSizeNelx ^3;
            DV.Exx = ones(1,numValues);
            DV.Eyy= ones(1,numValues);
            DV.t= ones(1,numValues);
            DV.w= ones(1,numValues);
            DV.x =ones(1,numValues);;
            
        end
        
        
        
        % ---------------------------------
        % If SIMP density is above minimum, then find the equivalent macro
        % properties from the D_meso matrix.
        % ---------------------------------
        if(macroElementProps.densitySIMP>config.voidMaterialDensityCutOff)
            % save the psuedo strain values
            %         outname = sprintf('./out%i/psuedostrain_Ite%i_forElement%i.csv',folderNum,macro_meso_iteration,elementNumber);
            %     p =  macroElementProperties.psuedoStrain;
            %               p =  csvread(outname);
            
            % save the final volume
            outname = sprintf('./out%i/volumeUsed_Ite%i_forElement%i.csv',folderNum,macro_meso_iteration,elementNumber);
            %              v =    configMeso.totalVolume;
            %     csvwrite(outname,v);
            if exist(outname, 'file') ~= 2
                 fprintf('File does not exist. Retry\n');
                combinedTopologyOptimization('1', '1', '1','100', int2str(elementNumber));
                
            end
            v =  csvread(outname);
            if(v>1)
                message = 'Volume is greater than 1???'
                break
            end
            
            
            outname = sprintf('./out%i/Dmatrix_%i_forElement_%i.csv',folderNum,macro_meso_iteration,elementNumber);
            if exist(outname, 'file') ~= 2
                continue;
            end
            %          outname = sprintf('./out%i/DsystemIter%i_Element_%i.csv',folderNum,macro_meso_iteration,elementNumber);
            try
                Din = csvread(outname);
            catch
                str = sprintf('error reading a file\n'); display(str);
                continue
                
            end
            
            Dcalculated= matProp.getDmatMatrixTopExxYyyRotVars(config, macroElementProps.densitySIMP,ActualExx, ActualEyy,ActualThetaValue,1);
            
            % -------------------
            % STEP 2, SET UP GOLDEN RATIO METHOD TO FIND
            % OPTIMAL THETA FOR ROTATION
            % -------------------
            
            n = 0;
            epsilon = pi/180; % 1 DEGREES ACCURACY
            x0 = 0; %lower_bracket;
            x3 =pi/2;% higher_bracket;
            leng = x3-x0;
            grleng = leng*config.gr ; % golden ratio lenth
            x1 = x3 - grleng;
            x2 = x0 + grleng;
            Dout = matProp.rotateDmatrix(config,x1, Din);
            sumZeroTerms =abs( Dout(1,3))+abs(Dout(2,3))+abs(Dout(3,1))+abs(Dout(3,2));
            fx1=sumZeroTerms;
            
            Dout = matProp.rotateDmatrix(config,x2, Din);
            sumZeroTerms =abs( Dout(1,3))+abs(Dout(2,3))+abs(Dout(3,1))+abs(Dout(3,2));
            fx2=sumZeroTerms;
            
            verbosity = 0;
            recordFx=[];
            
            while(1 == 1)
                if(verbosity ==1)
                    str = sprintf('loop# = %d, x0 = %f, x1 = %f, x2 = %f, x3 = %f, fx1 = %f, fx2 = %f\n', n, x0, x1, x2, x3, fx1, fx2); display(str);
                end
                
                if(fx1<=fx2) % less than or equal
                    % x0 = x0; % x0 stays the same
                    x3 = x2; % the old x2 is now x3
                    x2 = x1; % the old x1 is now x2
                    fx2 = fx1;
                    leng = x3 - x0; % find the length of the interval
                    x1 = x3 - leng*config.gr; % find golden ratio of length, subtract it from the x3 value
                    
                    Dout = matProp.rotateDmatrix(config,x1, Din);
                    fx1 =abs( Dout(1,3))+abs(Dout(2,3))+abs(Dout(3,1))+abs(Dout(3,2));
                    % fx1 = obj.EvaluteARotation(U,topDensity, material1Fraction,Exx,Eyy,x1,matProp, config); % calculate the fx
                    
                elseif(fx1>fx2) % greater than
                    x0 = x1; % the old x1 is now x0
                    x1 = x2; % the old x2 is now the new x1
                    fx1 = fx2;
                    % x3 = x3; % x3 stays the same.
                    
                    leng = (x3 - x0); % find the length of the interval
                    x2 = x0 + leng*config.gr; % find golden ratio of length, subtract it from the x3 value
                    %                 fx2 = obj.EvaluteARotation(U,topDensity, material1Fraction,Exx,Eyy,x2,matProp, config);  % calculate the fx
                    Dout = matProp.rotateDmatrix(config,x2, Din);
                    fx2 =abs( Dout(1,3))+abs(Dout(2,3))+abs(Dout(3,1))+abs(Dout(3,2));
                end
                
                % check to see if we are as close as we want
                if(leng < epsilon || n>100)
                    break;
                end
                n = n +1; % increment
                
            end
            Theta = (x2 + x3)/2;
            
            
            % plot the domain and range of the Kappa function
            if(1==0)
                thetaValuesToTest=0:epsilon:pi/2;
                for i = thetaValuesToTest
                    Dout = matProp.rotateDmatrix(config,i, Din);
                    fxRecord =abs( Dout(1,3))+abs(Dout(2,3))+abs(Dout(3,1))+abs(Dout(3,2));
                    recordFx=[recordFx fxRecord];
                end
                
                xValues = [0 Theta pi/2];
                yValues = [ 0 1 1]*max(recordFx);
                plot(thetaValuesToTest,recordFx);
                hold on
                stairs(xValues,yValues);
                titleText = sprintf('Kappa function for element %i',e);
                title(titleText);
                hold off
            end
            
            
            Din=Din*1/(macroElementProps.densitySIMP^(config.penal));
            Dout = matProp.rotateDmatrix(config,Theta, Din);
            
            % Scale UP based on the rho (x) density
            % Scale down on the denominator
            denominator = 1-matProp.v^2;
            %          denominator = 1;
            Etemp1=Dout(1,1)*denominator;
            Etemp2=Dout(2,2)*denominator;
            Theta = pi/2-Theta;
            
            
            if(ActualExx>ActualEyy)
                Exx=max(Etemp1,Etemp2);
                Eyy=min(Etemp1,Etemp2);
            else %ActualExx<ActualEyy
                Exx=min(Etemp1,Etemp2);
                Eyy=max(Etemp1,Etemp2);
            end
            diffDs=Din-Dcalculated;
            
            if(config.validationModeOn==0)
                if(Exx>matProp.E_material1)
                    Exx=matProp.E_material1 ;
                    strangeResultsFlag=1;
                end
                
                if(Eyy>matProp.E_material1)
                    Eyy=matProp.E_material1 ;
                    strangeResultsFlag=1;
                end
            end
            
            
            
            
            % Also, there is some difficulty when actualTheta is 0 or pi/2
            diffTheta = abs( ActualThetaValue-Theta);
            
            if(diffTheta>(pi/2-epsilon))
                if(Theta>pi/4)
                    Theta=pi/2-Theta;
                else
                    Theta=pi/2-Theta;
                end
                
                %             str = sprintf('Theta on wrong boundary. Switching values. ')
                diffTheta = abs( ActualThetaValue-Theta); % The new Diff Theta
            end
            
            
            % in the case  where, Exx = Eyy, then the material is basically
            % isotropic and rotating to find the orthotropic orientaiton will
            % not work. In this case, set the theta to the actualTheta
            % the criteria is that Exx and Eyy must be within 0.2% of each
            % other's value.
            if(abs(100*(Exx-Eyy)/Exx)<5)
                %            if(abs(100*(ActualExx-ActualEyy)/ActualEyy)<5)
                Theta=ActualThetaValue;
                %             str = sprintf('Exx = Eyy, setting theta to sys theta')
            end
            
            
            diffX = ActualExx-Exx;
            diffY = ActualEyy-Eyy;
            
            
            relativeErrorDiffExx = abs(diffX)/ActualExx;
            relativeErrorDiffyy = abs(diffY)/ActualEyy;
            relativeErrorDiffTheta = abs(diffTheta)/ActualThetaValue;
            
            maxError = 0.1;
            LargeErroFlag = 0;
            
            if(1==0)
                if(relativeErrorDiffExx>maxError)
                    fprintf('%i Exx Large Error: Target  = %f mesovalue = %f\n', e,ActualExx,Exx)
                    LargeErroFlag = 1;
                end
                if(relativeErrorDiffyy>maxError)
                    fprintf('%i Eyy Large Error: Target  = %f mesovalue = %f\n', e,ActualEyy,Eyy)
                    LargeErroFlag = 1;
                end
                if( relativeErrorDiffTheta>maxError)
                    fprintf('%i Theta Large Error: Target  = %f mesovalue = %f\n', e,ActualThetaValue,Theta)
                    LargeErroFlag = 1;
                end
                
                if( LargeErroFlag ==1)
                    fprintf('More Data: Target: Value: Relative Error\n')
                    fprintf('Exx %f %f %f\n',ActualExx,Exx,relativeErrorDiffExx)
                    fprintf('Eyy %f %f %f\n',ActualEyy,Eyy,relativeErrorDiffyy)
                    fprintf('Theta %f %f %f\n',ActualThetaValue,Theta,relativeErrorDiffTheta)
                    fprintf('rho = %f\n',v);
                    %: Targets %f %f %f, Meso %f %f %f, Rho=%f\n',ActualExx,ActualEyy,ActualThetaValue,Exx,Eyy,Theta,v)
                end
            end
            
            
            
            
            
            %DV.x already saved.
            DV.Exx(macroElementProps.yPos,macroElementProps.xPos)=Exx;
            DV.Eyy(macroElementProps.yPos,macroElementProps.xPos)=Eyy;
            DV.t(macroElementProps.yPos,macroElementProps.xPos)=Theta;
            DV.w(macroElementProps.yPos,macroElementProps.xPos)=v;
            
            
            %                 objectiveValue = ObjectiveCalculateEffectiveVars(x,DmatrixIN, matProp,config);
            
            if(strangeResultsFlag==0)
                rhoArray = [rhoArray;v];
                ExxArray=[ExxArray;Exx];
                EyyArray=[EyyArray;Eyy];
                thetaArray=[thetaArray;Theta];
                
                MacroExxColumn=[MacroExxColumn;ActualExx*macroElementProps.densitySIMP^(config.penal)];
                MacroEyyColumn=[MacroEyyColumn;ActualEyy*macroElementProps.densitySIMP^(config.penal)];
                MacroThetaColumn=[MacroThetaColumn;ActualThetaValue];
                RhoColumn=[RhoColumn;v];
            end
            
            
            
        else
            DV.Exx(macroElementProps.yPos,macroElementProps.xPos)=ActualExx;
            DV.Eyy(macroElementProps.yPos,macroElementProps.xPos)=ActualEyy;
            DV.t(macroElementProps.yPos,macroElementProps.xPos)=ActualThetaValue;
            DV.w(macroElementProps.yPos,macroElementProps.xPos)=0;
            
        end
    end
    
    folderCells = {sprintf('out%i',folderNum),'data'};
    for i = 1:2
        folderName = char(folderCells(i));
        % save the Exx field
        %     outname = sprintf('./out%i/ExxSubSysValues%i.csv',folderNum,macro_meso_iteration);
        outname = sprintf('./%s/ExxSubSysValues%i.csv',folderName,macro_meso_iteration);
        csvwrite( outname,DV.Exx);
        
        % save the Eyy field
        %     outname = sprintf('./out%i/EyySubSysValues%i.csv',folderNum,macro_meso_iteration);
        outname = sprintf('./%s/EyySubSysValues%i.csv',folderName,macro_meso_iteration);
        csvwrite( outname,DV.Eyy);
        
        % save the Theta field
        %     outname = sprintf('./out%i/ThetaSubSysValues%i.csv',folderNum,macro_meso_iteration);
        outname = sprintf('./%s/ThetaSubSysValues%i.csv',folderName,macro_meso_iteration);
        csvwrite( outname, DV.t);
        
        % save the density field
        %     outname = sprintf('./out%i/densityUsedSubSysValues%i.csv',folderNum,macro_meso_iteration);
        outname = sprintf('./%s/densityUsedSubSysValues%i.csv',folderName,macro_meso_iteration);
        csvwrite( outname,  DV.w);
        
        %------------------------
        % Save the macro columns as well. This will help with future analysis
        % ----------------------------
        % save the MacroExxColumn
        %     outname = sprintf('./out%i/MacroExxColumn%i.csv',folderNum,macro_meso_iteration);
        outname = sprintf('./%s/MacroExxColumn%i.csv',folderName,macro_meso_iteration);
        csvwrite( outname,MacroExxColumn);
        
        % save the MacroEyyColumn
        %     outname = sprintf('./out%i/MacroEyyColumn%i.csv',folderNum,macro_meso_iteration);
        outname = sprintf('./%s/MacroEyyColumn%i.csv',folderName,macro_meso_iteration);
        csvwrite( outname,MacroEyyColumn);
        
        % save the MacroThetaColumn
        %     outname = sprintf('./out%i/MacroThetaColumn%i.csv',folderNum,macro_meso_iteration);
        outname = sprintf('./%s/MacroThetaColumn%i.csv',folderName,macro_meso_iteration);
        csvwrite( outname, MacroThetaColumn);
        
        % save the RhoColumn
        %     outname = sprintf('./out%i/RhoColumn%i.csv',folderNum,macro_meso_iteration);
        outname = sprintf('./%s/RhoColumn%i.csv',folderName,macro_meso_iteration);
        csvwrite( outname,  RhoColumn);
    end
    
    
    % --------------------------------------------------------
    %
    %    Meso Validation Case
    %
    % --------------------------------------------------------
    if(config.validationModeOn==1)
        
        % --------------------------
        % Plot the raw data showing the density as circles
        % --------------------------
        RhoColor=RhoColumn; % color
        circleSize = ones(size(RhoColumn))*100; % circle size.
        scatter3(MacroExxColumn,MacroEyyColumn,MacroThetaColumn,circleSize,RhoColor,'filled','MarkerEdgeColor','k')
        title(sprintf('Meso Validation,Density Plot '));
        colorbar
        xlabel('Exx');
        ylabel('Eyy');
        zlabel('Theta');
        %colormap('gray')
        % colormap(flipud(gray(256)));
        colormap('summer');
        
        nameGraph2 = sprintf('./MesoValiation_RawData%i.png', config.macro_meso_iteration);
        print(nameGraph2,'-dpng');
        
        
        % --------------------------
        % Plot the Exx Error as circles
        % --------------------------
        figure
        diffExx = MacroExxColumn-ExxArray;
        diffExx=abs(diffExx);
        ColorColumn=diffExx; % color
        circleSize = ones(size(ColorColumn))*100; % circle size.
        scatter3(MacroExxColumn,MacroEyyColumn,MacroThetaColumn,circleSize,ColorColumn,'filled','MarkerEdgeColor','k')
        title(sprintf('Exx Error as circles (Target - Actual)'));
        colorbar
        xlabel('Exx');
        ylabel('Eyy');
        zlabel('Theta');
        %colormap('gray')
        % colormap(flipud(gray(256)));
        colormap('summer');
        nameGraph2 = sprintf('./MesoValiation_ExxError%i.png', config.macro_meso_iteration);
        print(nameGraph2,'-dpng');
        
        % --------------------------
        % Plot the Eyy Error as circles
        % --------------------------
        figure
        diffEyy = MacroEyyColumn-EyyArray;
        diffEyy=abs(diffEyy);
        ColorColumn=diffEyy; % color
        circleSize = ones(size(ColorColumn))*100; % circle size.
        scatter3(MacroExxColumn,MacroEyyColumn,MacroThetaColumn,circleSize,ColorColumn,'filled','MarkerEdgeColor','k')
        title(sprintf('Eyy Error as circles (Target - Actual)'));
        colorbar
        xlabel('Exx');
        ylabel('Eyy');
        zlabel('Theta');
        %colormap('gray')
        % colormap(flipud(gray(256)));
        colormap('summer');
        nameGraph2 = sprintf('./MesoValiation_EyyError%i.png', config.macro_meso_iteration);
        print(nameGraph2,'-dpng');
        
        
        % --------------------------
        % Plot the Theta Error as circles
        % --------------------------
        figure
        diffTheta = MacroThetaColumn-thetaArray;
        diffTheta=abs(diffTheta);
        ColorColumn=diffTheta; % color
        circleSize = ones(size(ColorColumn))*100; % circle size.
        scatter3(MacroExxColumn,MacroEyyColumn,MacroThetaColumn,circleSize,ColorColumn,'filled','MarkerEdgeColor','k')
        title(sprintf('Theta Error as circles (Target - Actual)'));
        colorbar
        xlabel('Exx');
        ylabel('Eyy');
        zlabel('Theta');
        %colormap('gray')
        % colormap(flipud(gray(256)));
        colormap('summer');
        nameGraph2 = sprintf('./MesoValiation_ThetaError%i.png', config.macro_meso_iteration);
        print(nameGraph2,'-dpng');
        
        
        % --------------------------
        % Plot the Combined Normalized Error
        % --------------------------
        figure
        % take ABS, and normalize
        totalError = abs(diffExx)/matProp.E_material1+abs(diffEyy)/matProp.E_material1+abs(diffTheta)/(pi/2);
        ColorColumn=totalError; % color
        circleSize = ones(size(ColorColumn))*100; % circle size.
        scatter3(MacroExxColumn,MacroEyyColumn,MacroThetaColumn,circleSize,ColorColumn,'filled','MarkerEdgeColor','k')
        title(sprintf('Normalized Summed Error as circles for Exx, Eyy, Theta'));
        colorbar
        xlabel('Exx');
        ylabel('Eyy');
        zlabel('Theta');
        %colormap('gray')
        % colormap(flipud(gray(256)));
        colormap('summer');
        nameGraph2 = sprintf('./MesoValiation_combinedError%i.png', config.macro_meso_iteration);
        print(nameGraph2,'-dpng');
        
    end
end
% -----------------------------------
%
%    Generate surface fit. 
%   must be commented out for matlab to compile on cluster. 
%
% % -----------------------------------
% if(1==1)
%     MacroExxColumnTotal=[];
%     MacroEyyColumnTotal=[];
%     MacroThetaColumnTotal=[];
%     RhoColumnTotal=[];
%     folderName='data';
%     for i = 1:macro_meso_iteration
%         %------------------------
%         % read the macro columns as well. This will help with future analysis
%         % ----------------------------
%         % save the MacroExxColumn
% %         outname = sprintf('./out%i/MacroExxColumn%i.csv',folderNum,macro_meso_iteration);
%          outname = sprintf('./%s/MacroExxColumn%i.csv',folderName,macro_meso_iteration);
%         
%         MacroExxColumn=csvread(outname);
%         MacroExxColumnTotal=[MacroExxColumnTotal; MacroExxColumn];
%         
%         % save the MacroEyyColumn
% %         outname = sprintf('./out%i/MacroEyyColumn%i.csv',folderNum,macro_meso_iteration);
%            outname = sprintf('./%s/MacroEyyColumn%i.csv',folderName,macro_meso_iteration);
%         temp=csvread(outname);
%         MacroEyyColumnTotal=[MacroEyyColumnTotal; temp];
%         
%         % save the MacroThetaColumn
% %         outname = sprintf('./out%i/MacroThetaColumn%i.csv',folderNum,macro_meso_iteration);
%            outname = sprintf('./%s/MacroThetaColumn%i.csv',folderName,macro_meso_iteration);
%         temp=csvread(outname);
%         MacroThetaColumnTotal=[MacroThetaColumnTotal; temp];
%         
%         % save the RhoColumn
% %         outname = sprintf('./out%i/RhoColumn%i.csv',folderNum,macro_meso_iteration);
%           outname = sprintf('./%s/RhoColumn%i.csv',folderName,macro_meso_iteration);
%         temp=csvread(outname);
%         RhoColumnTotal=[RhoColumnTotal; temp];
%     end
%     
%     for jjj=1:5
%     % Add full dense case
%       MacroExxColumnTotal=[MacroExxColumnTotal; max(MacroExxColumnTotal)];
%       MacroEyyColumnTotal=[MacroEyyColumnTotal; max(MacroEyyColumnTotal)];
%       MacroThetaColumnTotal=[MacroThetaColumnTotal; 0];
%       RhoColumnTotal=[RhoColumnTotal;1];
%     end
%   
%     
%     x=MacroExxColumnTotal/matProp.E_material1;
%     y = MacroEyyColumnTotal/matProp.E_material1;
%     
%     z=RhoColumnTotal;
%     
%    options= fitoptions;
% %    options.Normalize ='on';
% %    options.fittype='poly22';
%      f1 = fit([x y],z,'poly33',options)
% %      f2 = fit([x y],z,'poly23', 'Exclude', z > 1);
%     o=Optimizer;
%     [~, ~,annZ] = o.CalculateDensitySensitivityandRho(x,y,MacroThetaColumnTotal,ones(size(MacroEyyColumnTotal)),DV.ResponseSurfaceCoefficents,config,matProp,0);
%     
%     figure
%     plot(f1, [x y], z);
%     hold on
%     scatter3(x,y,z,'b')
%     hold on
%     scatter3(x,y,annZ,'r');
%     
%     title('Fit with data points. Red=Ann, Blue=Actual ')
%     xlabel('Exx');
%     ylabel('Eyy');
%     zlabel('rho');
%     zlim([0 1])
%     size(RhoColumnTotal)
% end
% 

%annTest(macro_meso_iteration);

% if 1==0
%     Exx = matProp.E_material1;
%     Eyy = 0;
%     v= 1;
%     rhoArray = [rhoArray;v];
%     ExxArray=[ExxArray;Exx];
%     EyyArray=[EyyArray;Eyy];
%
%      Exx = matProp.E_material1;dos
%     Eyy = matProp.E_material1/2;
%     v= 1;
%     rhoArray = [rhoArray;v];
%     ExxArray=[ExxArray;Exx];
%     EyyArray=[EyyArray;Eyy];
%
%     % Both extremes
%        Exx = matProp.E_material1;
%     Eyy = matProp.E_material1;
%     v= 1;
%     rhoArray = [rhoArray;v];
%     ExxArray=[ExxArray;Exx];
%     EyyArray=[EyyArray;Eyy];
%
%       Exx = matProp.E_material1/2;
%     Eyy =matProp.E_material1 ;
%     v= 1;
%     rhoArray = [rhoArray;v];
%     ExxArray=[ExxArray;Exx];
%     EyyArray=[EyyArray;Eyy];
%
%     %Eyy extreme
%     Exx =0;
%     Eyy =  matProp.E_material1;
%     v= 1;
%     rhoArray = [rhoArray;v];
%     ExxArray=[ExxArray;Exx];
%     EyyArray=[EyyArray;Eyy];
%
%
% end


% if(1==1)
%
%     nameArray = sprintf('./out%i/ExxArrayForFitting%i.csv',folderNum, config.macro_meso_iteration);
%     csvwrite(nameArray,ExxArray);
%
%     nameArray = sprintf('./out%i/EyyArrayForFitting%i.csv',folderNum, config.macro_meso_iteration);
%     csvwrite(nameArray,EyyArray);
%
%     nameArray = sprintf('./out%i/ThetaArrayForFitting%i.csv',folderNum, config.macro_meso_iteration);
%     csvwrite(nameArray,thetaArray);
%
%
%
%     nameArray = sprintf('./out%i/RhoArrayForFitting%i.csv',folderNum, config.macro_meso_iteration);
%     csvwrite(nameArray,rhoArray);
%
%     % REad the old arrays as well.
%     if(config.macro_meso_iteration>1)
%         for jjj= 1:config.macro_meso_iteration-1
%             nameArray = sprintf('./out%i/ExxArrayForFitting%i.csv',folderNum, jjj);
%             MacroExxColumnTemp =  csvread(nameArray);
%             ExxArray=[ExxArray ;MacroExxColumnTemp];
%
%             nameArray = sprintf('./out%i/EyyArrayForFitting%i.csv',folderNum, jjj);
%             MacroEyyColumnTemp =  csvread(nameArray);
%             EyyArray=[EyyArray; MacroEyyColumnTemp];
%
%
%             nameArray = sprintf('./out%i/ThetaArrayForFitting%i.csv',folderNum, jjj);
%             thetaArrayTemp =  csvread(nameArray);
%             thetaArray=[thetaArray; thetaArrayTemp];
%
%
%
%             nameArray = sprintf('./out%i/RhoArrayForFitting%i.csv',folderNum, jjj);
%             rhoArrayTemp =  csvread(nameArray);
%             rhoArray=[rhoArray; rhoArrayTemp];
%         end
%
%
%     end
%
%
%
%
%     figure(1)
%     scaleUp = matProp.E_material1;
%     config.useThetaInSurfaceFit=1;
%     if(config.useThetaInSurfaceFit==1)
%
%         % -----------------------
%         % PLot the raw data. Scale up the rho, to make the color range
%         % larger.
%         % -----------------------
%         RhoColor=rhoArray; % color
%         circleSize = ones(size(ExxArray))*100; % circle size.
%         scatter3(ExxArray,EyyArray,thetaArray,circleSize,RhoColor);
%         xlabel('Exx');
%         ylabel('Eyy');
%         zlabel('Theta');
%         title(sprintf('Rho (the color) as a function of Exx, Eyy, theta: iter %i',config.macro_meso_iteration));
%         colorbar
%
%         nameGraph2 = sprintf('./RhoDensityOfExxEyyPlot%i.png', config.macro_meso_iteration);
%         print(nameGraph2,'-dpng');
%
%         % ----------------------------
%         % Plot 2, with symmmetry taken into account.
%         % Make Exx always larger
%         % theta between 0 and pi/4
%         % ----------------------------
%
%       % Make the inputs be so taht Exx > Eyy
% % Rather than a strict theta, use the distance from pi/4, since the problem
% % is symmetric arround pi/4
% temp = ExxArray;
% logic = EyyArray>ExxArray;
% ExxArray(logic)=EyyArray(logic);
% EyyArray(logic) =temp(logic);
% %
% % min(thetaArray)
% % max(thetaArray)
% % thetaArray=((pi/4)^2+thetaArray.^2).^(1/2);
% temp2 = thetaArray;
% logic2 = thetaArray>pi/4;
% logic3 = thetaArray<pi/4;
% thetaArray(logic2)=thetaArray(logic2)-pi/4;
% thetaArray(logic3)=pi/4-thetaArray(logic3);
%
%          figure
%           scatter3(ExxArray,EyyArray,thetaArray,circleSize,RhoColor);
%         xlabel('Exx');
%         ylabel('Eyy');
%         zlabel('Theta');
%         title(sprintf('Plot 2Rho (the color) as a function of Exx, Eyy, theta: iter %i',config.macro_meso_iteration));
%         colorbar
%
%           nameGraph2 = sprintf('./Plot2RhoDensityOfExxEyyPlot%i.png', config.macro_meso_iteration);
%         print(nameGraph2,'-dpng');
%
%
%         % -------------------------------
%         % Least squares fit
%         % ------------------------------
% %
% x0=ones(1,10);
% x0 = randi([-5,5],1,10);
% A = [];
% b = [];
% 
% 
% % theta the same
% % rho the same.
% % scale down Exx, Eyy
% 
% X = ExxArray/scaleUp;
% Y = EyyArray/scaleUp;
% 
% %         Z = thetaArray/(pi/4);
% Z = thetaArray;
% R = rhoArray;
% 
% 
% ub = ones(6,1)*10000;
% lb = -ub;
% o=Optimizer;
% [coefficients finalObjective]= fmincon(@(x) fitObjectiveV2(x,X,Y,Z,R,o,config,matProp),x0,A,b,[],[],lb,ub);
% 
% finalObjective
% 
% % use the scaled data
% %         numPointsXandY = 20;
% %tt  =1/numPointsXandY;
% tt  =0.05;
% 
% [Xgrid, Ygrid, Zgrid]=meshgrid(0:tt:max(X),0:tt:max(Y),0:0.2:max(Z));
% 
% % Reshape into columns
% E_xx=reshape(Xgrid,[],1);
% E_yy=reshape(Ygrid,[],1);
% theta=reshape(Zgrid,[],1);
% 
% x=coefficients;
% 
% %------------
% % Calcualte the rho values using the fitting polynomial
% %------------
% [~, ~,rhoExperimental] = o.CalculateDensitySensitivityandRho(E_xx,E_yy,theta,coefficients,config,matProp);

% -----------------------
% Plot
% - rescale the data to the correct form
% - plot scatter3
%-------------------------
%         rhoExperimental=rhoExperimental/scaleUp;
%         E_xx=E_xx*scaleUp;
%         E_yy=E_yy*scaleUp;
%    rhoExperimental=rhoExperimental;
%    theta=theta;


% %         E_xx(E_yy>E_xx)=0;
% %         E_yy(E_yy>E_xx)=0;
%
%
%         figure
%         circleSize = ones(size(E_xx))*100; % circle size.
%         scatter3(E_xx,E_yy,theta,circleSize,rhoExperimental,'filled');
%         title(sprintf('Response surface,Rho (the color) as a function of Exx, Eyy, theta: iter %i',config.macro_meso_iteration));
%         colorbar
%          xlabel('Exx');
%         ylabel('Eyy');
%         zlabel('Theta');
%         %                 hold off
%
%         nameGraph2 = sprintf('./RhoDensityOfExxEyyThetaResponseSurfacePlot%i.png', config.macro_meso_iteration);
%         print(nameGraph2,'-dpng');
%
%           nameArray = sprintf('./out%i/ExxEyyRhoFitCoefficients%i.csv',folderNum, config.macro_meso_iteration);
%         %      csvwrite(nameArray,sfArray);
%
%         dlmwrite(nameArray, x, 'delimiter', ',', 'precision', 15);
%
%
%     else
%         % ---------------------------------------------------
%         % Plot and surface fit where
%         %
%         % rho is a function of Exx and Eyy
%         % ---------------------------------------------------
%         scatter3(ExxArray,EyyArray,rhoArray);
%         xlabel('Exx');
%         ylabel('Eyy');
%         zlabel('Rho,Density');
%
%         x0=[1 1 1 1 1 1];
%         A = [];
%         b = [];
%
%         scaleUp = matProp.E_material1;
%
%         %      X = MacroExxColumn/matProp.E_material1;
%         %      Y = MacroEyyColumn/matProp.E_material1;
%         X = ExxArray;
%         Y = EyyArray;
%
%         Z = rhoArray*scaleUp;
%
%         ub = ones(6,1)*100000;
%         lb = -ub;
%         coefficients= fmincon(@(x) fitObjective(x,X,Y,Z),x0,A,b,[],[],lb,ub);
%         %       [x,fval,exitflag] = ga(@(x) fitObjective(x,X,Y,Z),  6,A,b,[],[],lb,ub);
%         %        sfArray=x;
%         coefficients=coefficients/scaleUp
%         %
%         [Xgrid, Ygrid]=meshgrid(0:1000:max(X),0:1000:max(Y));
%
%         %      Xgrid=Xgrid*matProp.E_material1;
%         %      Ygrid=Ygrid*matProp.E_material1;
%
%         p00 =coefficients(1);
%         p10=coefficients(2);
%         p01=coefficients(3) ;
%         p20=coefficients(4);
%         p11=coefficients(5);
%         p02=coefficients(6);
%
%         Zexperimental=   p00 + p10*Xgrid + p01*Ygrid + p20*Xgrid.^2 + p11*Xgrid.*Ygrid + p02*Ygrid.^2;
%
%         hold on
%         surf(Xgrid,Ygrid,Zexperimental)
%         hold off
%
%         nameArray = sprintf('./out%i/ExxEyyRhoFitCoefficients%i.csv',folderNum, config.macro_meso_iteration);
%         %      csvwrite(nameArray,sfArray);
%
%         dlmwrite(nameArray, coefficients, 'delimiter', ',', 'precision', 15);
%
%
%         nameGraph2 = sprintf('./RhoDensityOfExxEyyPlot%i.png', config.macro_meso_iteration);
%         print(nameGraph2,'-dpng');
%     end
%
%
%
%
%
%
%
%
%
%     %           sf = fit([MacroExxColumn, MacroEyyColumn],rhoArray,'poly22')
%     %           plot(sf,[MacroExxColumn,MacroEyyColumn],rhoArray)
%     %          xlabel('MacroExxColumn');
%     %     ylabel('MacroEyyColumn');
%     %     zlabel('Rho,Density');
%     %      sfArray = [sf.p00 sf.p10 sf.p01 sf.p20 sf.p02 sf.p11 ];
%
%
%
%
%
%     %       figure(3)
%     %      sf = fit([ExxArray, EyyArray],rhoArray,'poly23')
%     %      plot(sf,[ExxArray,EyyArray],rhoArray)
%     %         xlabel('ExxArray');
%     %     ylabel('EyyArray');
%     %     zlabel('Rho,Density');
%     % %
%     %
%     %     xlabel('Exx');
%     %     ylabel('Eyy');
%     %     zlabel('Rho,Density');
%     %
%     %     figure(3)
%     %     scatter3(ExxArray,EyyArray,thetaArray);
%     %     xlabel('Exx');
%     %     ylabel('Eyy');
%     %     zlabel('theta');
%
%     %     figure(4)
%     %        scatter3(MacroExxColumn,MacroEyyColumn,rhoArray);
%     %     histogram(thetaArray)
%
%     %     figure(5)
%     %     DV = DV.CalculateVolumeFractions( config,matProp);
% else
%     DV.CalculateVolumeFractions( config,matProp)
%     p = plotResults;
%     FEACalls=1;
%     p.plotTopAndFraction(DV,  config, matProp, FEACalls); % plot the results.
%
%
%     nameGraph = sprintf('./MesoDesignExxEyyThetaVars%i.png', config.macro_meso_iteration);
%     print(nameGraph,'-dpng');
% end
% %
% p = plotResults;
% diffExx = ExxMacro- DV.Exx;
% diffEyy = EyyMacro- DV.Eyy;
% diffTheta = ThetaMacro- DV.t;
%
%
% relativeErrorExx=diffExx./ExxMacro;
% relativeErrorEyy=diffEyy./EyyMacro;
% relativeErrorTheta=diffTheta./ThetaMacro;
%
%
% % make the range -1 to 1
% relativeErrorExx(relativeErrorExx>1)=1;
% relativeErrorExx(relativeErrorExx<-1)=-1;
%
% relativeErrorEyy(relativeErrorEyy>1)=1;
% relativeErrorEyy(relativeErrorEyy<-1)=-1;
%
% relativeErrorTheta(relativeErrorTheta>1)=1;
% relativeErrorTheta(relativeErrorTheta<-1)=-1;
%
% xplots = 3;
% yplots = 3;
% c= 1;
% figure
% subplot(xplots,yplots,c);c=c+1;
%
% p.PlotArrayGeneric( diffExx, 'diffExx')
% subplot(xplots,yplots,c);c=c+1;
% p.PlotArrayGeneric( diffEyy, 'diffEyy')
% subplot(xplots,yplots,c);c=c+1;
% p.PlotArrayGeneric( diffTheta, 'diffTheta')
%
% subplot(xplots,yplots,c);c=c+1;
% p.PlotArrayGeneric( ExxMacro, 'ExxMacro')
%
% subplot(xplots,yplots,c);c=c+1;
% p.PlotArrayGeneric( EyyMacro, 'EyyMacro')
%
% subplot(xplots,yplots,c);c=c+1;
% p.PlotArrayGeneric( ThetaMacro, 'ThetaMacro')

% x = [ExxMacro; EyyMacro; ThetaMacro]

% figure
% subplot(2,2,1)
% p.PlotArrayGeneric(100* relativeErrorExx, 'Percent Error Exx')
% subplot(2,2,2)
% p.PlotArrayGeneric( 100*relativeErrorEyy, 'Perecent Error Eyy')
% subplot(2,2,3)
% p.PlotArrayGeneric(100* relativeErrorTheta, 'Percent Error Theta')
% subplot(2,2,4)
% p.PlotArrayGeneric(diffTheta, 'Diff Theta')
% nameGraph = sprintf('./MesoDesignExxEyyThetaVarsPercentError%i.png', config.macro_meso_iteration);
% print(nameGraph,'-dpng');
% validationMeso =1;
% if(validationMeso ==1)
%
%     totalValidationProblems=config.nely*config.nelx;
%     numSegments = floor(totalValidationProblems^(1/3));
%     numSegmentsExx = numSegments;
%     numSegmentsTheta = floor(totalValidationProblems/(numSegmentsExx^2));
%
%     numSegmentsExx=numSegmentsExx-1;
%     numSegmentsTheta=numSegmentsTheta-1;
%
%     ExxVector =0:matProp.E_material1/numSegmentsExx:matProp.E_material1;
%     EyyVector =0:matProp.E_material1/numSegmentsExx:matProp.E_material1;
%     thetaVector = 0:(pi/2)/numSegmentsTheta:pi/2;
%     [ExxValues EyyValues ThetaValues] = meshgrid(ExxVector,ExxVector,thetaVector);
%
%     %ExxValues=padarray(ExxValues,
%     ExxValues=reshape(ExxValues,1,[]);
%     [t1 t2]=size(ExxValues);
%     ExxValues=padarray(ExxValues,[0 totalValidationProblems-t2],'post');
%     ExxValues=reshape(ExxValues,config.nely,config.nelx);
%
%     EyyValues=reshape(EyyValues,1,[]);
%     EyyValues=padarray(EyyValues,[0 totalValidationProblems-t2],'post');
%     EyyValues=reshape(EyyValues,config.nely,config.nelx);
%
%     ThetaValues=reshape(ThetaValues,1,[]);
%     ThetaValues=padarray(ThetaValues,[0 totalValidationProblems-t2],'post');
%     ThetaValues=reshape(ThetaValues,config.nely,config.nelx);
%
%     xSimp = ones(t1, t2);
%     xSimp=reshape(xSimp,1,[]);
%     xSimp=padarray(xSimp,[0 totalValidationProblems-t2],'post');
%     xSimp=reshape(xSimp,config.nely,config.nelx);
%
%
%     ExxNewArray = [];
%      EyyNewArray = [];
%       EyyNewArray = [];
%        EzzNewArray = [];
%     for e = 1:t1*t2
%         Xcondition = ExxVector(1)==DV.Exx(e);
%         Ycondition = 1;%ExxVector(1)==DV.Exx(e);
%         thetaCondtion =1;% ThetaValues(1)==DV.t(e);
%         %rhoCondtion = ExxVector(1)==DV.Exx(e);
%         if(Xcondition==1 && Ycondition==1 && thetaCondtion==1)
%
%         end
%
%     end
%
%
% end



