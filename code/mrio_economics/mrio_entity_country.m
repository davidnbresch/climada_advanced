function mrio_entity_country(GLB_entity, climada_mriot)
% mrio entity country
% MODULE:
%   advanced
% NAME:
%	mrio_entity_country
% PURPOSE:
%   Generates entity files based on a global entity struct for a predefined 
%   set of countries. Furthermore, entities are prepared for mrio (multi 
%   regional I/O table) project.
%
%   NOTE: see PARAMETERS in code
%
%   previous call: 
%   entity = climada_entity_load;
%   climada_mriot = mrio_read_table;
% CALLING SEQUENCE:
%   mrio_entity_country(entity, climada_mriot);
% EXAMPLE:
%   mrio_entity_country(entity, climada_mriot);
% INPUTS:
%   entity: a (global) climada entity structure, see climada_entity_read for a full
%       description of all fields
%   climada_mriot: a struct with ten fields, one of them being countries_iso.
%       The latter is important for this function to define the country for which 
%       we generate entities. The struct represents a general climada mriot structure 
%       whose basic properties are the same regardless of the provided mriot it is 
%       based on, see mrio_read_table; 
%       OR: a country ISO3 code, in which case the entity is restricted to
%       the corresponding country.
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20180217, initial

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('GLB_entity', 'var'), GLB_entity = []; end
if ~exist('climada_mriot', 'var'), climada_mriot = []; end

% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)
if exist([climada_global.modules_dir filesep 'advanced' filesep 'data'],'dir') 
    module_data_dir = [climada_global.modules_dir filesep 'advanced' filesep 'data'];
else
    module_data_dir = [climada_global.modules_dir filesep 'climada_advanced' filesep 'data'];
end

% PARAMETERS
if isempty(GLB_entity), GLB_entity = climada_entity_load; end
if isempty(climada_mriot), climada_mriot = mrio_read_table; end

% centroids file
centroids_file = [climada_global.centroids_dir filesep 'GLB_NatID_grid_0360as_adv_1.mat'];

% load global isimip centroids of which we use the NatID to cut out the entities on country level
centroids = climada_centroids_load(centroids_file);

countries_ISO3 = centroids.ISO3_list(:,1);

% save filename which will be 
[~, fN, fE] = fileparts(GLB_entity.assets.filename);

% check whether we have passed over a climada mriot struct or a country ISO3 code
if isfield(climada_mriot,'mrio_data')
    mrio_countries_ISO3 = unique(climada_mriot.countries_iso, 'stable');
else
    if ischar(climada_mriot) % convert to cell, if single char
        country_ISO3_tmp = climada_mriot;
        country_ISO3 = {}; country_ISO3{1} = country_ISO3_tmp;
    end
    mrio_countries_ISO3 = country_ISO3;
end
n_mrio_countries = length(mrio_countries_ISO3);

fprintf('generate %i country entities and prepare for mrio ...\n',n_mrio_countries);

climada_progress2stdout % init, see terminate below

% create all entities for the mrio countries if not already done
for mrio_country_i = 1:n_mrio_countries
    country_ISO3_i = char(mrio_countries_ISO3(mrio_country_i));
    
    if contains(fN, 'GLB')
        entity_save_file = [climada_global.entities_dir filesep replace(fN,'GLB',country_ISO3_i) fE];
    else
        entity_save_file = [climada_global.entities_dir filesep country_ISO3_i '_' fN fE];
    end
    
    if ~exist(entity_save_file,'file')
        
        entity = GLB_entity; 
        
        if country_ISO3_i ~= 'ROW'
            country_NatID = find(ismember(countries_ISO3, country_ISO3_i)); % extract NatID
            sel_pos = intersect(find(ismember(GLB_entity.assets.NatID, country_NatID)), find(~isnan(GLB_entity.assets.Value))); % select all non-NaN assets % select all non-NaN assets of this country
        else % 'Rest of World' (RoW) is viewed as a country 
            list_RoW_ISO3 = setdiff(countries_ISO3, mrio_countries_ISO3); % find all countries that are not individually listed in the MRIO table 
            list_RoW_NatID = find(ismember(countries_ISO3, list_RoW_ISO3)); % extract NatID
            sel_pos = intersect(find(ismember(GLB_entity.assets.NatID, list_RoW_NatID)), find(~isnan(GLB_entity.assets.Value))); % select all non-NaN RoW assets
        end
        
        entity.assets.lon = GLB_entity.assets.lon(sel_pos); % restrict entity to country
        entity.assets.lat = GLB_entity.assets.lat(sel_pos);        
        entity.assets.Value = GLB_entity.assets.Value(sel_pos)/sum(GLB_entity.assets.Value(sel_pos)); % normalize assets
        entity.assets.Cover = GLB_entity.assets.Cover(sel_pos)/sum(GLB_entity.assets.Cover(sel_pos)); 
        entity.assets.Value_unit = GLB_entity.assets.Value_unit(sel_pos);
        entity.assets.Deductible = GLB_entity.assets.Deductible(sel_pos);
        entity.assets.DamageFunID = GLB_entity.assets.DamageFunID(sel_pos);
        entity.assets.centroid_index = GLB_entity.assets.centroid_index(sel_pos);
        entity.assets.Category_ID = GLB_entity.assets.Category_ID(sel_pos);
        entity.assets.NatID = GLB_entity.assets.NatID(sel_pos);
        entity.assets.filename = entity_save_file;
       
        % save entity as .mat file for fast access
        climada_entity_save(entity,entity_save_file);
        
    end
    
    climada_progress2stdout(mrio_country_i,n_mrio_countries,5,'processed countries'); % update
    
end % mrio_country_i

climada_progress2stdout(0) % terminate

end % mrio_entity_country
