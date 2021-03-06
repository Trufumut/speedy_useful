%% Programa adaptado para calcular Cond. Borde para SPEEDY, de SST HadISST
%20180511 --> se calculan condiciones de borde para experimentos
% Repositorio original: https://github.com/Trufumut/speedy_useful. Incluye una guía.
aseo % https://github.com/Trufumut/MATLAB_useful/blob/main/aseo.m
%% Preliminares
% ruta a los archivos
cd '/home/matt/Documentos/SPEEDY/';  % LINUX
path1 = '/home/matt/speedy_ver41.5/data/bc/t30/'; % path de datos % LINUX
path2 = '/home/matt/Documentos/SPEEDY/'; % path de utensilios %LINUX
% cd 'C:\Users\fredo\Documents\Geof\Tópico 2021-2\Final\'; % WINDOWS
% path1 = 'C:\Users\fredo\Documents\Geof\Tópico 2021-2\Final\in\'; % WINDOWS
% path2 = 'C:\Users\fredo\Documents\Geof\Tópico 2021-2\Final\out\'; % WINDOWS
%----Climatology that comes with Speedy package

[fid,mensaje] = fopen([path1, 'clim/sst_clim6110Hadisst.t30.sea.grd'], 'r'); % LINUX
% [fid,mensaje] = fopen([path1, 'sst_clim6110Hadisst.t30.sea.grd'], 'r'); % WINDOWS
variable = fread(fid, 'float','b'); % archivo de dim 55320x1

sstc=reshape(variable,4610,12); %4610*12=55320
sstc=sstc(2:48*96+1,:); %48*96=4608 --> valor 1 y end es 2.5829e-41 (distinto a -9.999e+19 = NaN)
sstc=reshape(sstc,96,48,12);

sstc=flipdim(sstc,2); % --> averiguar si parte desde +90° o desde -90°--> Parece que desde -90°
sstc=permute(sstc,[3 2 1 ]); %%%--------> IMPORTANTE! Dimensiones = (tiempo,latitud,longitud)

mm=min(min(min(sstc))); %-9.999e+19 = NaN (el valor + pequeño)
ii=find(sstc==mm); % ii contiene posiciones de los valores NAN,
SSTC = sstc; % para climatologia sin NaN
sstc(ii)=NaN;

% for i=1:12
% contourf(X,Y,sstc(:,:,i)')
% colorbar
% caxis([0 1])
% print(['seaice_' num2str(i)], '-djpeg','-r300')
% end
% % 
% % convert -delay 20 -loop 0 *.jpg seaice_clim6110_2.gif --> Esto en terminal...


%----Anomalies that come with Speedy package

% fid = fopen([path1,'noaa_anom_1854_2002_mean7908.t30.grd'], 'r') % <--------- falta este archivo
% varia = fread(fid, 'float','b');
% ssta=reshape(varia,4610,1777); clear varia
% ssta=ssta(2:48*96+1,:); % --> igual que el anterior se borra el primer y último valor
% ssta=reshape(ssta,96,48,1777);
% 
% ssta=flipdim(ssta,2);
% ssta=permute(ssta,[3 2 1 ]);

%%% IMPORTANTE: Resolución y puntos de grilla usados en SPEEDY
X=0:3.75:360; X=X(1:96);
Y=[-87.159   -83.479   -79.777   -76.070   -72.362   -68.652 -64.942...
    -61.232  -57.521   -53.810   -50.099   -46.389   -42.678   -38.967 -35.256...
    -31.545   -27.833  -24.122   -20.411   -16.700   -12.989    -9.278 -5.567...
    -1.856     1.856     5.567    9.278    12.989    16.700    20.411  24.122...
    27.833    31.545    35.256    38.967  42.678    46.389    50.099 53.810...
    57.521    61.232    64.942    68.652    72.362 76.070    79.777 83.479...
    87.159];


%% Desarrollo
%%%% CREATE NEW CLIMATOLOGY AND ANOMALIES USING HadISST  %%%%%
%----HadISST SST 1870/01-2021/07, dim=360x180x1819 % ESTE ES TÓPICO 2021

modelo = [path2,'HadISST_sst.nc']; % LINUX
% modelo = 'HadISST_sst.nc'; % WINDOWS

SST=ncread(modelo,'sst');
lon=ncread(modelo,'longitude'); % -180:+180
lat=ncread(modelo,'latitude'); % +89:-89
fechasSST=double(ncread(modelo,'time'));
fecha0 = datenum('01-01-1870');
fechasSST = fechasSST + fecha0; % enero 1870:julio 2021
% ncdisp('HadISST_sst.nc')
% cambiar dimensión de longitud de -180:180 a 0:360
lon = lon([181:end 1:180]); lon(181:end) = lon(181:end)+360; 
SST = SST([181:end 1:180],:,:);

SST=permute(SST,[3 2 1]); %---> (tiempo,lat,lon)
%SST2=reshape(SST2,1,180,89); SST2=permute(SST2,[1 3 2]);
%SST=[SST; SST2];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % Se calcula primero la climatología. Para ello se eliminarán los -1000°C
id1000 = find(SST == -1000);
SST(id1000) = NaN;  

%---Se desea obtener climatología 1961-2010 (50 años)
% tiempo = datenum(1870,1:length(fechasSST),15);
% 01/1961 = posición 1093 ; 12/2010 = posición 1692
SSTclim = SST(1093:1692,:,:);
SSTclim = reshape(SSTclim,[12 50 180 360]);
clim1 = squeeze(nanmean(SSTclim,2));

% Fills land with values interpolated from SST.
for j=1:12 %--> largo del año
    clim1(j,:,:)=inpaint_nans(squeeze(clim1(j,:,:)));
    j
end

% Rellenamos la longitud 0 con valores para evitar NaN al interpolar
clim1(:,:,2:361) = clim1(:,:,1:360);
clim1(:,:,1) = (clim1(:,:,2) + clim1(:,:,end))./2;

%---Interpolation
Lon = single([0 0.5:1:359.5])';
[clim]=interpol2(Lon,flipdim(lat,1),flipdim(clim1,2),X,Y); %--> hacer flipdim SST y lat

% Set to -9.9990e+19 climatology over continents
clim_NaN = clim; % respaldo
clim_NaN(ii) = NaN;
clim(ii) = mm;

% % Set values for sea ice as in the climatology that comes with Speedy.
% jj=find(sstc-273.15<0);
% clim(jj)=sstc(jj)-273.15;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % Luego se calculan las anomalías

%Fills land with values interpolated from SST.
%Otherwise in the interpolation procedure the ERSST doesn't have
%good values along boundaries with continents.
for j=1:length(fechasSST) %--> largo vector fecha
    SST2(j,:,:)=inpaint_nans(squeeze(SST(j,:,:)));
    j % este paso puede tardar
end
% Rellenamos la longitud 0 con valores para evitar NaN al interpolar
SST2(:,:,2:361) = SST2(:,:,1:360);
SST2(:,:,1) = (SST2(:,:,2) + SST2(:,:,end))./2;

% % Rellenamos la longitud 0 con valores para evitar NaN al interpolar
% SST(:,:,2:361) = SST(:,:,1:360);
% SST(:,:,1) = (SST(:,:,2) + SST(:,:,end))./2;

%---Interpolation
Lon = single([0 0.5:1:359.5])';
[SST2]=interpol2(Lon,flipdim(lat,1),flipdim(SST2,2),X,Y); %--> hacer flipdim SST y lat
clear id1000 ii Lon SSTclim
% % -----------------------------------------------------
% % % Esto es para no hacer todos los cálculos de nuevo hasta acá:
% % % La primera vez correr solo el "save", luego solo cargar lo anterior y se
% % % ahorra todo el trabajo computacional hasta este punto al volver a trabajar
% %  save('calculados') % CORRER SOLO LA PRIMERA VEZ esta línea
%  calculados=load('calculados')
%  nombres=structvars(calculados); % fx adjunta
%  for i=1:length(nombres(:,1))
%      eval(nombres(i,:))
%  end
%  clear nombres i calculados
% %
% % -----------------------------------------------------
%% Anomalías
% Compute HadISST anomalies based on the climatology 1961-2010
for j=1:12
  m=j;
  while (m<=length(fechasSST))
    SSTa(m,:,:)=SST2(m,:,:)-clim(j,:,:);
%     SSTa(m,:,:)=0; % PARA EXPERIMENTOS DE SOLAMENTE CLIMATOLOGÍA (anom = 0)
    m=m+12;
  end
end
%
% De aquí, solo correr el experimento deseado
% % % % % ----------------
% Experimento 1: solo climatología (poner anomalías en 0 en el ciclo de arriba)
% exp=1;
% (el experimento es no modificar nada, por eso solo está exp=1 para que se guarde 
% con el número correspondiente después)
% % % % % ----------------
% Experimento 2: zona el niño, forzar LA NIÑA (-1°C)
exp=2;
indxeq = find(Y>-6 & Y<6);
indyeq = find(X>190 & X<=240);
for j=1:12
  m=j;
  while (m<=length(fechasSST))
    SSTa(m,indxeq,indyeq)=-1; % aquí le pongo la alteración (-1 LN y +1 EN)
    m=m+12;
  end
end
% % % % % ----------------
%
%Set to 0 anomalies over continents
% for t=1:length(fechasSST)
%     ll = find(SSTC(1,:,:) == mm);
%     SSTa(t,ll)=0; % AQUÍ HAY UN 0, PERO PONER NaN para visualizar en el mapa
% end
% 
clim=clim+273.15; %aquí lo deja en Kelvin

% break
% clim_nonan=clim
% clim_nonan(clim_nonan<-100) == NaN
%
% Recorte para no usar desde 1870 sino que desde 1970
% SSTa = SSTa(1201:end,:,:);
% fechasSST = fechasSST(1201:end)
%% Visualizar los elementos a guardar
% Ver la climatología (los 12 meses)
figure
for i=1:12
    contourf(X',Y,squeeze(clim_NaN(i,:,:))), colorbar,caxis([-5 30])
    title(num2str(i)) 
    pause(0.5)
end
% Ver la anomalía, al menos para algunas fechas puestas a mano
figure
contourf(X',Y,squeeze(SSTa(200,:,:))), colorbar
%
%% Guardado los datos
%------ Save New Clim 

clim2=flipdim(clim,2);   % voltea la dimensión Y
clim2=permute(clim2,[3 2 1]);
clim2=reshape(clim2,[length(clim2(:,1,1))*length(clim2(1,:,1)),12]); % X*Y=4608
dummy=ones(4610,12)*variable(1);   % crea una matriz de 2.5829e-41
dummy(2:48*96+1,:)=clim2;          % rellena los espacios correspondientes
dummy=dummy(:); % hace de dummy una sola columna

fidw = fopen([path1, char('clim/sst_cEXP' + string(exp) + '.t30.sea.grd')], 'w'); % LINUX
% fidw = fopen([path2, char('sst_cEXP' + string(exp) + '.t30.sea.grd')], 'w'); % WINDOWS
count = fwrite(fidw,dummy,'float','b');
%
clear dummy

%------ Save New Anomalies

SSTa2=flipdim(SSTa,2);   % voltea la dimensión Y
% SSTa2=permute(SSTa2,[1 3 2]);
SSTa2=permute(SSTa2,[3 2 1]);
% SSTa2=SSTa(:,:)';
SSTa2=reshape(SSTa2,[length(SSTa2(:,1,1))*length(SSTa2(1,:,1)),length(SSTa(:,1,1))]);
dummy=ones(4610,length(SSTa(:,1,1)))*variable(1);   % crea una matriz de 2.5829e-41
dummy(2:48*96+1,:)=SSTa2;            % rellena los espacios correspondientes
dummy=dummy(:);

fidw = fopen([path1, char('anom/sst_aEXP' + string(exp) + '.t30.grd')], 'w'); % LINUX
% fidw = fopen([path2, char('sst_aEXP' + string(exp) + '.t30.grd')], 'w'); % WINDOWS
count = fwrite(fidw,dummy,'float','b');
%
clear dummy
%
%
%
%
%
%
%
%
%
%
%
%
%
