%function [EDS_hist,EDS]=florida_wiggle_test(construction_period_end)
% climada florida_wiggle_test
% MODULE:
%   _LOCAL
% NAME:
%   florida_wiggle_test
% PURPOSE:
%   batch job to TEST wiggling hazard parameters for one centroid in Florida
%
%   later maybe a function
%
%   see PARAMETERS
%
%   for speedup, consider climada_global.parfor=1
%
% CALLING SEQUENCE:
%   [EDS_hist,EDS]=florida_wiggle_test(construction_period_end)
% EXAMPLE:
%   florida_wiggle_test
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   to stdout and figures
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20180622, initial
% David N. Bresch, david.bresch@gmail.com, 20180910, rcps added
% David N. Bresch, david.bresch@gmail.com, 20180913, construction_period added
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% PARAMETERS
%
% market share of insurer (to get useful order of magnitude)
market_share=0.05; % market share in decimal, i.e. 5% as 0.05
% 
% last year to use to construct the probabilistic set(s)
construction_period_end=1980;
%
method='perturbed physics'; % wiggle some parameters to generate the hazard set
%method='rcps'; % use different rcps
%
% define the centroid(s)
% if you define here, we create a dummy entity with these (few) points,
% otherwise see entity load below
%centroids.lon = -80.1918;centroids.lat =  25.7617; % Miami, Florida, USA

EDS=[]; % (re)init

% % TESTs for whole US - just for illustration
% em_data=emdat_read('','USA','TC',1,1);
% entity=climada_entity_load('USA_UnitedStates_entity.mat');
% %climada_entity_plot(entity)

% create the asset base
% ---------------------

if ~exist('centroids','var')
    
    % create Florida, 10x10km, scaled to GDP and income_group, then times market_share
    entity_file=[climada_global.entities_dir filesep 'USA_UnitedStates_Florida_10x10.mat'];
    if exist(entity_file,'file')
        fprintf('loading entity ...');
        entity=climada_entity_load(entity_file);
    else
        parameters.resolution_km=10;
        entity=climada_nightlight_entity('USA','Florida',parameters);
        entity.assets.filename='/Users/bresch/Documents/_GIT/climada_data/entities/USA_UnitedStates_Florida_10x10.mat';
        entity.assets.Value=entity.assets.Value/sum(entity.assets.Value)*926e9*5;
        entity.assets.Cover=entity.assets.Value; % to cover 100%
        entity.assets.Value_comment='GDP USD 926 bn (2016) from https://en.wikipedia.org/wiki/Florida, factor 5 is WolrdBank income_group plus one';
        save(entity.assets.filename,'entity',climada_global.save_file_version);
        climada_entity_plot(entity);
    end
    entity.assets.Value=entity.assets.Value*market_share;
    entity.assets.Cover=entity.assets.Value;
    fprintf(' done\n');

else
    
    % set up the entity based on centroids
    fprintf('preparing entity ...');
    centroids.centroid_ID=1:length(centroids.lon); % define IDs
    entity=climada_entity_read('entity_template.xlsx','NOENCODE');
    if isfield(entity.assets,'hazard'),entity.assets=rmfield(entity.assets,'hazard');end
    if isfield(entity.assets,'centroid_index'),entity.assets=rmfield(entity.assets,'centroid_index');end
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
    
end

% load tropical cyclone (TC) tracks
% ---------------------------------

fprintf('loading TC tracks ...');
% load historical TC-tracks
%tc_track=climada_tc_read_unisys_database('atl'); % read historic TC tracks
tc_track=climada_tc_track_load([climada_global.data_dir filesep 'tc_tracks' filesep 'ibtracs' filesep 'ibtracs.mat']);
if isempty(tc_track),tc_track=isimip_ibtracs_read('all','',1,1);end % load from single files
fprintf(' done\n');

% generate historic hazard event set (all years)
fprintf('calculating historic hazard set:\n');
hazard_hist=climada_tc_hazard_set(tc_track,'NOSAVE',entity);
entity.assets.centroids_index=1:length(entity.assets.lon);
entity.assets.hazard.filename=hazard_hist.filename;
entity.assets.hazard.comment='local, hatrd-wired';
EDS_hist=climada_EDS_calc(entity,hazard_hist,'hist');
        
% figure;plot(hazard.yyyy,EDS.damage,'.r');
% figure;climada_damagefunctions_plot(entity,'TC 001')
% IFC=climada_hazard2IFC(hazard,1);
% figure;climada_IFC_plot(IFC)

% YDS=climada_EDS2YDS(EDS);
% % fix orig_yearset()
% figure;plot(hazard.orig_yearset.yyyy,YDS.damage,'.r');

% keep only historic tracks up to a certain year
for track_i=1:length(tc_track)
    if tc_track(track_i).yyyy(end)<=construction_period_end
        construction_period_end_track_i=track_i;
    end
end % track_i
total_years=tc_track(end).yyyy(end)-tc_track(1).yyyy(1)+1;
construction_years=tc_track(construction_period_end_track_i).yyyy(end)-tc_track(1).yyyy(1)+1;
after_construction_years=tc_track(end).yyyy(end)-tc_track(construction_period_end_track_i).yyyy(1);
tc_track=tc_track(1:construction_period_end_track_i);

switch method
    case 'perturbed physics'
        fprintf('calculating perturbed physics (9 combinations):\n');
        
        % generate historic hazard event set
        hazard_hist=climada_tc_hazard_set(tc_track,'NOSAVE',entity);
        
        % calculate historic damages (the kind of 'reference')
        EDS=climada_EDS_calc(entity,hazard_hist,'hist');
        
        % start wiggling
        ens_size =     9; % create ens_size varied derived tracks, default 9
        for random_walk_i=1:3
            ens_amp  =   1.5*random_walk_i; % amplitude of max random starting point shift degree longitude
            Maxangle = pi/10/random_walk_i; % maximum angle of variation, =pi is like undirected, pi/4 means one quadrant
            tc_track_prob=climada_tc_random_walk(tc_track,ens_size,ens_amp,Maxangle);
            hazard_prob=climada_tc_hazard_set(tc_track_prob,'NOSAVE',entity);
            EDS(end+1)=climada_EDS_calc(entity,hazard_prob,sprintf('prob walk %i',random_walk_i));
            
            for windfield_i=1:2
                if windfield_i==1,R_min=15;end
                if windfield_i==2,R_min=45;end
                hazard_prob=climada_tc_hazard_set(tc_track_prob,'NOSAVE',entity,1,R_min);
                EDS(end+1)=climada_EDS_calc(entity,hazard_prob,sprintf('prob walk %i wind %i',random_walk_i,windfield_i));
            end
        end
        
        climada_EDS_DFC(EDS,[],1,0,'hist');xlim([0 1000])
        %title('single point (Miami) tropical cyclone risk');
        
    case 'rcps'
        
        fprintf('calculating RCPs:\n');
        
        tc_track_prob=climada_tc_random_walk(tc_track);
        
        % generate historic hazard event set
        hazard_prob=climada_tc_hazard_set(tc_track_prob,'NOSAVE',centroids);
        
        % calculate historic damages (the kind of 'reference')
        EDS=climada_EDS_calc(entity,hazard_prob,'today');
        
        rcp_list=[26 45 60 85];
        reference_year=2050;
        for rcp_i=1:length(rcp_list)
            hazard_rcp = climada_tc_hazard_clim_scen_Knutson2015(hazard_prob,tc_track_prob,rcp_list(rcp_i),reference_year,0,'NOSAVE'); % 2-degree, 2015
            EDS(end+1)=climada_EDS_calc(entity,hazard_rcp,sprintf('rcp%2.2i %4.4i',rcp_list(rcp_i),reference_year));
        end % rcp_i
        
        climada_EDS_DFC(EDS,[],1,0,'today');xlim([0 100])
        
        title('single point (Miami) tropical cyclone risk');
        
end % switch method

% expected damge over whole period
%hist_damage_full_period=EDS_hist.ED;
hist_damage_full_period=sum(EDS_hist.damage)/total_years;
% expected damage over construction period
hist_damage_construction_period=sum(EDS_hist.damage(1:construction_period_end_track_i))/construction_years;
if hist_damage_construction_period<eps,hist_damage_construction_period=eps;end
% expected damage over period after construction until end of the dataset
hist_damage_after_construction_period=sum(EDS_hist.damage(construction_period_end_track_i+1:end))/after_construction_years;

fprintf('expected damage\n');
fprintf('construction period \t full period \t difference %%\n');
fprintf('historical: %g \t %g \t %g\n',hist_damage_construction_period,hist_damage_full_period,(hist_damage_full_period/hist_damage_construction_period-1)*100);

for EDS_i=2:length(EDS) % EDS(1) is historic, but only for construction_period, we have that above
    if EDS(EDS_i).ED<eps,EDS(EDS_i).ED=eps;end
    fprintf('%s: %g \t %g \t %g\n',EDS(EDS_i).annotation_name,EDS(EDS_i).ED,hist_damage_full_period,(hist_damage_full_period/EDS(EDS_i).ED-1)*100);
end % EDS_i
