%function florida_wiggle_test
% climada florida_wiggle_test
% MODULE:
%   _LOCAL
% NAME:
%   florida_wiggle_test
% PURPOSE:
%   batch job to TEST wiggling hazard parameters for one centroid in Florida
%
%   for speedup, consider climada_global.parfor=1
%
% CALLING SEQUENCE:
%   florida_wiggle_test
% EXAMPLE:
%   florida_wiggle_test
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   to stdout and figures
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20180622, initial
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% PARAMETERS
%
% define the centroid(s)
centroids.lon = -80.1918;centroids.lat =  25.7617; % Miami, Florida, USA


EDS=[]; % (re)init

% % TESTs for whole US - just for illustration
% em_data=emdat_read('','USA','TC',1,1);
% entity=climada_entity_load('USA_UnitedStates_entity.mat');
% %climada_entity_plot(entity)
%
% hazard_hist=climada_hazard_load('USA_UnitedStates_atl_TC_hist');
% hazard_prob=climada_hazard_load('USA_UnitedStates_atl_TC');
%
% EDS(1)=climada_EDS_calc(entity,hazard_hist,'hist');
% EDS(2)=climada_EDS_calc(entity,hazard_prob,'prob');
% figure;[~,~,legend_str,legend_handle]=climada_EDS_DFC(EDS);
% [legend_str,legend_handle]=emdat_barplot(em_data,'','','EM-DAT',legend_str,legend_handle);
%
% figure;plot(hazard_hist.yyyy,EDS(1).damage)
% hold on;
% plot(em_data.year,em_data.damage,'.r')
% return


% set up the entity based on centroids
fprintf('preparing entity ...');
centroids.centroid_ID=1:length(centroids.lon); % define IDs
entity=climada_entity_read('entity_template.xlsx','NOENCODE');
entity.assets=rmfield(entity.assets,'hazard');
entity.assets=rmfield(entity.assets,'centroid_index');
entity.assets=rmfield(entity.assets,'Category_ID');
entity.assets=rmfield(entity.assets,'Region_ID');
entity.assets=rmfield(entity.assets,'Value_unit');
entity.assets.lon=centroids.lon;
entity.assets.lat=centroids.lat;
entity.assets.Value=1;
entity.assets.Value_unit=repmat({'dummy'},size(entity.assets.Value));
entity.assets.Cover=1;
entity.assets.Deductible=0;
entity.assets.DamageFunID=1;
entity.assets.centroid_index=centroids.centroid_ID; % hard-wired
fprintf(' done\n');

fprintf('loading TC tracks, calculating hazard set and damages:\n');

% load historical TC-tracks
tc_track=climada_tc_read_unisys_database('atl'); % read historic TC tracks

% generate historic hazard event set
hazard_hist=climada_tc_hazard_set(tc_track,'NOSAVE',centroids);

% calculate historic damages (the kind of 'reference')
EDS=climada_EDS_calc(entity,hazard_hist,'hist');

% figure;plot(hazard.yyyy,EDS.damage,'.r');
% figure;climada_damagefunctions_plot(entity,'TC 001')
% IFC=climada_hazard2IFC(hazard,1);
% figure;climada_IFC_plot(IFC)

% YDS=climada_EDS2YDS(EDS);
% % fix orig_yearset()
% figure;plot(hazard.orig_yearset.yyyy,YDS.damage,'.r');

fprintf('calculating perturbed physics (9 combinations):\n');

% start wiggling
ens_size =     9; % create ens_size varied derived tracks, default 9
for random_walk_i=1:3
    ens_amp  =   1.5*random_walk_i; % amplitude of max random starting point shift degree longitude
    Maxangle = pi/10/random_walk_i; % maximum angle of variation, =pi is like undirected, pi/4 means one quadrant
    tc_track_prob=climada_tc_random_walk(tc_track,ens_size,ens_amp,Maxangle);
    hazard_prob=climada_tc_hazard_set(tc_track_prob,'NOSAVE',centroids);
    EDS(end+1)=climada_EDS_calc(entity,hazard_prob,sprintf('prob walk %i',random_walk_i));
    
    for windfield_i=1:2
        if windfield_i==1,R_min=15;end
        if windfield_i==2,R_min=45;end
        hazard_prob=climada_tc_hazard_set(tc_track_prob,'NOSAVE',centroids,1,R_min);
        EDS(end+1)=climada_EDS_calc(entity,hazard_prob,sprintf('prob walk %i wind %i',random_walk_i,windfield_i));
    end
end

climada_EDS_DFC(EDS,[],1,0,'hist');xlim([0 1000])
title('single point (Miami) tropical cyclone risk');
