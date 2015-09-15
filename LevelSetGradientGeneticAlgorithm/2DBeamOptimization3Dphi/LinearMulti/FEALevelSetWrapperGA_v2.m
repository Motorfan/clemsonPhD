function [obj, cinequality] = FEALevelSetWrapperGA(zpoints)

[xpoints,ypoints] = meshgrid(0:6/10:6,0:0.5:2);   
zpoints_v2 = zeros(5,11);

%zpoints = [1.1771,1.062,1.193,0.37502,2.0539,1.2221,1.0766,2.0261,2.2899,2.9467,-0.89181,-2.7429,-2.7798,-2.933,-2.4828,2.9158,2.9278,2.0928,-0.41381,2.0217,0.30951,1.8541,-1.5301,-1.6397,-2.2681,-2.0047,-2.2563,-2.2351,2.2366,-2.0073,0.80145,2.4771,0.4206,2.2132,2.3729,2.8345,2.9758,-0.22221,1.1713,2.9033,-2.8354,2.1735,-0.23456,2.1497,1.895,1.9576,1.4111,2.8378,0.49403,-2.5419,-1.2107,-1.7144,0.21443,0.2631,0.42773];

% 2 hours on palmetto 24 cpus
%zpoints = [2.9566,1.9182,1.2806,1.4627,1.1796,1.1309,1.1438,0.97819,0.99722,1.1953,2.232,-2.7651,-2.0145,2.9891,2.5537,-2.7595,-2.861,-2.5,-2.4894,-1.5508,-2.5457,1.7355,-2.2586,-2.5548,-2.9589,-1.6421,1.7504,-2.0618,-0.82854,-2.3249,2.5198,2.7406,-1.4904,-2.1549,-2.7656,-2.6363,-2.5136,0.19699,2.6132,0.23974,-2.7436,1.4363,-2.0293,-2.5411,2.2657,2.5246,2.7201,2.1128,2.2607,-2.1408,-0.35669,2.4456,-1.3075,-1.7597,-2.1988]


% 2.5 hours on palmetto 24 cpus
% zpoints = [2.9566,2.0432,1.1869,1.5564,1.1796,1.1309,1.1438,0.97819,0.99722,1.1953,2.232,-2.7651,-2.0145,2.9891,2.5537,-2.7595,-2.861,-2.5,-2.4894,-1.5508,-2.5457,1.7355,-2.2586,-2.5548,-2.9589,-1.6421,1.7348,-2.0618,-0.82854,-2.3249,2.5198,2.7406,-1.4904,-2.1549,-2.7656,-2.6363,-2.5136,0.19699,2.6132,0.17724,-2.7436,1.4363,-2.0293,-2.5411,2.2657,2.5246,2.7201,2.1128,2.2607,-2.1408,-0.35669,2.4456,-1.3075,-1.7597,-2.1988]

% zpoints = [2.5829,2.2738,2.4706,2.5247,2.3824,2.1426,3,1.211,1.0386,1.2317,2.9929,2.2732,2.6901,2.8588,2.1657,2.993,2.6207,2.7919,1.6305,2.9261,3,2.8904,2.7689,2.2713,2.8503,1.5294,1.8177,2.049,2.7861,3,-2.5192,-2.0571,-2.0523,1.4326,2.5095,1.6618,2.008,1.1563,3,-1.7132,-2.0881,-2.7288,-2.9991,-1.54,2.7121,2.4198,2.7478,2.8206,1.0128,3,2.9535,-2.1472,-1.6483,-0.27448,-0.055194]
% zpoints = [0.42803,0.48187,0.2106,0.43766,0.22189,0.54001,1,0.99961,0.85849,0.81156,-0.0022506,-0.89681,-0.99535,-0.5409,-0.94447,-0.6335,-0.96898,0.85301,-0.75876,-0.79805,-0.88295,-0.68623,-0.18342,-0.14218,-0.53861,-0.31121,-0.85369,0.49977,-0.52428,-0.92473,-0.70997,-0.71092,-0.035661,-0.35954,-0.81925,-0.85249,-0.80444,0.61216,-0.83885,-0.70771,-0.20291,-0.0032059,-0.37199,-0.32591,1,1,1,0.99479,-0.9074,-0.2135,-0.97204,-0.0013058,-0.76265,-0.22895,-0.33311]
%zpoints = [ 1,1,1,1,1,1,1,1,0.6125,0.30743,-0.04106,0.97325,1,1,-0.5,-0.25,-0.25,-0.25001,-0.875,-0.91875,-0.76844,-0.75829,-0.9777,0.9777,-0.49988,-0.50059,-0.7472,-0.6767,-0.73953,-0.95459,-0.75323,-0.30388,-0.81889,0.97323,1,-0.50001,-1.2536e-05,-0.50122,-0.54714,-0.51794,-0.24288,-0.50748,-0.47353,-0.82169,1,1,-0.50001,-0.056245,-0.059409,-0.53362,-0.3891,-0.054954,-0.27975,-0.29885,-0.36471]
zpoints = zpoints_v2
zpoints_v2(1,:) = zpoints(1:11);
zpoints_v2(2,:) = zpoints(12:22);
zpoints_v2(3,:) = zpoints(23:33);
zpoints_v2(4,:) = zpoints(34:44);
zpoints_v2(5,:) = zpoints(45:55);
doplot = 1  ;

[maxVonMisesStress, cost,maxDisplacement] = FEALevelSet_2D_v8(xpoints,ypoints,zpoints_v2, doplot); % Call FEA for first time

obj = cost
cinequality = maxDisplacement-0.2;  % max Displacemen is positive. The max displacement must be less than 0.1 inch
% cequality = ydisplacment+0.0623; % displacement will be negative, so add 0.0623 to make = 0
%feature('GetPid')




