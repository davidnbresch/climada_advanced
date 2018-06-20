function mrio_entity_country(GLB_entity, climada_mriot, switch_scale, check_figure, markersize, params)
% mrio entity country
% MODULE:
%   advanced
% NAME:
%	mrio_entity_country
% PURPOSE:
%   Generates entity files based on a global entity struct for a predefined 
%   set of countries. Furthermore, entities are prepared for MRIO (Multi 
%   Regional Input-Output) project, including
%       - get NatID for each asset
%       - normalize asset values as specified
%
%   NOTE: see PARAMETERS in code
%
%   previous call: 
%       climada_entity_load and mrio_read_table
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
%   switch_scale: set to 2 to scale asset values with total main sector 
%       production per country as given by mrio table, by default normalize 
%       asset values per country so that they add up to one (=1)
%   check_figure: set to 1 to visualize figures, by default entities are not plotted (=0)
%   markersize: the size of the 'tiles', one might need to experiment a
%       bit (that's why markersize is not part of params.)
%   params: a structure to pass on parameters, with fields as
%       (run params = mrio_get_params to obtain all default values)
%       centroids_file: the filename of the centroids file containing 
%           information on NatID for all centroid
%       hazard_file: the filename of the corresponding hazard file that is
%           is used to encode the constructed entity
%       verbose: whether we printf progress to stdout (=1, default) or not (=0)
% OUTPUTS:
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20180217, initial
% Ediz Herms, ediz.herms@outlook.com, 20180506, option to switch between normalized asset values and ones scaled up with the total sector production
%

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('GLB_entity', 'var'), GLB_entity = []; end
if ~exist('climada_mriot', 'var'), climada_mriot = []; end
if ~exist('switch_scale', 'var'), switch_scale = []; end
if ~exist('check_figure', 'var'), check_figure = []; end
if ~exist('markersize', 'var'), markersize = []; end
if ~exist('params','var'), params = struct; end
if ~exist('mainsector_name','var'), mainsector_name = []; end

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
if isempty(switch_scale), switch_scale = 1; end
if isempty(check_figure), check_figure = 0; end
if isempty(markersize), markersize = 2; end
if ~isfield(params,'hazard_file') || isempty(params.hazard_file)
    if (exist(fullfile(climada_global.hazards_dir, 'GLB_0360as_TC_hist.mat'), 'file') == 2) 
        params.hazard_file = 'GLB_0360as_TC_hist.mat';
    elseif switch_scale ~= 0 % prompt for hazard filename
        params.hazard_file = [climada_global.hazards_dir];
        [filename, pathname] = uigetfile(params.hazard_file, 'Select hazard file:');
        if isequal(filename,0) || isequal(pathname,0)
            return; % cancel
        else
            params.hazard_file = fullfile(pathname, filename);
        end
    end
end
if ~isfield(params,'centroids_file') || isempty(params.centroids_file)
    if (exist(fullfile(climada_global.centroids_dir, 'GLB_NatID_grid_0360as_adv_1.mat'), 'file') == 2) 
        params.centroids_file = 'GLB_NatID_grid_0360as_adv_1.mat';
    elseif switch_scale ~= 0 % prompt for centroids filename
        params.centroids_file = [climada_global.centroids_file];
        [filename, pathname] = uigetfile(params.centroids_file, 'Select centroids file:');
        if isequal(filename,0) || isequal(pathname,0)
            return; % cancel
        else
            params.centroids_file = fullfile(pathname, filename);
        end
    end
end
if ~isfield(params,'verbose'), params.verbose = 1; end

% load global centroids of which we use the NatID to cut out the entities on country level
centroids = climada_centroids_load(params.centroids_file);

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

% prompt for mainsector name to identify production values for scaling asset values
if switch_scale == 2
    mainsectors = unique(climada_mriot.climada_sect_name, 'stable');
    
    [mainsectors_liststr, mainsectors_sort_index] = sort(mainsectors);
    if isempty(mainsector_name)
        % compile list of all mrio countries, then call recursively below
        [selection_mainsector] = listdlg('PromptString','Select mainsector:',...
            'ListString',mainsectors_liststr);
        selection_mainsector = mainsectors_sort_index(selection_mainsector);
    else
        selection_mainsector = find(mainsectors == mainsector_name);
    end
end
        
if ~isfield(GLB_entity.assets, 'ISO3_list') 
    
    % load global centroids
    centroids = climada_centroids_load(params.centroids_file);
    
    % load hazard
    hazard = climada_hazard_load(params.hazard_file);
    
    % encode entity
    GLB_entity = climada_assets_encode(GLB_entity, hazard);

    % pass over ISO3 codes and NatID to assets
    if params.verbose, fprintf('get NatID for %i assets ...\n',n_assets); end
    GLB_entity.assets.ISO3_list = centroids.ISO3_list;

    if params.verbose, climada_progress2stdout; end % init, see terminate below

    for asset_i = 1:n_assets
        sel_centroid = GLB_entity.assets.centroid_index(asset_i);
        if sel_centroid > 0 && length(centroids.NatID) > sel_centroid
            GLB_entity.assets.NatID(asset_i) = centroids.NatID(sel_centroid);
        else
            GLB_entity.assets.NatID(asset_i) = 0;
        end
        if params.verbose, climada_progress2stdout(asset_i,n_assets,5,'processed assets'); end % update
    end % asset_i

    if params.verbose, climada_progress2stdout(0); end % terminate
    
end

if params.verbose, fprintf('generate %i country entities and prepare for mrio ...\n',n_mrio_countries); end

if params.verbose, climada_progress2stdout; end % init, see terminate below

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
        
        if ~strcmp(country_ISO3_i,'RoW') && ~strcmp(country_ISO3_i,'ROW')
            country_NatID = find(ismember(countries_ISO3, country_ISO3_i)); % extract NatID
            sel_pos = intersect(find(ismember(GLB_entity.assets.NatID, country_NatID)), find(~isnan(GLB_entity.assets.Value))); % select all non-NaN assets % select all non-NaN assets of this country
        else % 'Rest of World' (RoW) is viewed as a country 
            list_RoW_ISO3 = setdiff(countries_ISO3, mrio_countries_ISO3); % find all countries that are not individually listed in the MRIO table 
            list_RoW_NatID = find(ismember(countries_ISO3, list_RoW_ISO3)); % extract NatID
            sel_pos = intersect(find(ismember(GLB_entity.assets.NatID, list_RoW_NatID)), find(~isnan(GLB_entity.assets.Value))); % select all non-NaN RoW assets
        end
        
        entity.assets.lon = GLB_entity.assets.lon(sel_pos); % restrict entity to country
        entity.assets.lat = GLB_entity.assets.lat(sel_pos);  
        
        if switch_scale == 0
            entity.assets.Value = GLB_entity.assets.Value(sel_pos);
        elseif switch_scale == 1 % normalize asset values
            entity.assets.Value = GLB_entity.assets.Value(sel_pos)/sum(GLB_entity.assets.Value(sel_pos));
        elseif switch_scale == 2 % scale up with total mainsector production
            mainsector_index = find(ismember(climada_mriot.climada_sect_name,mainsectors(selection_mainsector)));
            country_index = find(ismember(climada_mriot.countries_iso,country_ISO3_i));
            total_mainsector_production = sum(climada_mriot.total_production(intersect(country_index,mainsector_index)));
            entity.assets.Value = (GLB_entity.assets.Value(sel_pos)/sum(GLB_entity.assets.Value(sel_pos))) * total_mainsector_production;
        end
        
        % for consistency, update Deductible and Cover
        entity.assets.Cover = entity.assets.Value; 
        entity.assets.Deductible = GLB_entity.assets.Deductible(sel_pos);
        
        % pass over Value_unit, DamageFunID, centroid_index,...
        entity.assets.Value_unit = GLB_entity.assets.Value_unit(sel_pos);
        entity.assets.DamageFunID = GLB_entity.assets.DamageFunID(sel_pos);
        entity.assets.centroid_index = GLB_entity.assets.centroid_index(sel_pos);
        entity.assets.Category_ID = GLB_entity.assets.Category_ID(sel_pos);
        entity.assets.NatID = GLB_entity.assets.NatID(sel_pos);
        
        % save filename and comment to ensure transparency
        entity.assets.reference_year = climada_global.present_reference_year;
        entity.assets.comment = sprintf('generated by %s at %s', mfilename,datestr(now)); 
        entity.assets.filename = entity_save_file;
        if isfield(entity.assets,'source_file'), entity.assets.source_file = GLB_entity.assets.source_file; end
        
        % make sure we have all fields and they are 'correct'
        entity.assets = climada_assets_complete(entity.assets);
       
        % save entity as .mat file for fast access
        climada_entity_save(entity,entity_save_file);
        
    end
    
    if check_figure
        climada_entity_plot(entity, markersize);
    end
    
    if params.verbose, climada_progress2stdout(mrio_country_i,n_mrio_countries,5,'processed countries'); end % update
    
end % mrio_country_i

if params.verbose, climada_progress2stdout(0); end % terminate

end % mrio_entity_country