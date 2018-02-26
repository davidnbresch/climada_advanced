function [entity, entity_save_file] = mrio_generate_mining_entity(hazard, encode_flag)
% mrio generate mining entity
% MODULE:
%   advanced
% NAME:
%	mrio_generate_country_entity
% PURPOSE:
%   Construct a global entity file based on global data on active mines and mineral plants. 
%
%   SPECIAL: run mrio_entity_country to generate country entities and
%   to prepare for mrio (multi regional I/O table) project
%
% CALLING SEQUENCE:
%   mrio_generate_country_entity
% EXAMPLE:
%   mrio_generate_country_entity
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   hazard: either a hazard set (struct) or a hazard set file (.mat with a
%       struct) or a centroid struct (as returned by climada_centroids_load or
%       climada_centroids_read). hazard needs to have fields hazard.lon and
%       hazard.lat, centroids fields centroids.lon and centroids.lat  
%       > promted for if not given (select either a hazard event set or a
%       centroids .mat file)
%       if set to 'SKIP', do not encode, return original assets (used for
%       special cases, where this way no need for if statements prior to
%       calling climada_assets_encode)
%       SPECIAL: centroids with centroid_ID<0 (in either hazard.centroid_ID
%       or centroids.centroid_ID) are not used in encoding.
%       (this way the user can e.g. temporarily 'disable' centroids prior
%       to passing them to climada_assets_encode by simply setting their
%       centroid_ID=-1)
%       NOTE: if isfield(centroids,'peril_ID') and FL some special rules apply
%   encode_flag: if =1, map read data points to calculation centroids of
%       hazard event set. Default=0.
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
% Ediz Herms, ediz.herms@outlook.com, 20180115, initial

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('hazard', 'var'), hazard = []; end
if ~exist('encode_flag', 'var'), encode_flag = []; end 

% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)
if exist([climada_global.modules_dir filesep 'advanced' filesep 'data'],'dir') 
    module_data_dir = [climada_global.modules_dir filesep 'advanced' filesep 'data'];
else
    module_data_dir = [climada_global.modules_dir filesep 'climada_advanced' filesep 'data'];
end

% PARAMETERS
if isempty(hazard), hazard = climada_hazard_load; end
if isempty(encode_flag), encode_flag = 0; end
%
% the file with the active mines and mineral plants in the US
% see https://mrdata.usgs.gov/mineplant/
filename{1} = [climada_global.data_dir filesep 'mineplant.xls'];
% and the file with the mineral operations outside the United States
% see https://mrdata.usgs.gov/mineral-operations/
filename{2} = [climada_global.data_dir filesep 'minfac.xls'];
% and the detailed instructions where to obtain in the file
% TEXT FILE WILL BE GIVEN LATER in the module's data dir.
%
% isimip centroids file, see XXX
centroids_file = [climada_global.centroids_dir filesep 'GLB_NatID_grid_0360as_adv_1.mat'];
%
% template entity file, such that we do not need to construct the entity from scratch
entity_file = [climada_global.entities_dir filesep 'entity_template' climada_global.spreadsheet_ext];
%

% load global (isimip) centroids
centroids = climada_centroids_load(centroids_file);

% check for data files being locally available
for file_i = 1:length(filename)
    if ~exist(filename{file_i},'file')
        fprintf(['Data file "' filename{file_i} '" does not exist.']);
        return
    end
end

if exist(entity_file,'file')
    entity = climada_entity_read(entity_file,'SKIP'); % read the empty entity
    if isfield(entity,'assets'), entity = rmfield(entity,'assets'); end
else
    fprintf('WARNING: base entity %s not found, entity just entity.assets\n', entity_file);
end

for file_i = 1:length(filename)
    % [fP, fN, fE] = fileparts(filename{file_i});
        
    entity_i = entity;
    
    xls_data = climada_xlsread('',filename{file_i},'',1);
   
    if isfield(xls_data,'LATITUDE')
        entity_i.assets.lon = xls_data.LONGITUDE(:)';
        entity_i.assets.lat = xls_data.LATITUDE(:)';
        entity_i.assets.Value = zeros(1,length(entity_i.assets.lon))+1;
    else
        entity_i.assets.lon = xls_data.longitude(:)';
        entity_i.assets.lat = xls_data.latitude(:)';
        entity_i.assets.Value = zeros(1,length(entity_i.assets.lon))+1;
    end
    
    % for consistency, update Deductible and Cover
    entity_i.assets.Deductible = entity_i.assets.Value*0;
    entity_i.assets.Cover = entity_i.assets.Value;
    
    % pass over (default) DamageFunID and filename
    entity_i.assets.DamageFunID = entity_i.assets.Value*0+1;
    entity_i.assets.reference_year = climada_global.present_reference_year;
    
    entity_i.assets.filename = filename{file_i};
    
    if file_i == 1
        entity = entity_i;
    else
        entity = climada_entity_combine(entity, entity_i);
    end
    
end

% encode entity
if encode_flag, entity = climada_assets_encode(entity, hazard); end

% pass over ISO3 codes and NatID to assets
entity.assets.ISO3_list = centroids.ISO3_list;

n_assets = length(entity.assets.Value);
for asset_i = 1:n_assets
    sel_centroid = entity.assets.centroid_index(asset_i);
    if sel_centroid > 0 && length(centroids.NatID) > sel_centroid
        entity.assets.NatID(asset_i) = centroids.NatID(sel_centroid);
    else
        entity.assets.NatID(asset_i) = 0;
    end
end % asset_i

entity.assets.reference_year = climada_global.present_reference_year;
entity.assets.filename = filename;
entity.assets.comment = sprintf('generated by %s at %s', mfilename,datestr(now)); 

% make sure we have all fields and they are 'correct'
entity.assets = climada_assets_complete(entity.assets); 

% save entity as .mat file for fast access
entity_save_file = [climada_global.entities_dir filesep 'GLB_mining_quarrying_XXX.mat'];
fprintf('saving entity as %s\n', entity_save_file);
climada_entity_save(entity, entity_save_file);

end % mrio_generate_entity
