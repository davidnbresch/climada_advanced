function entity = mrio_entity_prep(entity_file, centroids_file, climada_mriot) % uncomment to run as function
% mrio entity prep
% MODULE:
%   advanced
% NAME:
%   mrio_entity_prep
% PURPOSE:
%   load centroids and prepare entities for mrio (multi regional I/O table project)
%
%   NOTE: see PARAMETERS in code
%
%   previous call: 
%   see isimip_gdp_entity to generate the global centroids and entity
%   climada_mriot = mrio_read_table;
%   next call: 
%   [direct_subsector_risk, direct_country_risk] = mrio_direct_risk_calc(entity, hazard, climada_mriot, aggregated_mriot, risk_measure); % just to illustrate
% CALLING SEQUENCE:
%   entity = mrio_entity_prep(entity_file, centroids_file, climada_mriot)
% EXAMPLE:
%   climada_mriot = mrio_read_table;
%   entity = entity = mrio_entity_prep('', '', climada_mriot)
% INPUTS:
%   entity_filename: the filename of the Excel (.xls, .xlsx or .ods) file with the assets
%       If no path provided, default path in climada_global.entities_dir is used
%       > promted for if not given
%   centroids_filename: the filename of the Excel file with the centroids
%       > promted for if not given
%   climada_mriot: a struct with ten fields, one of them being countries_iso.
%       The latter is important for this function. The struct represents a general climada
%       mriot structure whose basic properties are the same regardless of the
%       provided mriot it is based on, see mrio_read_table; 
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   entity: the global entity
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20171206, initial
% Ediz Herms, ediz.herms@outlook.com, 20171207, normalize assets per country
% Ediz Herms, ediz.herms@outlook.com, 20180112, ...mrio table as input
% Ediz Herms, ediz.herms@outlook.com, 20180118, prompt for input if not given
%-

entity = []; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('entity_file', 'var'), entity_file = []; end 
if ~exist('centroids_file', 'var'), centroids_file = []; end 
if ~exist('climada_mriot', 'var'), climada_mriot = []; end 
if ~exist('encode_flag', 'var'), encode_flag = []; end 

% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)
if exist([climada_global.modules_dir filesep 'advanced' filesep 'data'],'dir') 
    module_data_dir=[climada_global.modules_dir filesep 'advanced' filesep 'data'];
else
    module_data_dir=[climada_global.modules_dir filesep 'climada_advanced' filesep 'data'];
end

% PARAMETERS
% prompt for entity_filename if not given
if isempty(entity_file) % local GUI
    entity_file = [module_data_dir filesep 'entities'];
    [filename, pathname] = uigetfile(entity_file, 'Select entity file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        entity_file = fullfile(pathname,filename);
    end
end
% prompt for centroids_filename if not given
if isempty(centroids_file) % local GUI
    centroids_file = [module_data_dir filesep 'centroids'];
    [filename, pathname] = uigetfile(centroids_file, 'Select centroids file:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        centroids_file = fullfile(pathname,filename);
    end
end
if isempty(climada_mriot), climada_mriot = mrio_read_table; end
if isempty(encode_flag), encode_flag = 0; end
    
% load global centroids
fprintf('Loading centroids %s\n',centroids_file);
centroids = climada_centroids_load(centroids_file);

% load global entity
fprintf('Loading entity %s\n',entity_file);
entity = climada_entity_load(entity_file);

countries_ISO3 = entity.assets.NatID_RegID.ISO3;
mrio_countries_ISO3 = unique(climada_mriot.countries_iso, 'stable');
n_mrio_countries = climada_mriot.no_of_countries;

% normalization of asset values for all countries as specified in mrio table
for mrio_country_i = 1:n_mrio_countries
    country_ISO3 = mrio_countries_ISO3(mrio_country_i); % extract ISO code
    if country_ISO3 ~= 'ROW'
        country_NatID = find(ismember(countries_ISO3, country_ISO3)); % extract NatID
        sel_pos = intersect(find(ismember(entity.assets.NatID, country_NatID)), find(~isnan(entity.assets.Value))); % select all non-NaN assets % select all non-NaN assets of this country
    else % 'Rest of World' (RoW) is viewed as a country 
        list_RoW_ISO3 = setdiff(countries_ISO3, mrio_countries_ISO3); % find all countries that are not individually listed in the MRIO table 
        list_RoW_NatID = find(ismember(countries_ISO3, list_RoW_ISO3)); % extract NatID
        sel_pos = intersect(find(ismember(entity.assets.NatID, list_RoW_NatID)), find(~isnan(entity.assets.Value))); % select all non-NaN RoW assets
    end
    entity.assets.Value(sel_pos) = entity.assets.Value(sel_pos)/sum(entity.assets.Value(sel_pos)); % normalize assets
end % mrio_country_i

end % mrio_entity_prep
