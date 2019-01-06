%function [EDS_hist,EDS]=climada_lse_test
% climada climada_lse_test
% MODULE:
%   _LOCAL
% NAME:
%   climada_lse_test
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
%   [EDS_hist,EDS]=climada_lse_test
% EXAMPLE:
%   climada_lse_test
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   to stdout and figures
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20180622, initial
% David N. Bresch, david.bresch@gmail.com, 20180910, rcps added
% David N. Bresch, david.bresch@gmail.com, 20180913, construction_period added
% David N. Bresch, david.bresch@gmail.com, 20181118, 4 random walks, 3 windfield variants (16 comb), construction period dynamic
% David N. Bresch, david.bresch@gmail.com, 20181120, write ED and EP into .csv
% David N. Bresch, david.bresch@gmail.com, 20181122, renamed from florida_wiggle_test to climada_lse_test
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% PARAMETERS
%
% market share of insurer (to get useful order of magnitude)
market_share=0.05; % market share in decimal, i.e. 5% as 0.05
%
reference_return_periods=[10 20 30 40 50 60 70 80 90 100];
%
% last years to use to construct the probabilistic set(s)
construction_period_ends=1980:5:2015; % usually 1980:5:2015 or a selection, e.g. [1980 1985 1995]
% note that the verification is always to the next construction period,
% i.e. for construction 1950...1980, verification is for 1950...1985
%
method='perturbed physics'; % wiggle some parameters to generate the hazard set
%method='rcps'; % use different rcps CURRENTLY OFF
%
ens_size =     1; % create ens_size varied derived tracks, default 9
%
% define the centroid(s)
% if you define here, we create a dummy entity with these (few) points,
% otherwise see entity load below
%centroids.lon = -80.1918;centroids.lat =  25.7617; % Miami, Florida, USA
%
% local folder to write the figures
fig_dir = [climada_global.results_dir filesep 'CLIMADA_LSE'];
if ~isdir(fig_dir),[fP,fN]=fileparts(fig_dir);mkdir(fP,fN);end % create it
fig_ext ='png';

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
        entity.assets.filename=[climada_global.entities_dir filesep 'USA_UnitedStates_Florida_10x10.mat'];
        entity.assets.Value=entity.assets.Value/sum(entity.assets.Value)*926e9*5;
        entity.assets.Cover=entity.assets.Value; % to cover 100%
        entity.assets.Value_comment='GDP USD 926 bn (2016) from https://en.wikipedia.org/wiki/Florida, factor 5 is WorldBank income_group plus one';
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
entity.assets.hazard.comment='local, hard-wired';
EDS_hist=climada_EDS_calc(entity,hazard_hist,'hist');

% establish decay characteristics
[~,p_rel] = climada_tc_track_wind_decay_calculate(tc_track,0);p_rel=real(p_rel); % fixes a strange issue

% figure;plot(hazard.yyyy,EDS.damage,'.r');
% figure;climada_damagefunctions_plot(entity,'TC 001')
% IFC=climada_hazard2IFC(hazard,1);
% figure;climada_IFC_plot(IFC)

% YDS=climada_EDS2YDS(EDS);
% % fix orig_yearset()
% figure;plot(hazard.orig_yearset.yyyy,YDS.damage,'.r');

% % keep only historic tracks up to a certain year
% for track_i=1:length(tc_track)
%     if tc_track(track_i).yyyy(end)<=construction_period_end
%         construction_period_end_track_i=track_i;
%     end
% end % track_i
% total_years=tc_track(end).yyyy(end)-tc_track(1).yyyy(1)+1;
% construction_years=tc_track(construction_period_end_track_i).yyyy(end)-tc_track(1).yyyy(1)+1;
% after_construction_years=tc_track(end).yyyy(end)-tc_track(construction_period_end_track_i).yyyy(1);
% tc_track=tc_track(1:construction_period_end_track_i);

switch method
    case 'perturbed physics'
        fprintf('calculating perturbed physics (16 combinations):\n');
        
        EDS=EDS_hist; % just a copy of historic, for handling
        
        % start wiggling
        for random_walk_i=1:4
            ens_amp  =   0.1+0.1*random_walk_i; % amplitude of max random starting point shift degree longitude
            Maxangle =     pi/10*random_walk_i; % maximum angle of variation, =pi is like undirected, pi/4 means one quadrant
            tc_track_prob = climada_tc_random_walk(tc_track,ens_size,ens_amp,Maxangle);
    
            % add the inland decay correction to all probabilistic nodes
            tc_track_prob = climada_tc_track_wind_decay(tc_track_prob, p_rel,0);
                    
%             climada_tc_track_info(tc_track_prob);
%             info_str=sprintf('ens amp %2.2f, max angle=%2.3f',ens_amp,Maxangle);title(info_str);axis tight,xlim([-180,180]),ylim([-90,90])
%             saveas(gcf,[fig_dir filesep sprintf('CLIMADA_LSE_random_walk_%1.1i',random_walk_i)],fig_ext);
%             close all % get rid of figures
            
            hazard_prob=climada_tc_hazard_set(tc_track_prob,'NOSAVE',entity);
            EDS(end+1)=climada_EDS_calc(entity,hazard_prob,sprintf('prob walk %i',random_walk_i));
            
            for windfield_i=1:3 % [10] 20 (30) 40 50, 30 is default (used above)
                % we had 10 20 (30) 40 then 20 (30) 40 50
                if windfield_i==1,R_min= 5;end
                if windfield_i==2,R_min=10;end
                if windfield_i==3,R_min=20;end
                hazard_prob=climada_tc_hazard_set(tc_track_prob,'NOSAVE',entity,1,R_min);
                EDS(end+1)=climada_EDS_calc(entity,hazard_prob,sprintf('prob walk %i wind %i',random_walk_i,windfield_i));
            end
        end
                
    case 'rcps'
        
        fprintf('calculating RCPs:\n');
        
        EDS=EDS_hist; % just a copy of historic, for handling
        
        % generate historic probabilistic hazard event set
        tc_track_prob=climada_tc_random_walk(tc_track);
        hazard_prob=climada_tc_hazard_set(tc_track_prob,'NOSAVE',centroids);
        
        % calculate historic damages (the kind of 'reference')
        EDS(end+1)=climada_EDS_calc(entity,hazard_prob,'today');
        
        rcp_list=[26 45 60 85];
        reference_year=2050;
        for rcp_i=1:length(rcp_list)
            hazard_rcp = climada_tc_hazard_clim_scen_Knutson2015(hazard_prob,tc_track_prob,rcp_list(rcp_i),reference_year,0,'NOSAVE'); % 2-degree, 2015
            EDS(end+1)=climada_EDS_calc(entity,hazard_rcp,sprintf('rcp%2.2i %4.4i',rcp_list(rcp_i),reference_year));
        end % rcp_i
        
        DFC=climada_EDS2DFC(EDS,reference_return_periods); % in USD amounts
        climada_EDS_DFC(EDS,[],0,0,'today');xlim([0 100]) % in USD amounts
        saveas(gcf,[fig_dir filesep 'CLIMADA_LSE_EP_full_period'],fig_ext);
        
end % switch method

% expected damge over whole period
%hist_damage_full_period=EDS_hist.ED; % just explicit in next line (same result)
total_years=tc_track(end).yyyy(end)-tc_track(1).yyyy(1)+1;
hist_damage_full_period=sum(EDS_hist.damage)/total_years;

% set all orig event damages in probabilistic set to zero
%orig_pos=find(hazard_prob.orig_event_flag);
% for EDS_i=2:length(EDS)
%     EDS(EDS_i).damage(orig_pos)=0; % set original event damages to zero
%     % adjust frequency (now ens_size instead of ens_size+1, since original
%     % events taken out or well, set to zero)
%     EDS(EDS_i).frequency=EDS(EDS_i).frequency*0+1/(hazard_prob.orig_years*ens_size); 
%     EDS(EDS_i).frequency(orig_pos)=0; % to be sure
% end

% keep only the probabilistic events for probabilistic sets
prob_pos=find(hazard_prob.orig_event_flag==0);
for EDS_i=2:length(EDS)
    EDS(EDS_i).damage          = EDS(EDS_i).damage(prob_pos); % set original event damages to zero
    EDS(EDS_i).event_ID        = EDS(EDS_i).event_ID(prob_pos); % set original event damages to zero
    EDS(EDS_i).orig_event_flag = EDS(EDS_i).damage*0; % set original event damages to zero
    EDS(EDS_i).frequency       = EDS(EDS_i).damage*0+1/(total_years*ens_size); 
    EDS(EDS_i).ED_at_centroid  = EDS(EDS_i).ED_at_centroid+NaN; % not valid any more
    EDS(EDS_i).ED              = EDS(EDS_i).damage*EDS(EDS_i).frequency';
end
EDS(1).frequency=EDS(1).damage*0+1/total_years;
EDS(1).ED=EDS(1).damage*EDS(1).frequency';

DFC=climada_EDS2DFC(EDS,reference_return_periods); % in USD amounts
climada_EDS_DFC(EDS,[],0,0,'hist');xlim([0,100]) % in USD amounts
saveas(gcf,[fig_dir filesep 'CLIMADA_LSE_EP_full_period'],fig_ext);

% write results
% -------------

for construction_period_i=1:length(construction_period_ends)-1
    
    construction_period_end=construction_period_ends(construction_period_i);
    verification_period_end=construction_period_ends(construction_period_i+1);
    
    csv_ED_table=[fig_dir filesep 'CLIMADA_LSE_cp_' sprintf('%4.4i',construction_period_end) '_ED.csv'];
    csv_EP_table=[fig_dir filesep 'CLIMADA_LSE_cp_' sprintf('%4.4i',construction_period_end) '_EP.csv'];
    
    % figure the index in the historic (track) set
    for track_i=1:length(tc_track)
        if tc_track(track_i).yyyy(end)<=construction_period_end
            construction_period_end_track_i=track_i;
        end
        if tc_track(track_i).yyyy(end)<=verification_period_end
            verification_period_end_track_i=track_i;
        end
    end % track_i
    total_years=tc_track(end).yyyy(end)-tc_track(1).yyyy(1)+1;
    construction_years=tc_track(construction_period_end_track_i).yyyy(end)-tc_track(1).yyyy(1)+1;
    verification_years=tc_track(verification_period_end_track_i).yyyy(end)-tc_track(1).yyyy(1)+1;
    %after_construction_years=tc_track(end).yyyy(end)-tc_track(construction_period_end_track_i).yyyy(1);
    
    % convert from index in historic set to the probabilistic event
    %cpe_i=construction_period_end_track_i*(ens_size+1);
    cpe_i=construction_period_end_track_i*(ens_size);
    
    % historic expected damage over construction period
    % -------------------------------------------------
    EDS_hist_cp=EDS_hist; % copy full historic
    EDS_hist_cp.damage    = EDS_hist_cp.damage(1:construction_period_end_track_i);
    EDS_hist_cp.frequency =(EDS_hist_cp.frequency(1:construction_period_end_track_i)*0+1)/construction_years;
    EDS_hist_cp.ED        = EDS_hist_cp.damage*EDS_hist_cp(1).frequency';
    if EDS_hist_cp.ED<eps,EDS_hist_cp.ED=eps;end % avoid division by zero
    hist_damage_construction_period=sum(EDS_hist.damage(1:construction_period_end_track_i))/construction_years;
    if hist_damage_construction_period<eps,hist_damage_construction_period=eps;end
    % expected damage over period after construction until end of the dataset
    %hist_damage_after_construction_period=sum(EDS_hist.damage(construction_period_end_track_i+1:end))/after_construction_years;
    
    % historic expected damage over verification period
    % -------------------------------------------------
    EDS_veri_cp=EDS_hist; % copy full historic
    EDS_veri_cp.damage    = EDS_veri_cp.damage(1:verification_period_end_track_i);
    EDS_veri_cp.frequency =(EDS_veri_cp.frequency(1:verification_period_end_track_i)*0+1)/verification_years;
    EDS_veri_cp.ED        = EDS_veri_cp.damage*EDS_veri_cp(1).frequency';
    if EDS_veri_cp.ED<eps,EDS_veri_cp.ED=eps;end % avoid division by zero
    hist_damage_verification_period=sum(EDS_veri_cp.damage(1:verification_period_end_track_i))/verification_years;
    if hist_damage_verification_period<eps,hist_damage_verification_period=eps;end
    
    % trim the EDS to construction period
    % -----------------------------------
    EDS_cp=EDS; % copy full probabilistic
    EDS_cp(1)=EDS_hist_cp; % first is historic
    for EDS_i=2:length(EDS_cp)
        EDS_cp(EDS_i).damage    = EDS_cp(EDS_i).damage(1:cpe_i);
        EDS_cp(EDS_i).frequency = EDS_cp(EDS_i).frequency(1:cpe_i)*0+1/ens_size/construction_years; % only ens_size, since no historic any more
        %EDS_cp(EDS_i).frequency =(EDS_cp(EDS_i).frequency(1:cpe_i)*0+1)/(ens_size+1)/construction_years;
        EDS_cp(EDS_i).ED        = EDS_cp(EDS_i).damage*EDS_cp(EDS_i).frequency';
        if EDS_cp(EDS_i).ED<eps,EDS_cp(EDS_i).ED=eps;end % avoid division by zero
        EDS_cp(EDS_i).event_ID  = EDS_cp(EDS_i).event_ID(1:cpe_i);
        EDS_cp(EDS_i).orig_event_flag = EDS_cp(EDS_i).orig_event_flag(1:cpe_i);
        EDS_cp(EDS_i).ED_at_centroid = EDS_cp(EDS_i).ED_at_centroid+NaN; % not valid any more
    end % EDS_i
    
    % first write the expected damage (ED) to stdout and a .csv file
    % --------------------------------------------------------------
    csv_fid=fopen(csv_ED_table,'w');
    
    csv_format='%s,%g,%g,%g\n';
    csv_header=sprintf('ensemble member,construction period %4.4i to %4.4i,verification period,difference',tc_track(1).yyyy(1),tc_track(construction_period_end_track_i).yyyy(end));
    csv_format=strrep(csv_format,',',climada_global.csv_delimiter);
    csv_header=strrep(csv_header,',',climada_global.csv_delimiter);
    
    fprintf('expected damage (construction period %4.4i..%4.4i\n',tc_track(1).yyyy(1),tc_track(construction_period_end_track_i).yyyy(end));
    fprintf('construction period \t verification period \t difference %%\n');
    fprintf(csv_fid,'%s\n',csv_header);
    
    fprintf('%s: %g \t %g \t %g\n','historical',hist_damage_construction_period,hist_damage_verification_period,(hist_damage_construction_period/hist_damage_verification_period-1)*100);
    fprintf(csv_fid,csv_format,    'historical',hist_damage_construction_period,hist_damage_verification_period,(hist_damage_construction_period/hist_damage_construction_period-1));
    
    for EDS_i=2:length(EDS_cp) % EDS(1) is historic, but only for construction_period, we have that above
        %ED=sum(EDS_cp(EDS_i).damage(1:cpe_i))/ens_size/construction_years; % damage during construction period
        fprintf('%s: %g \t %g \t %g\n',EDS_cp(EDS_i).annotation_name,EDS_cp(EDS_i).ED,hist_damage_verification_period,(EDS_cp(EDS_i).ED/hist_damage_verification_period-1)*100);
        fprintf(csv_fid,csv_format,    EDS_cp(EDS_i).annotation_name,EDS_cp(EDS_i).ED,hist_damage_verification_period,(EDS_cp(EDS_i).ED/hist_damage_verification_period-1));
    end % EDS_i
    fclose(csv_fid);
    fprintf('\n > ED written to %s\n',csv_ED_table)
    
    % second write the damage exceedance frequency (DFC) to stdout and a .csv file
    % ----------------------------------------------------------------------------

    DFC=climada_EDS2DFC(EDS_cp,reference_return_periods); % in USD amounts
    
    csv_header=sprintf('ensemble member,%i',reference_return_periods(1));
    csv_format='%s,%g';
    
    for rp_i=2:length(reference_return_periods)
        csv_header=[csv_header sprintf(',%i',reference_return_periods(rp_i))];
        csv_format=[csv_format ',%g'];
    end % i
    csv_format=[csv_format '\n'];
    csv_header=strrep(csv_header,',',climada_global.csv_delimiter);
    csv_format=strrep(csv_format,',',climada_global.csv_delimiter);
    
    csv_fid=fopen(csv_EP_table,'w');
    fprintf('%s\n',csv_header);
    fprintf(csv_fid,'%s\n',csv_header);
    
    for DFC_i=1:length(DFC) % EDS(1) is historic, but only for construction_period, we have that above
        fprintf(        csv_format,EDS_cp(DFC_i).annotation_name,DFC(DFC_i).damage);
        fprintf(csv_fid,csv_format,EDS_cp(DFC_i).annotation_name,DFC(DFC_i).damage);
    end % DFC_i
    fclose(csv_fid);
    fprintf('\n > EP written to %s\n',csv_EP_table)
    
end % construction_period_i
