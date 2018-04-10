function [entity, entity_save_file] = mrio_generate_forestry_entity(n_aggregations, params)
% mrio generate forestry entity
% MODULE:
%   advanced
% NAME:
%	mrio_generate_forestry_entity
% PURPOSE:
%   Construct a global entity file based on Land Cover map from the Climate Change Initiative (CCI) 
%
%   next call:
%       mrio_entity_country to generate country entities and to prepare for mrio 
%       (multi regional I/O table) project
%
% CALLING SEQUENCE:
%   mrio_generate_forestry_entity
% EXAMPLE:
%   mrio_generate_forestry_entity
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   n_aggregations: number of aggregation runs of the land cover data, default is ='4' 
%       whereas minimum number of runs is 1 as the dataset is too large to be handled otherwise
%   params: a struct containing several fields, some of which are struct
%       themselves that contain default values used in the entity generation
% OUTPUTS:
%  entity: a structure, with (please run the first example above and then
%       inspect entity for the latest content)
%       assets: itself a structure, with
%           lat: [1xn double] the latitude of the values
%           lon: [1xn double] the longitude of the values
%           Value: [1xn double] the total insurable value
%           Value_unit: {1xn cell}
%           Deductible: [1xn double] the deductible, default=0
%           Cover: [1xn double] the cover, defualt=Value
%           DamageFunID: [1xn double] the damagefunction curve ID
%           filename: the filename the content has been imported from
%           Category_ID: [1xn double] the category ID, see also entity.names
%           Region_ID: [1xn double] the region ID, see also entity.names
%           reference_year: [double] the year the assets are valid for
%           centroid_index: [1xn double] the centroids the assets have been
%               encoede to (unless you specifiec 'NOENCODE') 
%           hazard: only present if you did encode, itself a struct with
%               filename: the filename with path to the hazard you used
%               comment: the free comment as in hazard.comment
%       damagefunctions: itself a structure, with
%           DamageFunID: [nx1 double] the damagefunction curve ID
%           Intensity: [nx1 double] the hazard intensity
%           MDD: [nx1 double] the mean damage degree (severity of single asset damage)
%           PAA: [nx1 double] the percentage of assets affected
%           peril_ID: {nx1 cell} the peril_ID (such as 'TC', 'EQ')
%           Intensity_unit: {nx1 cell} the intensity unit (such as 'm/s', 'MMI')
%           name: {nx1 cell} a free name, eg. 'TC default'
%           datenum: [nx1 double] the datenum of this record being last
%               modified (set to import date)
%       measures: itself a structure, with
%           name: {nx1 cell} the (free) name of the measure
%           color: {nx1 cell} the color as RGB triple (e.g. '0.5 0.5 0.5')
%               to color the measure for display purposes
%           color_RGB: [nx3 double] the color converted from a string as in
%               color to RGB values as double
%           cost: [nx1 double] the cost of the measure. Make sure it is the
%               same units as assets.Value ;-)
%           hazard_intensity_impact_a: [nx1 double] the a parameter to
%               convert hazard intensity, i.e. i_used=i_orig*a+b
%           hazard_intensity_impact_b: [nx1 double] the b parameter to
%               convert hazard intensity, i.e. i_used=i_orig*a+b
%           hazard_high_frequency_cutoff: [nx1 double] the frequency
%           cutoff, i.e. set =1/30 to signify a measure which avoids any
%               damage up to 30 years of return period
%           hazard_event_set: {nx1 cell} to provide an alternative hazard
%               event set for a specific measure (advanced use only)
%           MDD_impact_a: [nx1 double] the a parameter to
%               convert MDD, i.e. MDD_used=MDD_orig*a+b
%           MDD_impact_b: [nx1 double] the b parameter to
%               convert MDD, i.e. MDD_used=MDD_orig*a+b
%           PAA_impact_a: [nx1 double] the a parameter to
%               convert PAA, i.e. PAA_used=PAA_orig*a+b
%           PAA_impact_b: [nx1 double] the b parameter to
%               convert PAA, i.e. PAA_used=PAA_orig*a+b
%           damagefunctions_map: {nx1 cell} to map to an alternative damage
%               function, contains elements such as '1to3;4to27' which means
%               map DamageFunID 1 to 3 and 4 to 27 to implement the impact of
%               the measure
%           damagefunctions_mapping: [1xn struct] the machine-readable
%               version of damagefunctions_map, with fields
%               damagefunctions_mapping(i).map_from: the (list of)
%               DamageFunIDs to map from, i.e. =[1 4] for the example above
%               damagefunctions_mapping(i).map_to: the (list of)
%               DamageFunIDs to map to, i.e. =[3 27] for the example above
%           peril_ID: {nx1 cell} the peril the respective measure applies
%               to (to allow for a multi-peril analysis driven by one entity
%               file - the user still needs to run climada_measures_impact for
%               each peril separately
%           damagefunctions: a full damagefunctions struct (as decribed
%               above), which gets 'switched to' when calculating measure's
%               impacts (see code climada_measures_impact). It is usally a
%               copy of entity.damagefunctions (as the entity file read for
%               measures does cntain a tab damagefunctions, hence gets read
%               again, does no harm...)
%           risk_transfer_attachement: [nx1 double] the attachement point
%               for risk transfer
%           risk_transfer_cover: [nx1 double] the cover for risk transfer
%           filename: the filename the content has been imported from
%           Region_ID: [nx1 double] NOT USED currently, see remark for regional_scope
%           assets_file: {nx1 cell} NOT USED currently, see remark for assets_file
%           /regional_scope/: (only supported in earlier climada release 2)
%               if assets tab found wich specifies the regional_scope of a measure 
%           /assets_file/: (only supported in earlier climada release 2)
%               to provide assets for a regional scope
%       discount: a structure, with
%           yield_ID: an ID to implement several yield curves (not supported yet, default=1)
%           year: the year a particular discount rate is valid for. If you
%               use a constant discount rate, just provide the same number for
%               each year (as in the template).
%           discount_rate: the discount_rate (e.g. 0.02 for 2%, but you can
%               format the cell as percentage in Exel - but not in .ods) per year 
%   entity_save_file: the name the encoded entity got saved to
% RESTRICTIONS:
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20180228, initial
% Ediz Herms, ediz.herms@outlook.com, 20180306, aggregate values - resolution can be managed via input
%

entity = []; % init output
entity_save_file = []; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('n_aggregations', 'var'), n_aggregations = []; end
if ~exist('params','var'), params = struct; end

% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)
if exist([climada_global.modules_dir filesep 'advanced' filesep 'data'],'dir') 
    module_data_dir = [climada_global.modules_dir filesep 'advanced' filesep 'data'];
else
    module_data_dir = [climada_global.modules_dir filesep 'climada_advanced' filesep 'data'];
end

% PARAMETERS
%
if isempty(n_aggregations) 
    n_aggregations = 4; 
elseif n_aggregations <= 1
    n_aggregations = 1;
end
if ~isfield(params,'centroids_file') || isempty(params.centroids_file)
    if (exist(fullfile(climada_global.centroids_dir, 'GLB_NatID_grid_0360as_adv_1.mat'), 'file') == 2) 
        params.centroids_file = 'GLB_NatID_grid_0360as_adv_1.mat';
    else % prompt for centroids filename
        params.centroids_file = [climada_global.centroids_file];
        [filename, pathname] = uigetfile(params.centroids_file, 'Select centroids file:');
        if isequal(filename,0) || isequal(pathname,0)
            return; % cancel
        else
            params.centroids_file = fullfile(pathname, filename);
        end
    end
end
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
%% 
% land cover map (300m observation) in .nc format
full_img_file = [module_data_dir filesep 'mrio' filesep 'ESACCI-LC-L4-LCCS-Map-300m-P1Y-2015-v2.0.7.nc'];
%
% Source:
% Land Cover from the Climate Change Initiative (CCI) 
% processed by ESA and by the Université Catholique de Louvain,
% 2015, "Land Cover Map 2015, Version 2.0",
% http://maps.elie.ucl.ac.be/CCI/viewer/
%
% detailed instructions where to obtain the file and references to the original 
% source can be found in the README file _readme.txt in the module's data dir.
%%
%
% template entity file, such that we do not need to construct the entity from scratch
entity_file = [climada_global.entities_dir filesep 'entity_template' climada_global.spreadsheet_ext];
%

% load global centroids
centroids = climada_centroids_load(params.centroids_file);

% load hazard
hazard = climada_hazard_load(params.hazard_file);

% check for full global land cover image being locally available
if ~exist(full_img_file,'file')
    fprintf(['Global land cover file "' full_img_file '" does not exist. Check README file for instructions where to obtain the file.']);
    return
end

if exist(entity_file,'file')
    entity = climada_entity_read(entity_file,'SKIP'); % read the empty entity
    if isfield(entity,'assets'), entity = rmfield(entity,'assets'); end
else
    fprintf('WARNING: base entity %s not found, entity just entity.assets\n', entity_file);
end

%read lat and lon vectors
lat_cs = ncread([full_img_file],'lat'); n_lat = length(lat_cs);
lon_cs = ncread([full_img_file],'lon'); n_lon = length(lon_cs);

forest = [50 60 61 70 71 80 81 90]; % see chapter 3.1.1 Legend (page 26) of Land Cover CCI PRODUCT USER GUIDE VERSION 2.0
weight = [1 1 1 1 1 1 1 1]; % possibility to assign different values to different types and densitites of forests 

climada_progress2stdout % init, see terminate below

n_subsets = 200; % ggT dimensions

lc_agg = [];
lat_agg = [];
lon_agg = [];
for subset_i = 1:n_subsets
    
    % get lat and lon indices which covers subset area (defined by rectangle)
    min_lat = find(lat_cs <= min(lat_cs), 1, 'first');
    max_lat = find(lat_cs >= max(lat_cs), 1, 'last');
    min_lon = find(lon_cs <= lon_cs(1+(subset_i-1)*(n_lon/n_subsets)), 1, 'last');
    max_lon = find(lon_cs >= lon_cs(subset_i*(n_lon/n_subsets)), 1, 'first');
    
    % get final lat lon vectors
    lat_subset = lat_cs(max_lat:min_lat); lat_subset = flipud(lat_subset);
    lon_subset = lon_cs(min_lon:max_lon); lon_subset = lon_subset';
    numel_lat = numel(lat_subset); numel_lon = numel(lon_subset);
    [lon_subset lat_subset] = meshgrid(lon_subset,lat_subset);
    
    % read land cover data within rectangle
    lc_subset = ncread([full_img_file],'lccs_class',[min_lon max_lat],[numel_lon numel_lat]); lc_subset = flipud(lc_subset');
    
    lc_subset(~ismember(lc_subset,[forest])) = 0;
    
    for forest_i = 1:length(forest)
        lc_subset(lc_subset == forest(forest_i)) = weight(forest_i);
    end
    
    % 1st aggregation (per subset)
    lc_subset_agg = table_circshift_agg(lc_subset, 1, 1);
    lon_subset_agg = table_circshift_agg(lon_subset, 0, 1);
    lat_subset_agg = table_circshift_agg(lat_subset, 0, 1);

    % put together aggregated subset values to one table
    lc_agg = [lc_agg lc_subset_agg];
    lon_agg = [lon_agg lon_subset_agg];
    lat_agg = [lat_agg lat_subset_agg];
    
    climada_progress2stdout(subset_i,n_subsets,1,'processed subsets'); % update
    
end

climada_progress2stdout(0) % terminate

clear lc_subset lc_subset_agg lon_subset_agg lat_subset_agg permutation_i

% aggregate values via subfunction table_circshift_agg
lc_agg = table_circshift_agg(lc_agg, 1, n_aggregations-1);
lon_agg = table_circshift_agg(lon_agg, 0, n_aggregations-1);
lat_agg = table_circshift_agg(lat_agg, 0, n_aggregations-1);

% reshape to Nx1 vector
forestry_intensity = reshape(lc_agg, [1,size(lc_agg,1)*size(lc_agg,2)]);
forestry_lon = reshape(lon_agg, [1,size(lon_agg,1)*size(lon_agg,2)]);
forestry_lat = reshape(lat_agg, [1,size(lat_agg,1)*size(lat_agg,2)]);

% save aggregated non-zero values as assets
entity.assets.Value = forestry_intensity(forestry_intensity>0);
entity.assets.lon = double(forestry_lon(forestry_intensity>0));
entity.assets.lat = double(forestry_lat(forestry_intensity>0));

% for consistency, update Deductible and Cover
entity.assets.Deductible = entity.assets.Value*0;
entity.assets.Cover = entity.assets.Value;

% pass over (default) DamageFunID
entity.assets.DamageFunID = entity.assets.Value*0+1;

% encode entity
entity = climada_assets_encode(entity, hazard);

% pass over ISO3 codes and NatID to assets
fprintf('get NatID for %i assets ...\n',length(entity.assets.Value));
entity.assets.ISO3_list = centroids.ISO3_list;

climada_progress2stdout % init, see terminate below

for asset_i = 1:length(entity.assets.Value)
    sel_centroid = entity.assets.centroid_index(asset_i);
    if sel_centroid > 0 && length(centroids.NatID) > sel_centroid
        entity.assets.NatID(asset_i) = centroids.NatID(sel_centroid);
    else
        entity.assets.NatID(asset_i) = 0;
    end
    climada_progress2stdout(asset_i,length(entity.assets.Value),5,'processed assets'); % update
end % asset_i

climada_progress2stdout(0) % terminate

% save filename and comment to ensure transparency
entity.assets.reference_year = climada_global.present_reference_year;
entity.assets.source_file = full_img_file;
entity.assets.comment = sprintf('generated by %s at %s', mfilename,datestr(now)); 

entity_save_file = [climada_global.entities_dir filesep 'GLB_forestry_fishing_XXX.mat'];
entity.assets.filename = entity_save_file;

% make sure we have all fields and they are 'correct'
entity.assets = climada_assets_complete(entity.assets);

% save entity as .mat file for fast access
fprintf('saving entity as %s\n', entity_save_file);
climada_entity_save(entity, entity_save_file);

%% Table circshift aggregation subfunction
function table = table_circshift_agg(table, aggregation_rule, iterations)
    
    while iterations >= 1

        position_shift = [1 0; 0 1; -1 0; 0 -1; -1 -1; -1 1; 1 1;1 -1];
        agg_table = table;
        
        if aggregation_rule ~= 0
            for shift_i = 1:8
                permutation_i = circshift(table,[position_shift(shift_i,1), position_shift(shift_i,2)]);
                agg_table = agg_table + permutation_i;
            end % shift_i
        end
        
        switch aggregation_rule
            case 0 % do not aggregate, only return condensed table
                table = table((floor(3/2)+1):3:size(agg_table,1),(floor(3/2)+1):3:size(agg_table,2));
            case 1 % aggregate values
                table = agg_table((floor(3/2)+1):3:size(agg_table,1),(floor(3/2)+1):3:size(agg_table,2));
            case 2 % calculate average value
                table = agg_table((floor(3/2)+1):3:size(agg_table,1),(floor(3/2)+1):3:size(agg_table,2))/9;
            otherwise % default
                table = agg_table((floor(3/2)+1):3:size(agg_table,1),(floor(3/2)+1):3:size(agg_table,2));
        end % switch aggregation_rule
        
        iterations = iterations - 1;
        
    end % iterations
    
end % table_circshift_agg

end % mrio_generate_forestry_entity