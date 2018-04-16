function [direct_subsector_risk, direct_country_risk] = mrio_direct_risk_calc(climada_mriot, aggregated_mriot, risk_measure, params) % uncomment to run as function
% mrio direct risk ralc
% MODULE:
%   advanced
% NAME:
%   mrio_direct_risk_calc
% PURPOSE:
%   Caculate direct risk per subsector and country given an encoded entity per economic sector (assets and damage functions), 
%   a hazard event set, a risk measure and a general climada MRIO table (as well as an aggregated climada mriot struct).
%
%   NOTE: see PARAMETERS in code
%
%   previous call: 
%
%   next call:  % just to illustrate
%   [total_subsector_risk, total_country_risk] = mrio_leontief_calc(direct_subsector_risk, climada_mriot);
% CALLING SEQUENCE:
%   [direct_subsector_risk, direct_country_risk] = mrio_direct_risk_calc(climada_mriot, aggregated_mriot, risk_measure, params);
% EXAMPLE:
%   climada_mriot = mrio_read_table;
%   aggregated_mriot = mrio_aggregate_table(climada_mriot);
%   [direct_subsector_risk, direct_country_risk] = mrio_direct_risk_calc(climada_mriot, aggregated_mriot);
% INPUTS:
%   climada_mriot: a structure with ten fields. It represents a general climada
%       mriot structure whose basic properties are the same regardless of the
%       provided mriot it is based on, see mrio_read_table;
%   aggregated_mriot: an aggregated climada mriot struct as
%       produced by mrio_aggregate_table.
% OPTIONAL INPUT PARAMETERS:
%   risk_measure: risk measure to be applied (string), default is the Expected Annual Damage (EAD)
 %   params: a structure with the fields
%       mriot: a structure with the fields
%           filename: the filename (and path, optional) of a previously
%               saved mrio table structure. If no path provided, default path ../data is used
%               > promted for if empty
%           table_flag: flag to mark which table type. If not provided, prompted for via GUI.
%       centroids_file: the filename (and path, optional) of a previously saved centroids
%           structure. If no path provided, default path ../data/centroids is used
%           > promted for if empty
%       hazard_file: the filename (and path, optional) of a hazard
%           structure. If no path provided, default path ../data/hazard is used
%           > promted for if empty
%       impact_analysis_mode: If set to =1, direct risk is only calculated for a 
%           subset of country x mainsector-combinations (prompted for). During the 
%           further calculation (mrio_leontief_calc) indirect impact of that particular
%           direct risk is estimated, default is =0 (all country x mainsector-combinations
%           evaluated)                              
% OUTPUTS:
%   direct_subsector_risk: a table containing as one variable the direct risk for each
%       subsector/country combination covered in the original mriot. The
%       order of entries follows the same as in the entire process, i.e.
%       entry mapping is still possible via the climada_mriot.setors and
%       climada_mriot.countries arrays. The table further contins three
%       more variables with the country names, country ISO codes and sector names
%       corresponging to the direct risk values.
%  direct_country_risk: a table containing as one variable the direct risk per country (aggregated across all subsectors) 
%       based on the risk measure chosen. Further a variable with correpsonding country
%       names and country ISO codes, respectively.
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20180115, initial
% Ediz Herms, ediz.herms@outlook.com, 20180118, disaggregate direct risk to all subsectors for each country
% Ediz Herms, ediz.herms@outlook.com, 20180212, possibility to provide entity on subsector level
% Ediz Herms, ediz.herms@outlook.com, 20180416, impact_analysis_mode: option to only calculate direct risk for a subset of country x mainsector-combinations
%-

direct_subsector_risk = []; % init output
direct_country_risk = []; % init output

global climada_global
if ~climada_init_vars, return; end % init/import global variables

% poor man's version to check arguments
if ~exist('climada_mriot', 'var'), climada_mriot = []; end
if ~exist('aggregated_mriot', 'var'), aggregated_mriot = []; end
if ~exist('risk_measure', 'var'), risk_measure = []; end
if ~exist('params','var'), params = struct; end
if ~exist('country_name','var'), country_name = []; end
if ~exist('mainsector_name','var'), mainsector_name = []; end

% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)
if exist([climada_global.modules_dir filesep 'advanced' filesep 'data'],'dir') 
    module_data_dir=[climada_global.modules_dir filesep 'advanced' filesep 'data'];
else
    module_data_dir=[climada_global.modules_dir filesep 'climada_advanced' filesep 'data'];
end

% PARAMETERS
if isempty(climada_mriot), climada_mriot = mrio_read_table; end
if isempty(aggregated_mriot), aggregated_mriot = mrio_aggregate_table(climada_mriot); end
if isempty(risk_measure), risk_measure = 'EAD'; end
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

mrio_countries_ISO3 = unique(climada_mriot.countries_iso, 'stable');
n_mrio_countries = length(mrio_countries_ISO3);

mainsectors = unique(climada_mriot.climada_sect_name, 'stable');
n_mainsectors = length(mainsectors);

subsectors = unique(climada_mriot.sectors, 'stable');
n_subsectors = climada_mriot.no_of_sectors;   

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
    
    selection_risk = zeros(length(selection_mainsector),length(selection_country));
    for selection_country_i = 1:length(selection_country)
        selection_risk(:,selection_country_i) = ones(1,length(selection_mainsector)).*(selection_country_i-1)*n_mainsectors+selection_mainsector; % TO DO: only one selection possible atm
    end
    selection_risk = reshape(selection_risk,[1,size(selection_risk,1)*size(selection_risk,2)]);
    
    else 
    selection_risk = [];
end

% check whether user provided data on subsector level in entity directory
subsector_information = zeros(1,n_subsectors*n_mrio_countries);
for subsector_j = 1:n_subsectors
    subsector_name = char(climada_mriot.sectors(subsector_j)); % extract subsector name
    mainsector_name = char(climada_mriot.climada_sect_name(subsector_j)); % extract mainsector name
    mainsector_j = find(mainsector_name == mainsectors);
    for mrio_country_i = 1:n_mrio_countries
        country_ISO3 = char(mrio_countries_ISO3(mrio_country_i)); % extract ISO code
        if ismember(mainsector_j+n_mainsectors*(mrio_country_i-1),selection_risk) & (exist(fullfile(climada_global.entities_dir, [country_ISO3 '_' mainsector_name '_' subsector_name '.mat']), 'file') == 2) 
            % if entity on subsector level exists (condition fullfilled) assign value = 1
            subsector_information(subsector_j+n_subsectors*(mrio_country_i-1)) = 1;
        end
    end
end
subsector_information = find(subsector_information);

% load hazard
hazard = climada_hazard_load(params.hazard_file);

climada_progress2stdout % init, see terminate below

% direct risk calculation per mainsector and per country
risk_i = 0;
direct_mainsector_risk = zeros(1,n_mainsectors*n_mrio_countries);    
for mainsector_j = 1:n_mainsectors % different exposure (asset) base as generated by mrio_generate_XXX_entity functions
    mainsector_name = char(mainsectors(mainsector_j));

    % load (global) mainsector entity
    mainsector_entity_file = ['GLB_' mainsector_name '_XXX.mat'];
    mainsector_entity = climada_entity_load(mainsector_entity_file);

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
            %uiwait(warndlg('Please prepare entities first.'));
        end

        if ~strcmp(country_ISO3,'RoW')
            country_NatID = find(ismember(countries_ISO3, country_ISO3)); % extract NatID
            sel_assets = eq(ismember(entity.assets.NatID, country_NatID),~isnan(entity.assets.Value)); % select all non-NaN assets of this country
        else % 'Rest of World' (RoW) is viewed as a country 
            list_RoW_ISO3 = setdiff(countries_ISO3, mrio_countries_ISO3); % find all countries that are not individually listed in the MRIO table 
            list_RoW_NatID = find(ismember(countries_ISO3, list_RoW_ISO3)); % extract NatID
            sel_assets = eq(ismember(entity.assets.NatID, list_RoW_NatID),~isnan(entity.assets.Value)); % select all non-NaN RoW assets
        end

        entity_sel = entity;
        entity_sel.assets.Value = entity.assets.Value .* sel_assets;  % set values = 0 for all assets outside country i.

        % risk calculation (see subfunction)
        if ~isempty(entity_sel.assets.Value) & (isempty(selection_risk) | ismember(mainsector_j+n_mainsectors*(mrio_country_i-1),selection_risk))
            direct_mainsector_risk(mainsector_j+n_mainsectors*(mrio_country_i-1)) = risk_calc(entity_sel, hazard, risk_measure);
        elseif isempty(entity_sel.assets.Value) | (~isempty(selection_risk) & ~ismember(mainsector_j+n_mainsectors*(mrio_country_i-1),selection_risk))
            direct_mainsector_risk(mainsector_j+n_mainsectors*(mrio_country_i-1)) = 0;
        end

        risk_i = risk_i + length(aggregated_mriot.aggregation_info.(mainsector_name)) - length(subsector_information)/n_mainsectors/n_mrio_countries;
        climada_progress2stdout(risk_i,n_mrio_countries*n_subsectors,5,'risk calculations'); % update

    end % mrio_country_i

end % mainsector_j

% Disaggregate direct mainsector risk to direct risk for all subsector/country combinations
direct_subsector_risk = mrio_disaggregate_risk(direct_mainsector_risk, climada_mriot, aggregated_mriot);

% direct risk calculation on subsector level
total_subsector_production = sum(climada_mriot.mrio_data,2)';
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
        direct_subsector_risk(sel_pos) = risk_calc(entity, hazard, risk_measure) * total_subsector_production(sel_pos);
    else
        direct_subsector_risk(sel_pos) = 0;
    end
    
    climada_progress2stdout(risk_i + subsector_i,n_mrio_countries*n_subsectors,5,'risk calculations'); % update
end

climada_progress2stdout(0) % terminate

% aggregate direct risk across all sectors per country to obtain direct
% country risk:
direct_country_risk = zeros(1,n_mrio_countries); 
for mrio_country_i = 1:n_mrio_countries
    for subsector_j = 1:n_subsectors 
        direct_country_risk(mrio_country_i) = direct_country_risk(mrio_country_i) + direct_subsector_risk((mrio_country_i-1) * n_subsectors+subsector_j);
    end % subsector_j
end % mrio_country_i

%%% For better readability, we return final results as tables so that
%%% countries and sectors corresponding to the values are visible on
%%% first sight. Further, a table allows reordering of values:

direct_subsector_risk = table(climada_mriot.countries',climada_mriot.countries_iso',climada_mriot.sectors',direct_subsector_risk', ...
                                'VariableNames',{'Country','CountryISO','Subsector','DirectSubsectorRisk'});
direct_country_risk = table(unique(climada_mriot.countries','stable'),unique(climada_mriot.countries_iso','stable'),direct_country_risk',...
                                'VariableNames',{'Country','CountryISO','DirectCountryRisk'});

%% Risk calculation function    
function risk = risk_calc(entity, hazard, risk_measure)
    
    % calculate event damage set
    EDS = climada_EDS_calc(entity, hazard, '', '', 2, '');

    % Calculate Damage exceedence Frequency Curve (DFC)
    %DFC = climada_EDS2DFC(EDS);

    % convert an event (per occurrence) damage set (EDS) into a year damage set (YDS)
    %YDS = climada_EDS2YDS(EDS, hazard);

    % quantify risk with specified risk measure 
    switch risk_measure
        case 'EAD' % Expected Annual Damage
            risk = EDS.ED;
        case '100y-event' % TO DO 
            return_period = 100;
            sel_pos = max(find(DFC.return_period >= return_period));
            risk = DFC.damage(sel_pos);
        case '50y-event' % TO DO 
            return_period = 50;
            sel_pos = max(find(DFC.return_period >= return_period));
            risk = DFC.damage(sel_pos);
        case '20y-event' % TO DO 
            return_period = 20;
            sel_pos = max(find(DFC.return_period >= return_period));
            risk = DFC.damage(sel_pos);
        case '10y-event' % TO DO 
            return_period = 10;
            sel_pos = max(find(DFC.return_period >= return_period));
            risk = DFC.damage(sel_pos);
        case 'worst-case' % TO DO 
            sel_pos = max(find(DFC.return_period));
            risk = DFC.damage(sel_pos);
        otherwise
            error('Please specify risk measure properly.')
            return
    end % switch risk_measure
    
end % risk_calc
   
end % mrio_direct_risk_calc