function IO_YDS = mrio_direct_risk_calc(climada_mriot, aggregated_mriot, params) % uncomment to run as function
% mrio direct risk ralc
% MODULE:
%   advanced
% NAME:
%   mrio_direct_risk_calc
% PURPOSE:
%   given an encoded entity per economic sector (assets and damage functions) 
%   and a hazard event set, calculate the direct year damage set (IO_YDS.direct) 
%   that contains information on the direct risk for each subsector x country-combination 
%   and year as defined by the general climada mriot struct and hazard provided. 
%
%   NOTE: see PARAMETERS in code
%
%   previous call: 
%       [aggregated_mriot, climada_mriot] = mrio_aggregate_table;
%   next call:  % just to illustrate
%       IO_YDS = mrio_leontief_calc(IO_YDS, climada_mriot);
% CALLING SEQUENCE:
%   IO_YDS = mrio_direct_risk_calc(climada_mriot, aggregated_mriot, params);
% EXAMPLE:
%   climada_mriot = mrio_read_table;
%   aggregated_mriot = mrio_aggregate_table(climada_mriot);
%   IO_YDS = mrio_direct_risk_calc(climada_mriot, aggregated_mriot);
% INPUTS:
%   climada_mriot: a structure with ten fields. It represents a general climada
%       mriot structure whose basic properties are the same regardless of the
%       provided mriot it is based on, see mrio_read_table;
%   aggregated_mriot: an aggregated climada mriot struct as
%       produced by mrio_aggregate_table.
% OPTIONAL INPUT PARAMETERS:
%   params: a structure with the fields
%       mriot: a structure with the fields
%           filename: the filename (and path, optional) of a previously saved 
%               mrio table structure. If no path provided, default path ../data 
%               is used
%               > prompted for if empty
%           table_flag: flag to mark which table type. If not provided, 
%               > prompted for if empty
%       centroids_file: the filename (and path, optional) of a previously saved centroids
%           structure. If no path provided, default path ../data/centroids is used
%           > prompted for if empty
%       hazard_file: the filename (and path, optional) of a hazard
%           structure. If no path provided, default path ../data/hazard is used
%           > prompted for if empty
%       impact_analysis_mode: If set to =1, direct risk is only calculated for a 
%           subset of country x mainsector-combinations (prompted for), default 
%           is =0 where all country x mainsector-combinations are evaluated. 
%           During the further calculation (mrio_leontief_calc) indirect impact 
%           of that particular direct risk is estimated.              
%       verbose: whether we printf progress to stdout (=1, default) or not (=0)
% OUTPUTS:
%   IO_YDS, the Input-Output year damage set, a struct with the fields:
%       direct, a struct itself with the field
%           ED: the total expected annual damage
%           reference_year: the year the damages are references to
%           yyyy(i): the year i
%           damage(year_i): the damage amount for year_i (summed up over all
%               assets and events)
%           Value: the sum of all Values used in the calculation (to e.g.
%               express damages in percentage of total Value)
%           frequency(i): the annual frequency, =1
%           orig_year_flag(i): =1 if year i is an original year, =0 else
%       hazard: itself a structure, with:
%           filename: the filename of the hazard event set
%           comment: a free comment
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20180115, initial
% Ediz Herms, ediz.herms@outlook.com, 20180118, disaggregate direct risk to all subsectors for each country
% Ediz Herms, ediz.herms@outlook.com, 20180212, possibility to provide entity on subsector level
% Ediz Herms, ediz.herms@outlook.com, 20180416, impact_analysis_mode: option to only calculate direct risk for a subset of country x mainsector-combinations
% Kaspar Tobler, 20180418 change calculations to use the newly implemented total_production array which includes production for final demand.
% Kaspar Tobler, 20180525 add use of mrio_generate_damagefunctions to make calculation with the appropriate damage functions (details in mrio_generate_damagefunctions).
% Ediz Herms, ediz.herms@outlook.com, 20180617, Input-Output damage year set (IO_YDS) struct as output 
% Ediz Herms, ediz.herms@outlook.com, 20180620, add IO_YDS.hazard with peril_ID
%

IO_YDS = struct;

global climada_global
if ~climada_init_vars, return; end % init/import global variables

% poor man's version to check arguments
if ~exist('climada_mriot', 'var'), climada_mriot = []; end
if ~exist('aggregated_mriot', 'var'), aggregated_mriot = []; end
if ~exist('params','var'), params = struct; end
if ~exist('country_name','var'), country_name = []; end
if ~exist('mainsector_name','var'), mainsector_name = []; end
if ~exist('subsector_name','var'), subsector_name = []; end

% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)
if exist([climada_global.modules_dir filesep 'advanced' filesep 'data'],'dir') 
    module_data_dir = [climada_global.modules_dir filesep 'advanced' filesep 'data'];
else
    module_data_dir = [climada_global.modules_dir filesep 'climada_advanced' filesep 'data'];
end

% PARAMETERS
if isempty(climada_mriot), climada_mriot = mrio_read_table; end
if isempty(aggregated_mriot), aggregated_mriot = mrio_aggregate_table(climada_mriot); end
if ~isfield(params,'hazard_file') || isempty(params.hazard_file)
    if (exist(fullfile(climada_global.hazards_dir, 'GLB_0360as_TC_hist.mat'), 'file') == 2) 
        params.hazard_file = 'GLB_0360as_TC_hist.mat';
    else % prompt for hazard filename
        params.hazard_file = [climada_global.hazards_dir];
        [filename, pathname] = uigetfile(params.hazard_file, 'Select hazard file:');
        if isequal(filename,0) || isequal(pathname,0)
            return; % cancel
        else
            params.hazard_file = fullfile(pathname, filename);
        end
    end
end
if ~isfield(params,'impact_analysis_mode'), params.impact_analysis_mode = 0; end
if ~isfield(params,'verbose'), params.verbose = 1; end

mrio_countries_ISO3 = unique(climada_mriot.countries_iso, 'stable');
n_mrio_countries = length(mrio_countries_ISO3);

mainsectors = unique(climada_mriot.climada_sect_name, 'stable');
n_mainsectors = length(mainsectors);

subsectors = unique(climada_mriot.sectors, 'stable');
n_subsectors = climada_mriot.no_of_sectors; 

nwp_countries = {'JPN','VNM','MYS','PHL','CHN','KOR','TWN'};  % Which countries are considered part of the north-west Pacific (NWP)?
                                                              % Quite ugly hardcoded version for time reasons. Later maybe base on actual coordinates of country being part of nwp region (predefine only coordinate boundary of region) and use admin0 file or so...

if params.impact_analysis_mode
    % prompt country (one or many)
    [countries_liststr, countries_sort_index] = sort(mrio_countries_ISO3);
    if isempty(country_name)
        % compile list of all mrio countries, then call recursively below
        [selection_country] = listdlg('PromptString','Select countries (or one):',...
            'ListString',countries_liststr);
        selection_country = countries_sort_index(selection_country);
    else 
        selection_country = find(mrio_countries_ISO3 == country_name);
    end
    % prompt for subsector name (one or many)
    [mainsectors_liststr, mainsectors_sort_index] = sort(mainsectors);
    if isempty(mainsector_name)
        % compile list of all mrio countries, then call recursively below
        [selection_mainsector] = listdlg('PromptString','Select mainsectors (or one):',...
            'ListString',mainsectors_liststr);
        selection_mainsector = mainsectors_sort_index(selection_mainsector);
    else
        selection_mainsector = find(mainsectors == mainsector_name);
    end
    
%     if length(selection_mainsector) < 2
%         main_fields = fields(aggregated_mriot.aggregation_info);
%         current_mainsector = char(main_fields(selection_mainsector));
%         subset_subsectors = aggregated_mriot.aggregation_info.(current_mainsector);
%         [subsectors_liststr, subsectors_sort_index] = sort(subset_subsectors);
%         if isempty(subsector_name)
%             % compile list of all mrio countries, then call recursively below
%             [selection_subsector] = listdlg('PromptString','Select subsectors (or one):',...
%                 'ListString',subsectors_liststr);
%             selection_subsector = subsectors_sort_index(selection_subsector);
%         else
%             selection_subsector = find(subset_subsectors == subsector_name);
%         end
%     end
    
    selection_risk = zeros(length(selection_mainsector),length(selection_country));
    for country_i = 1:length(selection_country)
        selection_risk(:,country_i) = ones(1,length(selection_mainsector)).*(selection_country(country_i)-1)*n_mainsectors+selection_mainsector; % TO DO: only one selection possible atm
    end % country_i
    selection_risk = reshape(selection_risk,[1,size(selection_risk,1)*size(selection_risk,2)]);
    
    else 
    selection_risk = [];
end % params.impact_analysis_mode

% check whether user provided data on subsector level in entity directory
if params.verbose
    fprintf('Check whether user provided data on subsector level in entity directory...\n');
    fprintf('Entities on sub-sector level found: ');
end
subsector_information = zeros(1,n_subsectors*n_mrio_countries);
for subsector_j = 1:n_subsectors
    subsector_name = char(climada_mriot.sectors(subsector_j)); % extract subsector name
    mainsector_name = char(climada_mriot.climada_sect_name(subsector_j)); % extract mainsector name
    mainsector_j = find(mainsector_name == mainsectors);
    for mrio_country_i = 1:n_mrio_countries
        country_ISO3 = char(mrio_countries_ISO3(mrio_country_i)); % extract ISO code
        if ismember(mainsector_j+n_mainsectors*(mrio_country_i-1),selection_risk) && (exist(fullfile(climada_global.entities_dir, [country_ISO3 '_' mainsector_name '_' subsector_name '.mat']), 'file') == 2) 
            % if entity on subsector level exists (condition fullfilled) assign value = 1
            subsector_information(subsector_j+n_subsectors*(mrio_country_i-1)) = 1;
            
            info = [char(climada_mriot.countries_iso(subsector_j+n_subsectors*(mrio_country_i-1))) ' | ' char(climada_mriot.sectors(subsector_j+n_subsectors*(mrio_country_i-1)))];
            if params.verbose
                fprintf('\n');
                fprintf('%s',info); 
            end
        end
    end % mrio_country_i
end % subsector_j
subsector_information = find(subsector_information);

if isempty(subsector_information) && params.verbose
    fprintf('NONE \n')
end

% load hazard
hazard = climada_hazard_load(params.hazard_file);

n_years = length(hazard.orig_yearset); ens_size=(hazard.event_count/hazard.orig_event_count)-1; 

if params.verbose, climada_progress2stdout; end % init, see terminate below

% direct risk calculation per mainsector and per country
if params.verbose, fprintf('Direct risk calculation per mainsector x country-combination...\n'); end
risk_i = 0;
direct_mainsector_damage = zeros(n_years*(ens_size+1),n_mainsectors*n_mrio_countries);
for mainsector_j = 1:n_mainsectors % different exposure (asset) base as generated by mrio_generate_XXX_entity functions
    mainsector_name = char(mainsectors(mainsector_j));

    % load (global) mainsector entity
    mainsector_entity_file = ['GLB_' mainsector_name '_XXX.mat'];
    
    if (exist(fullfile(climada_global.entities_dir, mainsector_entity_file), 'file') == 2) 
        mainsector_entity = climada_entity_load(mainsector_entity_file);
    else
        mainsector_entity = climada_entity_load(fullfile([module_data_dir filesep 'entities'], mainsector_entity_file));
    end

    % calculation for all countries as specified in mrio table
    for mrio_country_i = 1:n_mrio_countries
        country_ISO3 = char(mrio_countries_ISO3(mrio_country_i)); % extract ISO code

        % load entity on country level
        if (exist(fullfile(climada_global.entities_dir, [country_ISO3 '_' mainsector_name '_XXX.mat']), 'file') == 2) 
            % select entity country level
            entity_file = [country_ISO3 '_' mainsector_name '_XXX.mat'];
        else
            % otherwise use global entity
            entity_file = mainsector_entity_file;
        end

        if ~strcmp(entity_file, mainsector_entity_file)
            entity = climada_entity_load(entity_file);
        else
            entity = mainsector_entity;
        end

        if isfield(entity.assets, 'ISO3_list')
            countries_ISO3 = entity.assets.ISO3_list(:,1);
        elseif isfield(entity.assets, 'NatID_RegID')
            countries_ISO3 = entity.assets.NatID_RegID.ISO3;
        else
            error('Please prepare entities first.')
        end

        if ~strcmp(country_ISO3,'ROW') && ~strcmp(country_ISO3,'RoW')
            country_NatID = find(ismember(countries_ISO3, country_ISO3)); % extract NatID
            sel_assets = eq(ismember(entity.assets.NatID, country_NatID),~isnan(entity.assets.Value)); % select all non-NaN assets of this country
        else % 'Rest of World' (RoW) is viewed as a country 
            list_RoW_ISO3 = setdiff(countries_ISO3, mrio_countries_ISO3); % find all countries that are not individually listed in the MRIO table 
            list_RoW_NatID = find(ismember(countries_ISO3, list_RoW_ISO3)); % extract NatID
            sel_assets = eq(ismember(entity.assets.NatID, list_RoW_NatID),~isnan(entity.assets.Value)); % select all non-NaN RoW assets
        end

        entity_sel = entity;
        entity_sel.assets.Value = entity.assets.Value .* sel_assets;  % set values = 0 for all assets outside country i.
        
        if ~(sum(entity_sel.assets.Value == 1))
            entity_sel.assets.Value = entity_sel.assets.Value/sum(entity_sel.assets.Value); % make sure normalized assets are used
        end

        % risk calculation (see subfunction)
        if ~isempty(entity_sel.assets.Value) & (isempty(selection_risk) | ismember(mainsector_j+n_mainsectors*(mrio_country_i-1),selection_risk))
            YDS_sel = risk_calc(entity, hazard, country_ISO3);
            direct_mainsector_damage(:,mainsector_j+n_mainsectors*(mrio_country_i-1)) = YDS_sel.damage;
        elseif isempty(entity_sel.assets.Value) | (~isempty(selection_risk) & ~ismember(mainsector_j+n_mainsectors*(mrio_country_i-1),selection_risk))
            direct_mainsector_damage(:,mainsector_j+n_mainsectors*(mrio_country_i-1)) = 0;
        end

        risk_i = risk_i + 1;
        if params.verbose, climada_progress2stdout(risk_i,n_mrio_countries*n_mainsectors,1,'risk calculations'); end % update

    end % mrio_country_i

end % mainsector_j

if params.verbose, climada_progress2stdout(0); end % terminate

% Disaggregate direct mainsector risk to direct risk for all subsector/country combinations
if params.verbose, fprintf('Disaggregate direct main sector risk to direct sub sector risk...\n'); end
direct_subsector_damage = zeros(n_years*(ens_size+1),n_subsectors*n_mrio_countries);     
for mainsector_i = 1:n_mainsectors  
    main_fields = fields(aggregated_mriot.aggregation_info);
    current_mainsector = char(main_fields(mainsector_i));
        for subsector_j = 1:numel(aggregated_mriot.aggregation_info.(current_mainsector)) % How many subsectors belong to current mainsector.
            temp_subsectors = aggregated_mriot.aggregation_info.(current_mainsector);
            current_subsector = char(temp_subsectors(subsector_j));           

            sel_subsector_pos = climada_mriot.sectors == current_subsector;

            direct_subsector_damage(:,sel_subsector_pos) = direct_mainsector_damage(:,aggregated_mriot.sectors == current_mainsector);

        end % subsector_j
end % mainsector_i

% direct risk calculation on subsector level
if ~isempty(subsector_information) && params.verbose
    fprintf('Direct risk calculation on subsector level...\n')
    climada_progress2stdout % init, see terminate below
end

for subsector_i = 1:length(subsector_information)
    sel_pos = subsector_information(subsector_i);
    
    subsector_name = char(climada_mriot.sectors(sel_pos));
    mainsector_name = char(climada_mriot.climada_sect_name(sel_pos));
    country_ISO3 = char(climada_mriot.countries_iso(sel_pos));
    
    % load subsector entity
    entity_file = [country_ISO3 '_' mainsector_name '_' subsector_name '.mat'];
    entity = climada_entity_load(entity_file);
    
    % risk calculation (see subfunction) + multiplication with each subsector's total production
    if ~isempty(entity.assets.Value)
        YDS_sel = risk_calc(entity, hazard, country_ISO3);
        direct_subsector_damage(:,sel_pos) = YDS_sel.damage;
    else
        direct_subsector_damage(:,sel_pos) = 0;
    end
   
    if params.verbose, climada_progress2stdout(subsector_i,length(subsector_information),1,'risk calculations'); end % update
    
end % subsector_i

if params.verbose, climada_progress2stdout(0); end % terminate

% Derive absolute damage by multiplying relative damage with total sectorial production
total_subsector_production = climada_mriot.total_production';
direct_subsector_damage = direct_subsector_damage .* total_subsector_production;

% setting up the (direct) year damage set
%------------------------------------------------
IO_YDS.direct.reference_year = YDS_sel.reference_year;

IO_YDS.direct.countries = climada_mriot.countries;
IO_YDS.direct.countries_iso = climada_mriot.countries_iso;
IO_YDS.direct.sectors = climada_mriot.sectors;
IO_YDS.direct.climada_sect_name = climada_mriot.climada_sect_name;
IO_YDS.direct.aggregation_info = aggregated_mriot.aggregation_info;

IO_YDS.direct.damage = direct_subsector_damage; % damage per country x sector-combination and year (matrix)
IO_YDS.direct.Value = total_subsector_production; % sectorial production as value
IO_YDS.direct.frequency = YDS_sel.frequency'; 

IO_YDS.direct.annotation_name = YDS_sel.annotation_name; 

IO_YDS.direct.ED = mean(direct_subsector_damage,1); % derive annual expected damage 
IO_YDS.direct.yyyy = YDS_sel.yyyy'; 
IO_YDS.direct.orig_year_flag = YDS_sel.orig_year_flag';  

% since a hazard event set might have been created on another Machine, make
% sure it can later be referenced (with filesep and hence fileparts):
hazard_peril_ID = char(hazard.peril_ID); % used below
IO_YDS.peril_ID = hazard_peril_ID;
IO_YDS.hazard.peril_ID = IO_YDS.peril_ID; % backward compatibility
if ~isfield(hazard,'filename'), hazard.filename = ''; end
IO_YDS.hazard.filename = strrep(char(hazard.filename),'\',filesep); % from PC
IO_YDS.hazard.filename = strrep(IO_YDS.hazard.filename,'/',filesep); % from MAC
if ~isfield(hazard,'refence_year'), hazard.refence_year = climada_global.present_reference_year; end
IO_YDS.hazard.refence_year = hazard.refence_year;
if ~isfield(hazard, 'scenario'), hazard.scenario = 'no climate change'; end
IO_YDS.hazard.scenario = hazard.scenario;
if ~isfield(hazard,'comment'), hazard.comment = ''; end
IO_YDS.hazard.comment = hazard.comment;

%% Risk calculation function 
function YDS = risk_calc(entity, hazard, country_ISO3)
    % Calculate damagefunctions based on Emanuel (see function for
    % details); need to check whether current country is in north-west
    % Pacific or not (differing dfs):
    if ismember(country_ISO3,nwp_countries)
        entity.damagefunctions = mrio_generate_damagefunctions(entity.damagefunctions,25,61,0.08);
    else
        entity.damagefunctions = mrio_generate_damagefunctions(entity.damagefunctions,25,61,0.64);
    end    
    
    % calculate event damage set
    EDS = climada_EDS_calc(entity, hazard, '', '', 2, '');

    % convert an event (per occurrence) damage set (EDS) into a year damage set (YDS)
    YDS = climada_EDS2YDS(EDS, hazard, '', '', 1); % silent_mode (=1)
    
end % risk_calc
   
end % mrio_direct_risk_calc