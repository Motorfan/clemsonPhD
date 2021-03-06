%%%%%%%%%% OPTIMALITY CRITERIA UPDATE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [xnew]=OC_meso(nelx,nely,x,volfrac,dc ,DV, config)

% % Make sure that dc is negative. 
% absL =  max(max(dc));
% if(absL>-1)
%     dc = dc-absL-1;
% end
% 
% 
% % if the sensitivity is really small, then make it larger to help the
% % optimal criteria method work better.
% absL =  max(max(abs(dc)));
% if absL <10000
%     dc = dc*10000/absL;
% end
% 
% if absL>10000000
%       dc = dc/100000.0;
% end

% multiplier = 1;
% 
% if(settings.doUseMultiElePerDV) % if elements per design var.     
%    multiplier = settings.numVarsX*settings.numVarsY;   
% else
multiplier=nelx*nely;
% end
   SumDensity = sum(sum(x));
l1 = -10000000; l2 = 1000000; move = 0.1;
while (l2-l1 > 1e-4)
    lmid = 0.5*(l2+l1);
    
%     term = dc*lmid;
   
    term = 0.5*lmid*dc/SumDensity;
    xnew = max(0.01,max(x-move,min(1.,min(x+move,x.*term))));  
     SumDensity = sum(sum(xnew));
%     xnew = max(0.01,max(x-move,min(1.,min(x+move,x.*(-dc./lmid)^1/4))));    
    %   desvars = max(VOID, max((x - move), min(SOLID,  min((x + move),(x * (-dfc / lammid)**self.eta)**self.q))))    
    %[volume1, volume2] = designVar.CalculateVolumeFractions(settings);
    %currentvolume=volume1+volume2;
    
    %if currentvolume - volfrac > 0;
    
   
%     xnew(xnew>config.voidMaterialDensityCutOff)=1;
%     xnew(xnew<=config.voidMaterialDensityCutOff)=0;
    
     if sum(sum(xnew)) - 1*multiplier < 0;
%      if sum(sum(lmid*dc)) - 2*SumDensity > 0;
        l1 = lmid;
    else
        l2 = lmid;
    end
end
t = 1;