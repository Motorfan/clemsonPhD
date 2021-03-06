function []=annTest(iterations)
% module load  matlab/2016a
fprintf('annTest\n');



ExxArray=[];
EyyArray=[];
thetaArray=[];
rhoArray=[];

iterationsArray = [1];

count = 1;
for ii = [0  ]
    folderNum=ii;
    iterations=iterationsArray(count);
    count=count+1;
    for jjj= 1:iterations
        % nameArray = sprintf('./out%i/ExxArrayForFitting%i.csv',folderNum, jjj);
        macro_meso_iteration=jjj
                nameArray = sprintf('./data/MacroExxColumn%i.csv',macro_meso_iteration);
%         nameArray = sprintf('./data/MacroExxColumn%i.csv',folderNum,macro_meso_iteration);
        MacroExxColumnTemp =  csvread(nameArray);
        ExxArray=[ExxArray ;MacroExxColumnTemp];
        
        %        nameArray = sprintf('./out%i/EyyArrayForFitting%i.csv',folderNum, jjj);
                nameArray = sprintf('./data/MacroEyyColumn%i.csv',macro_meso_iteration);
%         nameArray = sprintf('./data/MacroEyyColumn%i.csv',folderNum,macro_meso_iteration);
        MacroEyyColumnTemp =  csvread(nameArray);
        EyyArray=[EyyArray; MacroEyyColumnTemp];
        
        
        %        nameArray = sprintf('./out%i/ThetaArrayForFitting%i.csv',folderNum, jjj);
                nameArray = sprintf('./data/MacroThetaColumn%i.csv',macro_meso_iteration);
%         nameArray = sprintf('./data/MacroThetaColumn%i.csv',folderNum,macro_meso_iteration);
        thetaArrayTemp =  csvread(nameArray);
        thetaArray=[thetaArray; thetaArrayTemp];
        
        
        
        %         nameArray = sprintf('./out%i/RhoArrayForFitting%i.csv',folderNum, jjj);
        %         nameArray = sprintf('./out%i/RhoColumn%i.csv',folderNum,macro_meso_iteration);
        nameArray = sprintf('./data/RhoColumn%i.csv',macro_meso_iteration);
        rhoArrayTemp =  csvread(nameArray);
        rhoArray=[rhoArray; rhoArrayTemp];
    end
end

% Make the inputs be so taht Exx > Eyy
% Rather than a strict theta, use the distance from pi/4, since the problem
% is symmetric arround pi/4
temp = ExxArray;
logic = EyyArray>ExxArray;
ExxArray(logic)=EyyArray(logic);
EyyArray(logic) =temp(logic);

maxExx = max(EyyArray);
%
% min(thetaArray)
% max(thetaArray)
% thetaArray=((pi/4)^2+thetaArray.^2).^(1/2);
temp2 = thetaArray;
logic2 = thetaArray>pi/4;
logic3 = thetaArray<pi/4;
thetaArray(logic2)=thetaArray(logic2)-pi/4;
thetaArray(logic3)=pi/4-thetaArray(logic3);

% compare = [thetaArray temp2];
% compare

% min(thetaArray)
% max(thetaArray)

% -----------------------
% Plot the raw data
% -----------------------

figure
circleSize = ones(size(ExxArray))*100; % circle size.
scatter3(ExxArray,EyyArray,thetaArray,circleSize,rhoArray,'filled');
title(sprintf('RAw data, Rho (the color) as a function of Exx, Eyy, theta: iter %i',1));
colorbar
xlabel('Exx');
ylabel('Eyy');
zlabel('Theta');
axis([0 maxExx 0 maxExx 0 pi/4]);
%                 hold off

nameGraph2 = sprintf('./AnnRawDataTest3DGrid.png');
print(nameGraph2,'-dpng');

x = [ExxArray' ; EyyArray'; thetaArray'];
t=rhoArray';

size(x)
size(t)

setdemorandstream(491218382)
% net = fitnet(10,'trainbfg');
%  net = cascadeforwardnet(10);
net = feedforwardnet(10);
figure(1)
% view(net)
% print('ANN_view.png','-dpng');

% Train
[net,tr] = train(net,x,t);

plotperform(tr)
print('ANN_preformance.png','-dpng');


y = net(x);
plotregression(t,y)
print('ANN_regressionTest2.png','-dpng');

genFunction(net,'annRhoOfExxEyyTheta_version2');

%--------------------------
% Plot a grid where the ANN finds the density
% plot to see if it matches something reasonable
%-----------------------------------
matProp = MaterialProperties; % material properties Object
Xmax = matProp.E_material1;
Ymax = matProp.E_material1;
Zmax= pi/4;
numValues = 10;
[Xgrid, Ygrid, Zgrid]=meshgrid(0:Xmax/numValues:Xmax,...
    0:Ymax/numValues:Ymax ,...
    0:Zmax/numValues:Zmax);

% Reshape into columns
E_xx=reshape(Xgrid,[],1);
E_yy=reshape(Ygrid,[],1);
theta=reshape(Zgrid,[],1);
[t1, t2, t3]=size(Xgrid);

% Make the inputs be so taht Exx > Eyy
% Rather than a strict theta, use the distance from pi/4, since the problem
% is symmetric arround pi/4
% ExxTemp = [];
% EyyTemp=[];
% ThetaTemp=[];
% for iiii = 1:size(E_xx)
%     if(E_yy(iiii)<E_xx(iiii) && theta(iiii)>pi/4)
%         ExxTemp=[ExxTemp; E_xx(iiii)];
%         EyyTemp=[EyyTemp;E_yy(iiii)];
%        % logic = E_yy>E_xx;
%         %E_xx(logic)=E_yy(logic);
%         %E_yy(logic) =temp(logic);
%         %temp2 = thetaArray;
%        % if(theta(iiii)>pi/4)
%             ThetaTemp=[ThetaTemp;theta(iiii)-pi/4];
%         %else
%          %     ThetaTemp=[ThetaTemp;-pi/4-theta(iiii)];
%         %end
% %         logic2 = thetaArray>pi/4;
% %         logic3 = thetaArray<pi/4;
% %         thetaArray(logic2)=thetaArray(logic2)-pi/4;
% %         thetaArray(logic3)=pi/4-thetaArray(logic3);
%     end
% end
% E_xx=ExxTemp;
% E_yy=EyyTemp;
% theta=ThetaTemp;
temp = E_xx;
logic = E_yy>E_xx;
E_xx(logic)=E_yy(logic);
E_yy(logic) =temp(logic);
logic2 = theta>pi/4;
logic3 = theta<pi/4;
theta(logic2)=theta(logic2)-pi/4;
theta(logic3)=pi/4-theta(logic3);


xTest = [E_xx' ; E_yy'; theta'];
rhoExperimental=net(xTest);
rhoExperimental(rhoExperimental>1)=1;
rhoExperimental(rhoExperimental<0)=0;

size(xTest)
size(rhoExperimental)

figure
circleSize = ones(size(E_xx))*100; % circle size.
scatter3(E_xx,E_yy,theta,circleSize,rhoExperimental,'filled');
title(sprintf('Response surface,Rho (the color) as a function of Exx, Eyy, theta: iter %i',1));
colorbar
xlabel('Exx');
ylabel('Eyy');
zlabel('Theta');
axis([0 maxExx 0 maxExx 0 pi/4]);
%                 hold off

nameGraph2 = sprintf('./AnnTest3DGrid.png');
print(nameGraph2,'-dpng');

rhoExperimental
t1
t2
t3
rhoExperimental=reshape(rhoExperimental,[t1 t2 t3]);



outname = sprintf('./out%i/ANN_interp_E_xx.csv',0);
csvwrite(outname,Xgrid);
outname = sprintf('./out%i/ANN_interp_E_yy.csv',0);
csvwrite(outname,Ygrid);
outname = sprintf('./out%i/ANN_interp_Theta.csv',0);
csvwrite(outname,Zgrid);
outname = sprintf('./out%i/ANN_interp_Rho.csv',0);
csvwrite(outname,rhoExperimental);

Xq=100000*0.6;
Yq=100000*0.4;
Zq=0;
Vq = interp3(Xgrid,Ygrid,Zgrid,rhoExperimental,Xq,Yq,Zq);

fprintf('InterpValue = %f',Vq);

% % Plot the current work
% o=Optimizer;
% Coefficents=[     -0.0449    1.0449    1.0449    0.0000   -1.0449    0.0000];
%
% Exx=E_xx;
% Eyy=E_yy;
% %theta = theta;
% config=Configuration;
% config.useThetaInSurfaceFit=0;
%
% matProp = MaterialProperties;
% [EyySensitivty, ExxSensitivity,rhoValue] = o.CalculateDensitySensitivityandRho(Exx/matProp.E_material1,Eyy/matProp.E_material1,theta,Coefficents,config,matProp);
%
% figure
% circleSize = ones(size(E_xx))*100; % circle size.
% scatter3(E_xx,E_yy,theta,circleSize,rhoValue,'filled');
% title(sprintf(' surface using current method '));
% colorbar
% xlabel('Exx');
% ylabel('Eyy');
% zlabel('Theta');
%
% nameGraph2 = sprintf('./annCurrentMethod.png');
% print(nameGraph2,'-dpng');




% loop over the ann output vs the experimental. If the difference is large,
% then print the Exx, eyy, theta valeus
for jjjj = [0.05 0.1 0.2 0.3]
    rangeV=jjjj;
    lowerV=1-rangeV;
    upperV=1+rangeV;

    size(t,2)
    numberOfValues = 1:size(t,2);

    ExxArrayV2=[];
    EyyArrayV2=[];
    thetaArrayV2=[];
    rhoArrayV2=[];

    count=0;
    for i=numberOfValues
        experimental=t(i);
        annValue=y(i);

        dividedByValue = experimental/annValue;
        if(dividedByValue<lowerV ||dividedByValue>upperV)
           % fprintf('%i Exx %f Eyy %f Theta %f rho %f AnnRho %f \n',i, x(1,i), x(2,i), x(3,i),experimental,annValue)
            ExxArrayV2=[ExxArrayV2 x(1,i)];
            EyyArrayV2=[EyyArrayV2 x(2,i)];
            thetaArrayV2=[thetaArrayV2 x(3,i)];
            rhoArrayV2=[rhoArrayV2 experimental];
            count=count+1;
        end

    end
    count
    
%     E_xx = ExxArrayV2;
%     E_yy=EyyArrayV2;
%     thetaArray=thetaArrayV2;
%     
%     temp = E_xx;
%     logic = E_yy>E_xx;
%     E_xx(logic)=E_yy(logic);
%     E_yy(logic) =temp(logic);
%     temp2 = thetaArray;
%     logic2 = thetaArray>pi/4;
%     logic3 = thetaArray<pi/4;
%     thetaArray(logic2)=thetaArray(logic2)-pi/4;
%     thetaArray(logic3)=pi/4-thetaArray(logic3);


    figure
    circleSize = ones(size(ExxArrayV2))*100; % circle size.
    scatter3(ExxArrayV2,EyyArrayV2,thetaArrayV2,circleSize,rhoArrayV2,'filled');
    title(sprintf(' Values that do not fit well with error more than %i',jjjj*100));
    colorbar
    xlabel('Exx');
    ylabel('Eyy');
    zlabel('Theta');
    axis([0 maxExx 0 maxExx 0 pi/4]);

    nameGraph2 = sprintf('./annDoNotFitWellErrorMoreThan%i.png',jjjj*100);
    print(nameGraph2,'-dpng');
end
