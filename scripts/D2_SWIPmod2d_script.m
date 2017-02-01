%%% SURFACE-WAVE dispersion INVERSION & PROFILING (SWIP)
%%% MODULE D2 : SWIPmod2d.m
%%% S. Pasquet - V17.01.25
%%% SWIPmod2d.m plots observed, calculated and residual pseudo-sections
%%% It also plots Vp, Vs, Vp/Vs, Poisson's ratio and auxiliary data 2D sections

dpMIN=0; % Min depth (m)

run('SWIP_defaultsettings')

if input_vel==0 || input_vel>2
    fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
    fprintf('\n    Select at least one model');
    fprintf('\n   Set either "input_vel" to 1 or 2');
    fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n');
    return
end

if plot2dcal==0 && plot2dmod==0 && plothisto==0 && savexzv==0
    fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
    fprintf('\n           Select at least one plot/save option');
    fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n');
    return
end

% Initialization (same for D1 and D2)
if input_vel==1
    [dir_all,dir_inv_img]=dir_create(2);
    if dir_all.dir_main==0
        return
    end
    if dir_inv_img.dir_rep_inv==0
        return
    end
    % Read previous inversion settings
    dir_rep_inv=dir_inv_img.dir_rep_inv;
    dir_img_inv=dir_inv_img.dir_img_inv;
    dir_xzv_inv=dir_inv_img.dir_xzv_inv;
    matstruct=dir(fullfile(dir_rep_inv,'*.invparam.mat'));
    matfileinv=fullfile(dir_rep_inv,matstruct.name);
    try
        load(matfileinv);
    catch
        fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
        fprintf('\n   Missing .mat file in inversion folder');
        fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n');
        return
    end
    if isfield(inv_set,'maxmodeinv')==1
        maxmodeinv=inv_set.maxmodeinv;
    else
        nmodeinv=inv_set.nmodeinv;
        maxmodeinv=nmodeinv-1;
    end
    paramtype=inv_set.paramtype;
else
    dir_all=dir_create(0);
    if dir_all.dir_main==0
        return
    end
    maxmodeinv=[];
end
dir_dat=dir_all.dir_dat;
dir_img=dir_all.dir_img;
dir_pick=dir_all.dir_pick;
dir_param=dir_all.dir_param;
dir_targ=dir_all.dir_targ;
dir_inv=dir_all.dir_inv;
dir_xzv=dir_all.dir_xzv;
matstruct=dir(fullfile(dir_dat,'*.param.mat'));
matfile=fullfile(dir_dat,matstruct.name);
try
    load(matfile);
catch
    fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
    fprintf('\n   Missing .mat file in file.dat folder');
    fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n');
    return
end
dx=acquiparam.dx;
topo=acquiparam.topo;
nWmin=stackdisp.nWmin;
nWmax=stackdisp.nWmax;
xsca=pomega.xsca;
XmidT=xmidparam.XmidT; % Get Xmids
Xlength=length(XmidT); % Get Xmids
xmidformat=stackdisp.xmidformat;
if exist('Xmidselec','var')~=1 || isempty(Xmidselec)==1
    Xmidselec=1:Xlength;
end
if max(Xmidselec)>Xlength
    Xmidselec=Xmidselec(Xmidselec<=Xlength);
end
nshot=xmidparam.nshot;
fmin=pomega.fmin;
fmax=pomega.fmax;
f=plotopt.f;
nf=length(f);
if exist('targopt_inv','var')==0
    wave=targopt.wave(1);
    resampvec=targopt.resampvec;
    sampling=targopt.sampling;
    lmaxpick=targopt.lmaxpick;
else
    wave=targopt_inv.wave(1);
    resampvec=targopt_inv.resampvec;
    sampling=targopt_inv.sampling;
    lmaxpick=targopt_inv.lmaxpick;
end
zround=xmidparam.zround; % Get topography
if isempty(dpMAX)==1
    if input_vel==1
        fprintf('\n  Looking for maximum HSD...\n');
        dpMAX=zeros(size(Xmidselec));
        for ix=Xmidselec
            dir_rep_ind=fullfile(dir_rep_inv,[num2str(XmidT(ix),xmidformat),'_reports']);
            if exist(dir_rep_ind,'dir')==7
                paramstruct=dir(fullfile(dir_rep_ind,'*.param'));
                for ip=1:length(paramstruct)
                    paramfile=fullfile(dir_rep_ind,paramstruct(ip).name);
                    [~,dpMAX(ix)]=param2mod(paramfile);
                end
            end
        end
        dpMAX=max(dpMAX);
        if dpMAX == 0
            if paramtype>0
                paramstruct=dir(fullfile(dir_targ,['*.type',num2str(paramtype),'.param']));
                dpMAX=zeros(size(paramstruct));
                for ip=1:length(paramstruct)
                    paramfile=fullfile(dir_targ,paramstruct(ip).name);
                    [~,dpMAX(ip)]=param2mod(paramfile);
                end
                dpMAX=max(dpMAX);
            else
                if isempty(strfind(dir_rep_inv,dir_inv))==1
                    dir_rep_inv=fullfile(dir_all.dir_start,dir_rep_inv);
                end
                paramname=fullfile(dir_param,[dir_rep_inv(length(dir_inv)+1:end),'.param']);
                if exist(paramname,'file')==2
                    [~,dpMAX]=param2mod(paramname);
                else
                    fprintf('\n  !!!!!!!!!!!!!!!!!!!!!');
                    fprintf('\n   Missing .param file');
                    fprintf('\n  !!!!!!!!!!!!!!!!!!!!!\n\n');
                    return
                end
            end
        end
    else
        dpMAX=max(resampvec);
    end
    dpMIN=0;
end
maxdepth=ceil(dpMAX/dz)*dz;
depth=max(zround):-dz:min(zround)-maxdepth; % Depth vector with topo
ZZ=0:dz:maxdepth;
nZ=length(ZZ);

% File and folder names initialization
if nbest==0
    extens=['.bweb',num2str(outpoints)]; % Best within error bars
else
    extens=['.best',num2str(nbest)]; % Arbitrary nb
end
if input_vel==1
    dir_img_inv_mod=fullfile(dir_img_inv,['models',extens]);
    dir_img_inv_2d=fullfile(dir_img_inv_mod,'2dmodels');
    dir_xzv_inv_mod=fullfile(dir_xzv_inv,['models',extens]);
else
    dir_img_ind=fullfile(dir_img,'Usermodels');
    dir_img_inv_mod=dir_img_ind;
    dir_img_inv_2d=fullfile(dir_img_ind,'2dmodels');
    dir_xzv_inv_mod=fullfile(dir_xzv,'Usermodels');
end
if exist(dir_img_inv_2d,'dir')~=7
    mkdir(dir_img_inv_2d);
end
if exist(dir_xzv_inv_mod,'dir')~=7
    mkdir(dir_xzv_inv_mod);
end
if modeltype==1
    modeltype='best'; avertype='Vms';
elseif modeltype==2
    modeltype='layered'; avertype='Vms';
elseif modeltype==3
    modeltype='smooth'; avertype='Vms';
elseif modeltype==4
    modeltype='layered'; avertype='Vws';
elseif modeltype==5
    modeltype='smooth'; avertype='Vws';
elseif modeltype==6
    modeltype='ridge'; avertype='Vms';
else
    modeltype='smooth'; avertype='Vws';
    fprintf('\n  Weighted smooth model selected by default\n');
end

XmidT_vp=XmidT; depth_vp=depth;

% Select velocity and STD models
if ((input_vel==1 && usevptomo==1) || input_vel==2) && (plot2dcal==1 || plothisto==1 || plot2dmod==1 || savexzv==1)
    fprintf('\n  Select Vp model file\n');
    [filevel,pathvel]=uigetfile({'*.model;*.dat;*.xzv;*.txt'},'Select Vp model');
    Vpfile=fullfile(pathvel,filevel); % File with velocity (3 columns X,Z,Vp)
    if pathvel==0
        VpI=[]; VpItomo=[]; VsItomo=[]; usevptomo=0; zinc=0:dz:maxdepth;
        fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
        fprintf('\n   No Vp model file selected - Use Vp from SWIP');
        fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        if input_vel==2
            return
        end
    else
        try
            if input_vel==1 && usevptomo==1
                VpI=readtomo(Vpfile,0,XmidT,depth,xsca,vpaver,mean([nWmin,nWmax]),dx); % Read Vp tomo file
                if vpmask==1
                    XmidT_vp=XmidT; depth_vp=depth;
                else
                    [VpItomo,XmidT_vp,depth_vp]=readtomo(Vpfile,0,[],[],xsca); % Read Vp tomo file
                end
            elseif input_vel==2
                [VpItomo,Xi,Zi]=readtomo(Vpfile,0); % Read Vp tomo file
                VpItomo=flipud(VpItomo);
                zround=interp1(XmidT,zround,unique(Xi),'linear','extrap');
                XmidT=unique(Xi);
                depth=flipud(unique(Zi));
                Xlength=length(XmidT);
                Xmidselec=1:Xlength;
            end
        catch
            fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
            fprintf('\n   Invalid Vp model file - Use Vp from SWIP');
            fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
            VpI=[]; VpItomo=[]; VsItomo=[]; usevptomo=0; zinc=0:dz:maxdepth;
            if input_vel==2
                return
            end
        end
    end
    %     if plot1dstd==1
    %         [filevelstd,pathvelvelstd]=uigetfile({'*.model;*.dat;*.xzv;*.txt'},'Select Vp STD model');
    %         if pathvelvelstd==0
    %             VpIstd=[]; VpIstdtomo=[];
    %         else
    %             Vpstdfile=fullfile(pathvelstd,filevelstd); % File with velocity STD (3 columns X,Z,VpSTD)
    %             VpIstd=readtomo(Vpstdfile,0,XmidT,depth,xsca,vpaver,mean([nWmin,nWmax]),dx); % Read Vp STD tomo file
    %             VpIstdtomo=readtomo(Vpstdfile,0,XmidT,depth,xsca); % Read Vp STD tomo file
    %         end
    %     end
    if input_vel==2 && isempty(VpItomo)==0
        fprintf('\n  Select Vs model file (cancel if no Vs model available)\n');
        [filevel,pathvel]=uigetfile({'*.model;*.dat;*.xzv;*.txt'},'Select Vs model (cancel if no Vs model available)');
        if pathvel==0
            VsItomo=[]; plot2dcal=0; plothisto=0;
            fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
            fprintf('\n   No Vs model file selected - Ignore Vstomo');
            fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        else
            Vsfile=fullfile(pathvel,filevel); % File with velocity (3 columns X,Z,Vs)
            try
                VsItomo=readtomo(Vsfile,0,XmidT,depth,xsca); % Read Vs tomo file
                VpItomo(isnan(VsItomo)==1)=NaN;
                VsItomo(isnan(VpItomo)==1)=NaN;
            catch
                fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                fprintf('\n   Invalid Vs model file - Ignore Vstomo');
                fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
                VsItomo=[]; VpItomo=[];
            end
        end
        %         if plot1dstd==1
        %             [filevelstd,pathvelvelstd]=uigetfile({'*.model;*.dat;*.xzv;*.txt'},'Select Vs STD model');
        %             if pathvelvelstd==0
        %                 VsIstdtomo=[];
        %             else
        %                 Vsstdfile=fullfile(pathvelstd,filevelstd); % File with velocity STD (3 columns X,Z,VsSTD)
        %                 VsIstdtomo=readtomo(Vsstdfile,0,XmidT,depth,xsca); % Read Vs STD tomo file
        %                 VpIstdtomo(isnan(VsIstdtomo)==1)=NaN;
        %                 VsIstdtomo(isnan(VpIstdtomo)==1)=NaN;
        %             end
        %         end
    end
else
    zinc=0:dz:maxdepth;
end

% Specific settings for D2
indf=zeros(Xlength,1);
indi=indf; DOI=indf*NaN;

if input_aux==1
    fprintf('\n  Select auxiliary data file\n');
    [fileaux,pathaux]=uigetfile({'*.model;*.dat;*.xzv;*.txt'},'Select auxiliary data file');
    Auxfile=fullfile(pathaux,fileaux); % File with auxiliary data (3 columns X,Z,Aux)
    if pathaux==0
        AuxI=[];
        fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
        fprintf('\n   No auxiliary data file selected - Ignore auxiliary data');
        fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        input_aux=0;
    else
        if input_vel==1 && auxmask==1
            try
                AuxI=readtomo(Auxfile,0,XmidT,depth,xsca); % Read auxiliary file
                XmidT_aux=XmidT; depth_aux=depth;
                auxmat=AuxI;
            catch
                fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                fprintf('\n   Invalid auxiliary data file - Ignore auxiliary data');
                fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
                AuxI=[];
            end
        else
            try
                [AuxI,XmidT_aux,depth_aux]=readtomo(Auxfile,0,[],[],xsca); % Read auxiliary file
                auxmat=AuxI;
            catch
                fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                fprintf('\n   Invalid auxiliary datafile - Ignore auxiliary data');
                fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
                return
            end
        end
    end
end

% Initialization of the maximum number of modes
if isempty(maxmodeinv)==1
    pvcstruct=dir(fullfile(dir_pick,'*.pvc'));
    npvc=length(pvcstruct);
    M=[];
    for ip=1:npvc
        pvcfile=pvcstruct(ip).name;
        m=str2double(pvcfile(end-4));
        if ismember(m,M)==0
            M=[M,m];
        end
    end
    if isempty(M)==0
        maxmodeinv=ones(1,Xlength)*max(M);
    else
        maxmodeinv=zeros(1,Xlength);
    end
end

% Initialization of velocity matrices
vph2dobs=cell(max(maxmodeinv)+1,1);
for ip=1:max(maxmodeinv)+1
    vph2dobs{ip}=zeros(length(resampvec),Xlength)*NaN;
end
delta2dobs=vph2dobs;
vph2dobsALL=[]; delta2dobsALL=[];
if plot2dcal==1 || plothisto==1
    vph2dcal=vph2dobs;
    vph2dres=vph2dobs;
    misfitall=zeros(1,Xlength)*NaN;
    vph2dcalALL=[];
end

vpmat=zeros(length(depth),Xlength).*NaN;
vpmatok=vpmat;
vsmat=vpmat;
vpvsmat=vpmat;
vptvsmat=vpmat;
poismat=vpmat;
rhomat=vpmat;
vsstdmat=vpmat;
maskmat=vpmat;
maskmatvp=vpmat;

[testimgmgck,~]=unix('which montage');
[testpdfjam,~]=unix('which pdfjam');
testplot=((testpdfjam==0 && strcmp(imgform,'pdf')==1) || (testimgmgck==0 && strcmp(imgform,'pdf')==0 && strcmp(imgform,'fig')==0));
if concat == 0
    testplot = 0;
end

if Xlength==1
    fprintf('\n  Only one Xmid - cannot plot 2D sections\n');
    return
end

fprintf('\n  **********************************************************');
fprintf('\n  **********************************************************\n');

%%
modexist=zeros(1,Xlength);
fprintf('\n  Reading models...\n');
for ix=Xmidselec
    if plot2dcal==0 && plot2dmod==0 && plothisto==0 && savexzv==0
        break
    end
    
    % Initialisation
    vph2dobsall=[]; delta2dobsall=[]; vph2dcalall=[];
    if input_vel==1
        dir_rep_ind=[dir_rep_inv,'/',num2str(XmidT(ix),xmidformat),'_reports'];
        if exist(dir_rep_ind,'dir')~=7 && sum(nshot(ix,:))>=0
            fprintf(['\n  No data/inversion for Xmid',num2str(ix),' = ',...
                num2str(XmidT(ix),xmidformat),' m\n']);
            continue
        end
    end
    
    % Get picked dispersion curves
    if plot2dcal==1 || plothisto==1
        if input_vel~=1
            nametarg=fullfile(dir_targ,[num2str(XmidT(ix),xmidformat),'.target']);
        else
            nametarg=fullfile(dir_rep_ind,[num2str(XmidT(ix),xmidformat),'.target']);
            if exist(nametarg,'file')~=2 && sum(nshot(ix,:))>=0
                if exist(nametarg(1:end-3),'file')==2
                    movefile(nametarg(1:end-3),nametarg);
                else
                    fprintf(['\n  No dispersion picked for Xmid',num2str(ix),' = ',...
                        num2str(XmidT(ix),xmidformat),' m\n']);
                end
            end
        end
        if exist(nametarg,'file')~=2
            if input_vel==1
                npvc=0;
            else
                pvcstruct=dir(fullfile(dir_pick,[num2str(XmidT(ix),xmidformat),'.*.pvc']));
                npvc=length(pvcstruct);
                modes=zeros(npvc,1)*NaN;
                freqresamp=cell(npvc,1);
                vresamp=freqresamp; deltaresamp=freqresamp;
                for ip=1:npvc
                    pvcfile=pvcstruct(ip).name;
                    modes(ip)=str2double(pvcfile(end-4)); % Mode number
                    if modes(ip)>maxmodeinv(ix)
                        break
                    end
                    Vprev=load(fullfile(dir_pick,pvcfile));
                    % Resample in lambda or frequency
                    [freqresamp{modes(ip)+1},vresamp{modes(ip)+1},deltaresamp{modes(ip)+1}]=...
                        resampvel(Vprev(:,1),Vprev(:,2),Vprev(:,3),resampvec,sampling,1);
                end
                if npvc==0
                    npvc=maxmodeinv(ix)+1; modes=0:npvc-1;
                    freqresamp=cell(npvc,1);
                    vresamp=freqresamp; deltaresamp=freqresamp;
                end
            end
        else
            % Read target file to get picked dispersion curves
            [freqresamp,vresamp,deltaresamp,modes]=targ2pvc(nametarg);
            npvc=length(modes);
            lmaxpicktmp=zeros(npvc,1);
            for ip=1:npvc
                % Resample in lambda or frequency
                [freqresamp{modes(ip)+1},vresamp{modes(ip)+1},deltaresamp{modes(ip)+1}]=...
                    resampvel(freqresamp{modes(ip)+1},vresamp{modes(ip)+1},...
                    deltaresamp{modes(ip)+1},resampvec,sampling,1);
                lmaxpicktmp(ip)=max(vresamp{modes(ip)+1}./freqresamp{modes(ip)+1});
            end
            lmaxpick(ix)=max(lmaxpicktmp);
        end
    end
    
    % Read velocity models
    if input_vel==1
        % Velocity file name
        filevel=fullfile(dir_rep_ind,[num2str(XmidT(ix),xmidformat),extens,'.',...
            avertype,'.',modeltype]);
        % Standard deviation file name
        filevelstd=fullfile(dir_rep_ind,[num2str(XmidT(ix),xmidformat),extens,'.',...
            'VmsStd.',modeltype]);
        if strcmp(modeltype,'best')==1
            filevelstd=fullfile(dir_rep_ind,[num2str(XmidT(ix),xmidformat),extens,'.',...
                'VmsStd.layered']);
        end
        if strcmp(modeltype,'ridge')==1
            filevelstd=fullfile(dir_rep_ind,[num2str(XmidT(ix),xmidformat),extens,'.',...
                'VmsStd.smooth']);
        end
        
        if exist(filevel,'file')==0
            if exist(dir_rep_ind,'dir')==7 && sum(nshot(ix,:))>=0
                fprintf(['\n  No SWIP model for Xmid',num2str(ix),' = ',...
                    num2str(XmidT(ix),xmidformat),' m\n']);
            end
            modvel=[];
        else
            modvel=dlmread(filevel,'',1,0);
            moddepth=[0;cumsum(modvel(:,1))];
            modstd=dlmread(filevelstd,'',1,0);
            depthstd=[0;modstd(:,1)];
            
            if maxdepth>moddepth(end)
                moddepth(end)=maxdepth;
                %                 maxdepth=moddepth(end);
                zinc=0:dz:maxdepth;
            else
                modvel=modvel(moddepth<maxdepth,:);
                modstd=modstd(moddepth<maxdepth,:);
                moddepth=[0;cumsum(modvel(:,1))];
                depthstd=depthstd(1:length(moddepth));
            end
            thick=modvel(:,1);
            vpsw=modvel(:,2);
            vssw=modvel(:,3);
            rhosw=modvel(:,4);
            
            depthstd(end)=0;
            vpstd=modstd(:,2);
            vsstd=modstd(:,3);
            rhostd=modstd(:,4);
            
            if usevptomo==1
                filevel=[filevel,'_vptomo'];
                filedisp=[filevel,'.disp'];
                vptomo=VpI(VpI(:,ix)>0,ix);
                if isempty(vptomo)~=1
                    vptomo=[vptomo(1);vptomo;vptomo(end)];
                    ztmp=dz.*ones(1,size(VpI(VpI(:,ix)>0,ix),1));
                    zinc=[0,cumsum(ztmp)];
                    if max(zinc)>maxdepth && abs(max(zinc)-maxdepth)>1e-10
%                         zinc=0:dz:max(zinc);
                        vptomo=vptomo(1:length(zinc)+1);
                    elseif max(zinc)<maxdepth && abs(max(zinc)-maxdepth)>1e-10
                        zinc=0:dz:maxdepth;
                        vptomo2=vptomo(end)*ones(length(zinc)+1,1);
                        vptomo2(1:length(vptomo))=vptomo;
                        vptomo=vptomo2;
                    else
                        zinc=0:dz:maxdepth;
                    end
                    [vpsw,~,~,vssw]=velresamp(zinc,vptomo,moddepth,vssw,0.1,0,0);
                else
                    modvel=[];
                end
            else
                filedisp=[filevel,'.disp'];
            end
        end
        
    elseif input_vel==2
        filevel=fullfile(dir_dat,[num2str(XmidT(ix),xmidformat),'.tomo']);
        filedisp=fullfile(dir_dat,[num2str(XmidT(ix),xmidformat),'.tomo.disp']);
        nlay=size(VpItomo(VpItomo(:,ix)>0,ix),1);
        ztomo=dz.*ones(nlay,1);
        zinc=[0;cumsum(ztomo)];
        vptomo=VpItomo(VpItomo(:,ix)>0,ix);
        if isempty(VsItomo)==0
            vstomo=VsItomo(VsItomo(:,ix)>0,ix);
        else
            vstomo=[];
        end
        if max(zinc)<maxdepth
            zinc=0:dz:maxdepth;
            vptomo2=NaN*ones(length(zinc),1);
            vptomo2(1:length(vptomo))=vptomo;
            vptomo=vptomo2;
            if isempty(VsItomo)==0
                if isempty(vstomo)==0
                    vstomo2=NaN*ones(length(zinc),1);
                    vstomo2(1:length(vstomo))=vstomo;
                    vstomo=vstomo2;
                else
                    vstomo=vptomo*NaN;
                end
            end
        end
        
        if isempty(vptomo)~=1
            if isempty(vstomo)~=1
                for ll=1:nlay
                    while poisson(vptomo(ll),vstomo(ll))<=0.1
                        vptomo(ll)=vptomo(ll)+1;
                        vstomo(ll)=vstomo(ll)-1;
                    end
                end
            end
        else
            if sum(nshot(ix,:))>=0
                fprintf(['\n  No Vp or Vs from tomo for Xmid',num2str(ix),' = ',...
                    num2str(XmidT(ix),xmidformat),' m\n']);
            end
            vptomo=[]; vstomo=[];
        end
    else
        filevel=[];
    end
    
    D=[];
    if (input_vel==1 && isempty(modvel)==0) || (input_vel==2 && isempty(vptomo)~=1)
        modexist(ix)=1;
        
        if plot2dcal==1 || plothisto==1
            if input_vel==1 && usevptomo==1 && isempty(vptomo)~=1
                dinsave(filevel,thick,vpsw,vssw,rhosw);
            elseif input_vel==2 && isempty(vptomo)~=1 && isempty(vstomo)~=1
                if isempty(rhoMIN)==1
                    flagrho=1;
                    rhoMIN=1800; rhoMAX=1800;
                else
                    flagrho=0;
                end
                dinsave(filevel,ztomo,vptomo,vstomo,mean([rhoMIN,rhoMAX]));
                if flagrho==1
                    rhoMIN=[]; rhoMAX=[];
                end
            end
            
            nftest=nf;
            while nftest>10
                matgpdc(filevel,maxmodeinv(ix)+1,wave,nftest-1,fmin+(fmax-fmin)/nftest,fmax,sampling,filedisp);
                D=readdisp(filedisp,maxmodeinv(ix)+1);
                if isempty(D)==1
                    if nftest==nf
                        if input_vel==1
                            fprintf(['\n  Re-run forward calculation with less frequency samples for Xmid',...
                                num2str(ix),' = ',num2str(XmidT(ix),xmidformat),' m\n']);
                        else
                            fprintf(['\n  Re-run forward calculation with less frequency samples for X = ',...
                                num2str(XmidT(ix),xmidformat),' m\n']);
                        end
                    end
                    nftest=nftest-10;
                else
                    break
                end
            end
            
            if usevptomo==1 && input_vel==1
                delete(filevel);
            elseif input_vel==2
                delete(filevel);
            end
            delete(filedisp);
        end
        
        if plot2dmod==1 || savexzv==1
            if (plotDOI==0 || maskDOI==0) && input_vel==1
                DOI(ix)=zround(ix)-maxdepth;
                indf(ix)=round(maxdepth/dz);
            end
            % Get DOI (Lmax*doifact)
            if (plotDOI==1 || maskDOI==1) && input_vel==1
                DOI(ix)=zround(ix)-lmaxpick(ix)*doifact;
                indf(ix)=round((lmaxpick(ix)*doifact)/dz);
            end
            % Get DOI with standard deviation
            if (plotDOI==2 || maskDOI==2) && input_vel==1
                if exist('vsstd','var')==1 && isempty(vsstd)==0
                    flipmoddepth=flipud(moddepth);
                    flipvsstd=flipud([vsstd;vsstd(end)]);
                    if sum(vsstd)~=0 % Case more than one model is in the error bars
                        indhsd=find(flipvsstd<stdMAX,1,'first');
                        if indhsd~=1 % Case there are some VsSTD < stdMAX
                            hsdtmp=flipmoddepth(indhsd-1);
                        elseif indhsd==1 % Case all VsSTD < stdMAX
                            hsdtmp=0;
                        else % Case all VsSTD > stdMAX
                            hsdtmp=[];
                        end
                    else % Only one model => VsSTD=0
                        hsdtmp=lmaxpick(ix)*doifact; % Fix higher limit to lmaxpick(ix)*doifact
                    end
                    if isempty(hsdtmp)==1 % Case all VsSTD > stdMAX
                        hsdtmp=moddepth(find(vsstd<=median(vsstd),1,'first'));
                    elseif hsdtmp==0 % Case all VsSTD < stdMAX
                        hsdtmp=flipmoddepth(find(flipvsstd<flipvsstd(1),1,'first'));
                        if isempty(hsdtmp)==1
                            hsdtmp=flipmoddepth(1);
                        end
                    end
                    if hsdtmp>lmaxpick(ix)*doifact
                        hsdtmp=lmaxpick(ix)*doifact; % Fix higher limit to lmaxpick(ix)*doifact
                    end
                    if plotDOI==2 || maskDOI==2
                        DOI(ix)=zround(ix)-hsdtmp;
                    end
                    if maskDOI==2
                        indf(ix)=round((hsdtmp)/dz);
                    end
                else
                    if plotDOI==2 || maskDOI==2
                        DOI(ix)=zround(ix)-maxdepth;
                    end
                    if maskDOI==2
                        indf(ix)=round((maxdepth)/dz);
                    end
                end
            end
            if (plotDOI==3 || maskDOI==3) && input_vel==1
                flipmoddepth=flipud(moddepth);
                flipvsstd=flipud([vsstd;vsstd(end)]);
                hsdtmp=flipmoddepth(find(flipvsstd<max(flipvsstd) & ...
                    flipmoddepth<flipmoddepth(find(flipvsstd==max(flipvsstd),1,'last')),1,'first'));
                if isempty(hsdtmp)==1
                    hsdtmp=0;
                end
                if plotDOI==3 || maskDOI==3
                    DOI(ix)=zround(ix)-hsdtmp;
                end
                if maskDOI==3
                    indf(ix)=round((hsdtmp)/dz);
                end
            end
            if DOI(ix)<zround(ix)-maxdepth
                DOI(ix)=zround(ix)-maxdepth;
            end
            
            % Look for topo index
            crit=abs(zround(ix)-depth);
            indi(ix)=find(crit==min(crit),1);
            
            if input_vel==1
                vp0=velresamp(moddepth,[vpsw;vpsw(end)],zinc);
                vs0=velresamp(moddepth,[vssw;vssw(end)],zinc);
                rho0=velresamp(moddepth,[rhosw;rhosw(end)],zinc);
                vsstd0=velresamp(moddepth,[vsstd;vsstd(end)],zinc);
            elseif input_vel==2
                vp0=vptomo;
                vs0=vstomo;
            end
            if indf(ix)>length(depth)-indi(ix) || isnan(indf(ix))==1
                indf(ix)=length(depth)-indi(ix);
            end
            if indf(ix)>length(vp0)
                indf(ix)=length(vp0);
            end
            vpmat(indi(ix):indi(ix)+length(vp0)-1,ix)=vp0;
            vpmatok(indi(ix):indi(ix)+length(vp0)-1,ix)=vp0;
            if input_vel==1 || (input_vel==2 && isempty(VsItomo)==0)
                maskmat(indi(ix):indi(ix)+indf(ix)-1,ix)=ones(size(vs0(1:indf(ix))));
                maskmatvp(indi(ix):indi(ix)+indf(ix)-1,ix)=ones(size(vs0(1:indf(ix))));
                vsmat(indi(ix):indi(ix)+length(vs0)-1,ix)=vs0;
                vpvsmat(indi(ix):indi(ix)+length(vs0)-1,ix)=vp0./vs0;
                vptvsmat(indi(ix):indi(ix)+length(vs0)-1,ix)=vp0.*vs0;
                poismat(indi(ix):indi(ix)+length(vs0)-1,ix)=poisson(vp0,vs0);
            end
            if input_vel==1
                rhomat(indi(ix):indi(ix)+length(rho0)-1,ix)=rho0;
                vsstdmat(indi(ix):indi(ix)+length(vsstd0)-1,ix)=vsstd0;
            end
        end
    end
    if plot2dcal==1 || plothisto==1
        for ip=1:npvc
            if exist('vresamp','var')==1 && isempty(vresamp{modes(ip)+1})==0
                vph2dobs{modes(ip)+1}(:,ix)=vresamp{modes(ip)+1}';
                delta2dobs{modes(ip)+1}(:,ix)=deltaresamp{modes(ip)+1}';
            else
                vph2dobs{modes(ip)+1}(:,ix)=NaN;
                delta2dobs{modes(ip)+1}(:,ix)=NaN;
            end
            if isempty(D)==0
                freqcal=D{modes(ip)+1,1}; % Frequency
                vcal=1./D{modes(ip)+1,2}; % Velocity
                if isnan(freqcal)==0
                    % Resample in lambda or frequency
                    [~,vresamp{modes(ip)+1}]=resampvel(freqcal,vcal,...
                        vcal,resampvec,sampling,1);
                    vph2dcal{modes(ip)+1}(:,ix)=vresamp{modes(ip)+1};
                else
                    vph2dcal{modes(ip)+1}(:,ix)=NaN;
                end
                if input_vel==1
                    vph2dcal{modes(ip)+1}(isnan(vph2dobs{modes(ip)+1}(:,ix)),ix)=NaN;
                    vph2dobs{modes(ip)+1}(isnan(vph2dcal{modes(ip)+1}(:,ix)),ix)=NaN;
                end
                vph2dobsall=[vph2dobsall;vph2dobs{modes(ip)+1}(:,ix)];
                delta2dobsall=[delta2dobsall;delta2dobs{modes(ip)+1}(:,ix)];
                vph2dcalall=[vph2dcalall;vph2dcal{modes(ip)+1}(:,ix)];
            else
                vph2dobsall=[vph2dobsall;vph2dobs{modes(ip)+1}(:,ix)*NaN];
                delta2dobsall=[delta2dobsall;vph2dobs{modes(ip)+1}(:,ix)*NaN];
                vph2dcalall=[vph2dcalall;vph2dobs{modes(ip)+1}(:,ix)*NaN];
            end
        end
        if sum(isnan(vph2dcalall))~=length(vph2dcalall)
            misfitall(ix)=sqrt(sum(((vph2dcalall(vph2dobsall>0)...
                -vph2dobsall(vph2dobsall>0)).^2./...
                (length(vph2dobsall)*(delta2dobsall(vph2dobsall>0).^2)))));
            vph2dcalALL=[vph2dcalALL;vph2dcalall];
            vph2dobsALL=[vph2dobsALL;vph2dobsall];
            delta2dobsALL=[delta2dobsALL;delta2dobsall];
        else
            misfitall(ix)=NaN;
        end
    end
end

if sum(modexist)==0 && (plot2dcal==1 || plot2dmod==1 || plothisto==1 || savexzv==1)
    fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
    fprintf('\n                No model existing with these settings');
    fprintf('\n         Check settings => "modeltype", "nbest" and "outpoints"');
    fprintf('\n  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
end

fprintf('\n  **********************************************************');
fprintf('\n  **********************************************************\n');

if usevptomo==1 && input_vel==1
    avertype=[avertype,'_Vptomo'];
    if vpmask==0
        vpmatok=VpItomo;
        maskmatvp=ones(size(vpmatok));
    else
        vpmatok=vpmat;
    end
elseif input_vel==2
    vpmatok=VpItomo;
    maskmat=ones(size(maskmat));
    maskmatvp=ones(size(maskmatvp));
    if isempty(VsItomo)==0
        vsmat=VsItomo;
        vpvsmat=vpmat./vsmat;
        poismat=poisson(vpmat,vsmat);
    else
        vsmat=vpmat;
    end
    avertype='user';
    modeltype='tomo';
end

%%
if sum(modexist)>0
    if plot2dcal==1 || plothisto==1
        fprintf('\n  Saving observed, calculated and residual phase velocity sections\n');
        nmodeinv=0;
        for ip=1:max(maxmodeinv)+1
            fprintf(['\n      Mode ',num2str(ip-1),'\n']);
            if sum(sum(isnan(vph2dcal{ip})))==numel(vph2dcal{ip})
                continue
            end
            nmodeinv=nmodeinv+1;
            if plot2dcal==1
                if input_vel==1
                    % Observed phase velocity
                    if sampling==0
                        f1=plot_img(showplot,XmidT,resampvec,vph2dobs{ip},map1,axetop,0,cbpos,fs,'X (m)',...
                            freqtitle_short,'Vphase (m/s)',[xMIN xMAX],[0 max(resampvec)],...
                            [Vphmin Vphmax],xticks,lticks,vphticks,[],[],vphISO,[12 0 24 12],[],1,0);
                    else
                        f1=plot_img(showplot,XmidT,resampvec,vph2dobs{ip},map1,axetop,1,cbpos,fs,'X (m)',...
                            lamtitle,'Vphase (m/s)',[xMIN xMAX],[lamMIN lamMAX],...
                            [vphMIN vphMAX],xticks,lticks,vphticks,[],[],vphISO,[12 0 24 12],[],1,0);
                    end
                    sizeax=get(gca,'position');
                    fileobs=fullfile(dir_img_inv_2d,['Vphobs','.M',num2str(ip-1),'.',avertype,...
                        '.',modeltype,'.',imgform]);
                    save_fig(f1,fileobs,imgform,imgres,1,1-testplot);
                    if showplot==0
                        close(f1);
                    else
                        showplot=showplot+1;
                    end
                end
                
                % Calculated phase velocity
                if sampling==0
                    f1=plot_img(showplot,XmidT,resampvec,vph2dcal{ip},map1,axetop,0,cbpos,fs,'X (m)',...
                        freqtitle_short,'Vphase (m/s)',[xMIN xMAX],[0 max(resampvec)],...
                        [Vphmin Vphmax],xticks,lticks,vphticks,[],[],vphISO,[12 0 24 12],[],1,0);
                else
                    f1=plot_img(showplot,XmidT,resampvec,vph2dcal{ip},map1,axetop,1,cbpos,fs,'X (m)',...
                        lamtitle,'Vphase (m/s)',[xMIN xMAX],[lamMIN lamMAX],...
                        [vphMIN vphMAX],xticks,lticks,vphticks,[],[],vphISO,[12 0 24 12],[],1,0);
                end
                filecal=fullfile(dir_img_inv_2d,['Vphcalc','.M',num2str(ip-1),'.',avertype,...
                    '.',modeltype,'.',imgform]);
                save_fig(f1,filecal,imgform,imgres,1,1-testplot);
                if showplot==0
                    close(f1);
                else
                    showplot=showplot+1;
                end
            end
            
            if input_vel==1
                % Residuals
                vph2dres{ip}=(vph2dobs{ip}-vph2dcal{ip});
                if plot2dcal==1
                    if sampling==0
                        f1=plot_img(showplot,XmidT,resampvec,abs(vph2dres{ip}),map4,axetop,0,cbpos,fs,'X (m)',...
                            freqtitle_short,'Residuals (m/s)',[xMIN xMAX],[0 max(resampvec)],...
                            [Vphmin Vphmax],xticks,lticks,residticks,[],[],[],[12 8.5 24 12],[],1,0);
                    else
                        f1=plot_img(showplot,XmidT,resampvec,abs(vph2dres{ip}),map4,axetop,1,cbpos,fs,'X (m)',...
                            lamtitle,'Residuals (m/s)',[xMIN xMAX],[lamMIN lamMAX],...
                            [residMIN residMAX],xticks,lticks,residticks,[],[],[],[12 8.5 24 12],[],1,0);
                    end
                    fileaux=fullfile(dir_img_inv_2d,['Vphres','.M',num2str(ip-1),'.',avertype,...
                        '.',modeltype,'.',imgform]);
                    save_fig(f1,fileaux,imgform,imgres,1,1-testplot);
                    if showplot==0
                        close(f1);
                    else
                        showplot=showplot+1;
                    end
                end
                
                if plothisto==1
                    % Histograms
                    res=reshape(vph2dres{ip},size(vph2dres{ip},1)*size(vph2dres{ip},2),1);
                    res=res(isnan(res)==0);
                    stdRMS=std(res);
                    meanRMS=mean(res);
                    goodRMS=res(res<meanRMS+2*stdRMS(end) & res>meanRMS-2*stdRMS(end));
                    percent=fix(1000*length(goodRMS)/length(res))/10;
                    % Gaussian curve
                    edges=2*max(abs(min(goodRMS)),max(goodRMS));
                    xgaus=linspace(-edges,edges,100); % Plotting range
                    ygaus=0.5*length(res)*exp(-0.5*((xgaus-mean(res))/std(res)).^ 2)/(std(res)*sqrt(2*pi));
                    
                    if showplot==0
                        f2=figure(1);
                        set(f2,'visible','off')
                    else
                        f2=figure(showplot);
                    end
                    N=hist(res,xgaus);
                    hist(res(abs(res)<edges),xgaus,'linewidth',3);
                    hi=findobj(gca,'Type','patch');
                    set(hi,'FaceColor','r','EdgeColor','k');
                    xlabel('Residuals (m/s)'); ylabel('Nb of samples');
                    h=get(gca,'xlabel'); set(h,'FontSize',fs*2.5);
                    h=get(gca,'ylabel'); set(h,'FontSize',fs*2.5);
                    sizetick=get(gca,'ticklength');
                    set(gca,'TickDir','out','linewidth',3,'XMinorTick','on','YMinorTick','on',...
                        'ticklength',[sizetick(1)*3 sizetick(2)]);
                    h=findall(gcf,'Type','Axes'); set(h,'FontSize',fs*2.5);
                    set(f2,'Units','centimeters');
                    set(gcf,'Position',[25 0 18 18]);
                    hold on;
                    %                     plot(xgaus,ygaus*mean(N)/mean(ygaus),'k','linewidth',3);
                    axis square
                    titr=sprintf(['mu = ',num2str(round(meanRMS*10)/10),...
                        ' m/s  |  sigma = ',num2str(round(stdRMS*10)/10),...
                        ' m/s  \n ',num2str(percent),' %% of the samples < 2*sigma']);
                    title(titr,'fontsize',16);
                    file1=fullfile(dir_img_inv_2d,['HistRes','.M',num2str(ip-1),'.',avertype,...
                        '.',modeltype,'.',imgform]);
                    save_fig(f2,file1,imgform,imgres,1,1-testplot);
                    if showplot==0
                        close(f2);
                    else
                        showplot=showplot+1;
                    end
                end
            end
            if testplot==1 && plot2dcal==1 && input_vel~=2
                panel1=fullfile(dir_img_inv_2d,['Vph_Obs_Cal_Res','.M',num2str(ip-1),'.',avertype,...
                    '.',modeltype,'.',imgform]);
                cat_img([fileobs,' ',filecal,' ',fileaux],imgform,1,[],panel1,1);
                delete(fileobs,filecal,fileaux);
            end
            if savexzv==1
                if input_vel==1
                    save_xzv(fullfile(dir_xzv_inv_mod,['Vphobs','.M',num2str(ip-1),'.',avertype,'.',modeltype,'.xzv']),...
                        XmidT,resampvec,vph2dobs{ip});
                end
                save_xzv(fullfile(dir_xzv_inv_mod,['Vphcalc','.M',num2str(ip-1),'.',avertype,'.',modeltype,'.xzv']),...
                    XmidT,resampvec,vph2dcal{ip});
            end
        end
        
        if testplot==1 && plothisto==1 && input_vel~=2
            fprintf('\n  Saving residual histograms\n');
            if nmodeinv<=3
                columns=nmodeinv;
            else
                columns=ceil(nmodeinv/2);
            end
            panel2=fullfile(dir_img_inv_2d,['HistRes.',avertype,'.',modeltype,'.',imgform]);
            cat_img(fullfile(dir_img_inv_2d,['HistRes','.M*.',avertype,...
                '.',modeltype,'.',imgform]),imgform,columns,[],panel2,1);
            delete(fullfile(dir_img_inv_2d,['HistRes','.M*.',avertype,...
                '.',modeltype,'.',imgform]));
        end
        
        if input_vel==1 && plot2dcal==1
            fprintf('\n  Saving inversion misfit graph\n');
            % Plot QC figure
            vph2dobsALL=vph2dobsALL(isnan(vph2dobsALL)==0);
            vph2dcalALL=vph2dcalALL(isnan(vph2dcalALL)==0);
            RMSfinal = sqrt(sum((vph2dcalALL-vph2dobsALL).^2)/length(vph2dcalALL));
            
            % Misfit for each Xmid
            f4=plot_curv(showplot,XmidT,misfitall,[],'.-',[0 0 0],[],axetop,0,0,fs,'X (m)',...
                'Misfit',[],[xMIN xMAX],[0 max(misfitall)+0.05],[],xticks,[],[],[],[],...
                [26 0 24 12],[],[]);
            
            sizeax2=get(gca,'position');
            set(findobj(f4,'Type','Axes'),'ActivePositionProperty','Position');
            set(findobj(f4,'Type','Axes'),'position',...
                [sizeax2(1),sizeax2(2),sizeax(3),sizeax2(4)/3]);
            
            xlabh=get(get(gca,'XLabel'),'extent');
            text(sizeax(1)+5,xlabh(2)/1.5,['Final RMS = ',...
                num2str(round(mean(RMSfinal)*10)/10),' m/s'],'FontSize',fs);
            % Save figure
            file1=fullfile(dir_img_inv_2d,['Misfit.',avertype,'.',modeltype,'.',imgform]);
            save_fig(f4,file1,imgform,imgres,1);
            if showplot==0
                close(f2);
            else
                showplot=showplot+1;
            end
        end
    end
    
    %%
    if plot2dmod==1
        fprintf('\n  Saving 2D sections\n');
        
        if plotiso==1
            specmat=vpmat;
        elseif plotiso==2
            specmat=vsmat;
        elseif plotiso==3
            specmat=vsstdmat;
        elseif plotiso==4
            specmat=vpvsmat;
        elseif plotiso==5
            specmat=poismat;
        elseif plotiso==6
            specmat=auxmat;
        else
            specmat=[];
        end
        if input_vel==2 && plotiso>0
            specmat=flipud(specmat);
        end
        
        % Saving Vs section
        if isempty(zMIN) || isempty(zMAX)
            zMIN=floor(min(min(depth))/10)*10;
            zMAX=ceil(max(max(depth))/10)*10;
        end
        if length(find(isnan(DOI)==0))==1
            blocky=0;
        end
        f1=plot_img(showplot,XmidT,depth,vsmat.*maskmat,map5,axetop,0,cbpos,fs,'X (m)',...
            'Altitude (m)','Vs (m/s)',[xMIN xMAX],[zMIN zMAX],...
            [vsMIN vsMAX],xticks,zticks,vsticks,[],[],vsISO,[12 0 24 12],[],vertex,blocky);
        sizeax=get(gca,'Position');
        if plotiso>0 && isempty(specISO)==0
            hold on;
            if length(specISO)==1
                isoline=[specISO specISO];
            else
                isoline=specISO;
            end
            [cs,hc]=contour(XmidT,depth,specmat,isoline,'color',[0 0 0],'linewidth',1);
            clabel(cs, hc,'Color', 'k', 'Rotation', 0,'fontsize',12,'labelspacing', 500);
            hold off;
        end
        if plottopo==1
            hold on
            plot(topo(:,1),topo(:,2),'k-','linewidth',2);
        end
        if plotDOI>0 && input_vel==1 && length(find(isnan(DOI)==0))>1
            hold on
            dashline(XmidT,DOI,2,2,2,2,'color','k','linewidth',1.5);
        end
        filevs=fullfile(dir_img_inv_2d,['VS.',avertype,...
            '.',modeltype,'.',imgform]);
        if input_vel==1 || (input_vel==2 && isempty(VsItomo)==0)
            save_fig(f1,filevs,imgform,imgres,1,1-testplot);
        end
        if showplot==0
            close(f1);
        else
            showplot=showplot+1;
        end
        
        % Saving Vp section
        f1=plot_img(showplot,XmidT_vp,depth_vp,vpmatok.*maskmatvp,map5,axetop,0,cbpos,fs,'X (m)',...
            'Altitude (m)','Vp (m/s)',[xMIN xMAX],[zMIN zMAX],...
            [vpMIN vpMAX],xticks,zticks,vpticks,[],[],vpISO,[12 8.5 24 12],sizeax,vertex,blocky);
        if plotiso>0 && isempty(specISO)==0
            hold on;
            if length(specISO)==1
                isoline=[specISO specISO];
            else
                isoline=specISO;
            end
            [cs,hc]=contour(XmidT,depth,specmat,isoline,'color',[0 0 0],'linewidth',1);
            clabel(cs, hc,'Color', 'k', 'Rotation', 0,'fontsize',12,'labelspacing', 500);
            hold off;
        end
        if plottopo==1
            hold on
            plot(topo(:,1),topo(:,2),'k-','linewidth',2);
        end
        if plotDOI>0 && input_vel==1 && length(find(isnan(DOI)==0))>1
            hold on
            dashline(XmidT,DOI,2,2,2,2,'color','k','linewidth',1.5);
        end
        filevp=fullfile(dir_img_inv_2d,['VP.',avertype,...
            '.',modeltype,'.',imgform]);
        save_fig(f1,filevp,imgform,imgres,1,1-testplot);
        if showplot==0
            close(f1);
        else
            showplot=showplot+1;
        end
        
        if input_vel==1
            % Saving VsStd section
            f1=plot_img(showplot,XmidT,depth,vsstdmat,map5,axetop,0,cbpos,fs,'X (m)',...
                'Altitude (m)','Vs STD (m/s)',[xMIN xMAX],[zMIN zMAX],...
                [stdMIN stdMAX],xticks,zticks,stdticks,[],[],stdISO,[25 0 24 12],sizeax,vertex,blocky);
            if plottopo==1
                hold on
                plot(topo(:,1),topo(:,2),'k-','linewidth',2);
            end
            if input_vel==1 && length(find(isnan(DOI)==0))>1
                hold on
                dashline(XmidT,DOI,2,2,2,2,'color','k','linewidth',1.5);
            end
            filestd=fullfile(dir_img_inv_2d,['VSstd.',avertype,...
                '.',modeltype,'.',imgform]);
            save_fig(f1,filestd,imgform,imgres,1,1-testplot);
            if showplot==0
                close(f1);
            else
                showplot=showplot+1;
            end
            
            f1=plot_img(showplot,XmidT,depth,vsmat,map5,axetop,0,cbpos,fs,'X (m)',...
                'Altitude (m)','Vs (m/s)',[xMIN xMAX],[zMIN zMAX],...
                [vsMIN vsMAX],xticks,zticks,vsticks,[],[],vsISO,[12 0 24 12],[],vertex,blocky);
            if plottopo==1
                hold on
                plot(topo(:,1),topo(:,2),'k-','linewidth',2);
            end
            if input_vel==1 && length(find(isnan(DOI)==0))>1
                hold on
                dashline(XmidT,DOI,2,2,2,2,'color','k','linewidth',1.5);
            end
            filevs2=fullfile(dir_img_inv_2d,['VS2.',avertype,...
                '.',modeltype,'.',imgform]);
            if input_vel==1 || (input_vel==2 && isempty(VsItomo)==0)
                save_fig(f1,filevs2,imgform,imgres,1,1-testplot);
            end
            if showplot==0
                close(f1);
            else
                showplot=showplot+1;
            end
        end
        
        if input_vel==1 || (input_vel==2 && isempty(VsItomo)==0)
            % Saving Vp/Vs section
            f1=plot_img(showplot,XmidT,depth,vpvsmat.*maskmat,map6,axetop,0,cbpos,fs,'X (m)',...
                'Altitude (m)','Vp/Vs',[xMIN xMAX],[zMIN zMAX],...
                [vpvsMIN vpvsMAX],xticks,zticks,vpvsticks,[],[],vpvsISO,[25 8.5 24 12],sizeax,vertex,blocky);
            if plotiso>0 && isempty(specISO)==0
                hold on;
                if length(specISO)==1
                    isoline=[specISO specISO];
                else
                    isoline=specISO;
                end
                [cs,hc]=contour(XmidT,depth,specmat,isoline,'color',[0 0 0],'linewidth',1);
                clabel(cs, hc,'Color', 'k', 'Rotation', 0,'fontsize',12,'labelspacing', 500);
                hold off;
            end
            if plottopo==1
                hold on
                plot(topo(:,1),topo(:,2),'k-','linewidth',2);
            end
            if plotDOI>0 && input_vel==1 && length(find(isnan(DOI)==0))>1
                hold on
                dashline(XmidT,DOI,2,2,2,2,'color','k','linewidth',1.5);
            end
            filevpvs=fullfile(dir_img_inv_2d,['VPVS.',avertype,...
                '.',modeltype,'.',imgform]);
            save_fig(f1,filevpvs,imgform,imgres,1,1-testplot);
            if showplot==0
                close(f1);
            else
                showplot=showplot+1;
            end
        end
        
        %         if input_vel==1 || (input_vel==2 && isempty(VsItomo)==0)
        %             fprintf('\n  Saving Vp.Vs section\n');
        %             f1=plot_img_log(showplot,XmidT,depth,vptvsmat.*maskmat,map6,axetop,0,cbpos,fs,'X (m)',...
        %                 'Altitude (m)','Vp.Vs',[xMIN xMAX],[zMIN zMAX],...
        %                 [],xticks,zticks,[],[],[],[],[25 8.5 24 12],sizeax,vertex,blocky);
        %             if plotiso>0 && isempty(specISO)==0
        %                 hold on;
        %                 if length(specISO)==1
        %                     isoline=[specISO specISO];
        %                 else
        %                     isoline=specISO;
        %                 end
        %                 [cs,hc]=contour(XmidT,depth,specmat,isoline,'color',[0 0 0],'linewidth',1);
        %                 clabel(cs, hc,'Color', 'k', 'Rotation', 0,'fontsize',12,'labelspacing', 500);
        %                 hold off;
        %             end
        %             if plottopo==1
        %                 hold on
        %                 plot(topo(:,1),topo(:,2),'k-','linewidth',2);
        %             end
        %             if plotDOI>0 && input_vel==1
        %                 hold on
        %                 dashline(XmidT,DOI,2,2,2,2,'color','k','linewidth',1.5);
        %             end
        %             file1=fullfile(dir_img_inv_2d,['VPtVS.',avertype,...
        %                 '.',modeltype,'.',imgform]);
        %             save_fig(f1,file1,imgform,imgres,1);
        %             if showplot==0
        %                 close(f1);
        %             else
        %                 showplot=showplot+1;
        %             end
        %         end
        
        if input_vel==1 || (input_vel==2 && isempty(VsItomo)==0)
            % Saving Poisson's ratio section
            f1=plot_img(showplot,XmidT,depth,poismat.*maskmat,map6,axetop,0,cbpos,fs,'X (m)',...
                'Altitude (m)','Poisson',[xMIN xMAX],[zMIN zMAX],...
                [poisMIN poisMAX],xticks,zticks,poisticks,[],[],poisISO,[25 16 24 12],sizeax,vertex,blocky);
            if plotiso>0 && isempty(specISO)==0
                hold on;
                if length(specISO)==1
                    isoline=[specISO specISO];
                else
                    isoline=specISO;
                end
                [cs,hc]=contour(XmidT,depth,specmat,isoline,'color',[0 0 0],'linewidth',1);
                clabel(cs, hc,'Color', 'k', 'Rotation', 0,'fontsize',12,'labelspacing', 500);
                hold off;
            end
            if plottopo==1
                hold on
                plot(topo(:,1),topo(:,2),'k-','linewidth',2);
            end
            if plotDOI>0 && input_vel==1 && length(find(isnan(DOI)==0))>1
                hold on
                dashline(XmidT,DOI,2,2,2,2,'color','k','linewidth',1.5);
            end
            filepois=fullfile(dir_img_inv_2d,['Poisson.',avertype,...
                '.',modeltype,'.',imgform]);
            save_fig(f1,filepois,imgform,imgres,1,1-testplot);
            if showplot==0
                close(f1);
            else
                showplot=showplot+1;
            end
        end
        if testplot==1
            if input_vel==1 || (input_vel==2 && isempty(VsItomo)==0)
                if input_aux==1 && exist('AuxI','var')==1
                    dispmsg=0;
                else
                    dispmsg=1;
                end
                panel3=fullfile(dir_img_inv_2d,['VP_VS_Pois.',avertype,'.',modeltype,'.',imgform]);
                cat_img([filevp,' ',filevs,' ',filepois],imgform,1,[],panel3,dispmsg);
                panel4=fullfile(dir_img_inv_2d,['VP_VS_VPVS.',avertype,'.',modeltype,'.',imgform]);
                cat_img([filevp,' ',filevs,' ',filevpvs],imgform,1,[],panel4,dispmsg);
            end
            if input_vel==1
                panel5=fullfile(dir_img_inv_2d,['VSstd_VS.',avertype,'.',modeltype,'.',imgform]);
                cat_img([filestd,' ',filevs2],imgform,1,[],panel5,1);
            end
        end
    end
end

if plot2dmod==1 && exist('auxmat','var')==1 && input_aux==1 && isempty(auxmat)==0
    if input_vel==2
        fileAUX=fullfile(dir_img_inv_2d,['AUX.user.tomo.',imgform]);
    else
        fileAUX=fullfile(dir_img_inv_2d,['AUX.',avertype,'.',modeltype,'.',imgform]);
        if maskDOI>0 && auxmask==1
            auxmat(isnan(maskmat)==1)=NaN;
        end
    end
    if input_vel==2 || (input_vel==1 && sum(modexist)>0)
        % Plot auxiliary data section
        if exist('sizeax','var')~=1
            sizeax=[];
        end
        if auxlogscal==1
            f1=plot_img_log(showplot,XmidT_aux,depth_aux,auxmat,map7,axetop,0,cbpos,fs,'X (m)',...
                'Altitude (m)',auxtitle,[xMIN xMAX],[zMIN zMAX],...
                [auxMIN auxMAX],xticks,zticks,auxticks,[],[],auxISO,[25 16 24 12],sizeax,vertex,blocky);
        else
            f1=plot_img(showplot,XmidT_aux,depth_aux,auxmat,map7,axetop,0,cbpos,fs,'X (m)',...
                'Altitude (m)',auxtitle,[xMIN xMAX],[zMIN zMAX],...
                [auxMIN auxMAX],xticks,zticks,auxticks,[],[],auxISO,[25 16 24 12],sizeax,vertex,blocky);
        end
        if plotiso>0 && isempty(specISO)==0
            hold on;
            if length(specISO)==1
                isoline=[specISO specISO];
            else
                isoline=specISO;
            end
            [cs,hc]=contour(XmidT,depth,specmat,isoline,'color',[0 0 0],'linewidth',1);
            clabel(cs, hc,'Color', 'k', 'Rotation', 0,'fontsize',12,'labelspacing', 500);
            hold off;
        end
        if plottopo==1
            hold on
            plot(topo(:,1),topo(:,2),'k-','linewidth',2);
        end
        if plotDOI>0 && input_vel==1 && length(find(isnan(DOI)==0))>1
            hold on
            dashline(XmidT,DOI,2,2,2,2,'color','k','linewidth',1.5);
        end
        save_fig(f1,fileAUX,imgform,imgres,1,1-testplot);
        if showplot==0
            close(f1);
        else
            showplot=showplot+1;
        end
    end
    
    if testplot==1
        if (input_vel==1 && sum(modexist)>0) || (input_vel==2 && isempty(VsItomo)==0)
            panel6=fullfile(dir_img_inv_2d,['VP_VS_Pois_Aux.',avertype,'.',modeltype,'.',imgform]);
            cat_img([filevp,' ',filevs,' ',filepois,' ',fileAUX],imgform,1,[],panel6,1);
            delete(panel3);
            panel7=fullfile(dir_img_inv_2d,['VP_VS_VPVS_Aux.',avertype,'.',modeltype,'.',imgform]);
            cat_img([filevp,' ',filevs,' ',filevpvs,' ',fileAUX],imgform,1,[],panel7,1);
            delete(panel4);
        elseif input_vel==2 && isempty(VpItomo)==0 && isempty(VsItomo)==1
            panel8=fullfile(dir_img_inv_2d,['Aux_VP.',avertype,'.',modeltype,'.',imgform]);
            cat_img([fileAUX,' ',filevp],imgform,1,[],panel8,1);
        elseif input_vel==2 && isempty(VpItomo)==0 && isempty(VsItomo)==0
            panel9=fullfile(dir_img_inv_2d,['Aux_VP_VS.',avertype,'.',modeltype,'.',imgform]);
            cat_img([fileAUX,' ',filevp,' ',filevs],imgform,1,[],panel9,1);
        end
        
    end
end

if testplot==1 && plot2dmod==1 && concat==1
    if exist('filevp','var')==1 && exist(filevp,'file')==2
        if input_vel==1 || (input_vel==2 && isempty(VsItomo)==0)
            delete(filevp);
        end
    end
    if exist('filevs','var')==1 && exist(filevs,'file')==2
        delete(filevs);
    end
    if exist('filevs2','var')==1 && exist(filevs2,'file')==2
        delete(filevs2);
    end
    if exist('filepois','var')==1 && exist(filepois,'file')==2
        delete(filepois);
    end
    if exist('filevpvs','var')==1 && exist(filevpvs,'file')==2
        delete(filevpvs);
    end
    if exist('filestd','var')==1 && exist(filestd,'file')==2
        delete(filestd);
    end
    if exist('fileAUX','var')==1 && exist(fileAUX,'file')==2
        delete(fileAUX);
    end
end

if savexzv==1 && input_vel==1
    save_xzv(fullfile(dir_xzv_inv_mod,['VS.',avertype,'.',modeltype,'.xzv']),XmidT,depth,vsmat.*maskmat);
    save_xzv(fullfile(dir_xzv_inv_mod,['VP.',avertype,'.',modeltype,'.xzv']),XmidT,depth,vpmat.*maskmat);
    save_xzv(fullfile(dir_xzv_inv_mod,['VPVS.',avertype,'.',modeltype,'.xzv']),XmidT,depth,vpvsmat.*maskmat);
    save_xzv(fullfile(dir_xzv_inv_mod,['Poisson.',avertype,'.',modeltype,'.xzv']),XmidT,depth,poismat.*maskmat);
    save_xzv(fullfile(dir_xzv_inv_mod,['VSstd.',avertype,'.',modeltype,'.xzv']),XmidT,depth,vsstdmat.*maskmat);
    if input_aux==1 && auxmask==1
        auxmat(isnan(auxmat)==1 & isnan(vpmat)==0)=min(auxmat(isnan(auxmat)==0));
        save_xzv(fullfile(dir_xzv_inv_mod,['Aux.',avertype,'.',modeltype,'.xzv']),XmidT,depth,auxmat.*maskmat);
    end
end
