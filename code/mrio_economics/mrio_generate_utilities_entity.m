function [entity, entity_save_file] = mrio_generate_utilities_entity
% 
% MODULE:
%   advanced
% NAME:
%	mrio_generate_utilities_entity
% PURPOSE:
%   Construct a global entity file based on a global data set of power plant locations.
%   These are for now taken as a proxy for the utilities mainsector.
%
%   next call:
%       mrio_entity_country 
%
% CALLING SEQUENCE:
%   mrio_generate_utilitie_entity
% EXAMPLE:
%   mrio_generate_utilities_entity;   No function arguments required.
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%  entity: a structure, with following fields:
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
%   entity_save_file: the name and path the encoded entity got saved to
% RESTRICTIONS:
% MODIFICATION HISTORY:
% Kaspar Tobler, 20180313, first working version

entity = []; % init output
entity_save_file = []; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments

% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)
if exist([climada_global.modules_dir filesep 'advanced' filesep 'data'],'dir') 
    module_data_dir = [climada_global.modules_dir filesep 'advanced' filesep 'data'];
else
    module_data_dir = [climada_global.modules_dir filesep 'climada_advanced' filesep 'data'];
end

% PARAMETERS

% Get file with all power plants globally. For source and user
% requirements, check user manual or readme file.
utilities_file = [module_data_dir filesep 'entities' filesep 'utilities_source.csv'];
%
% Source: http://enipedia.tudelft.nl/wiki/Using_SPARQL_with_Enipedia
%   Section Advanced > Download all power plant data.


% isimip centroids file, see isimip_gdp_entity to generate the global centroids and entity
centroids_file = [climada_global.centroids_dir filesep 'GLB_NatID_grid_0360as_adv_1.mat'];

% isimip hazard file
hazard_file = [climada_global.hazards_dir filesep 'GLB_0360as_TC_hist.mat'];

% template entity file, such that we do not need to construct the entity from scratch
entity_file = [climada_global.entities_dir filesep 'entity_template' climada_global.spreadsheet_ext];


% load global (isimip) centroids
centroids = climada_centroids_load(centroids_file);

% load (isimip) hazard
hazard = climada_hazard_load(hazard_file);

% check whether required source file exists and ask for user input if it doesn't:
if ~exist(utilities_file,'file')
    [choice] = questdlg('The necessary source file (see manual) does not seem to exist. Please choose the appropriate file manually or donwload first...',...
        'Source file does not exist',...
        'Choose from file dialog.','Donwload first and cancel.','Choose from file dialog.'); % Repeated string specifies default choice.
    if isequal(choice,'') || isequal(choice,'Donwload first and cancel.') % User chose to abort or closed the dialog window without choice.
        error('Necessary source file not provided. Please download first (check user manual) and try again.')
    else
        [filename, pathname] = uigetfile([module_data_dir filesep '*.*'], 'Use the properly named source file for the utilities entity:');
        utilities_file = fullfile(pathname,filename);
    end 
end

if exist(entity_file,'file')
    entity = climada_entity_read(entity_file,'SKIP'); % read the empty entity
    if isfield(entity,'assets'), entity = rmfield(entity,'assets'); end
else
    fprintf('WARNING: base entity %s not found, entity just entity.assets\n', entity_file);
end


% Read from provided source file (.csv):

raw_data = readtable(utilities_file);

% Check whether lon and lat exist and where (might change in future releases):
vars = raw_data.Properties.VariableNames;
if (nnz(contains(vars,'lat','IgnoreCase',true)) > 0) && (nnz(contains(vars,'lon','IgnoreCase',true)) > 0)
    lat_col = find(contains(vars,'lat','IgnoreCase',true));
    lon_col = find(contains(vars,'lon','IgnoreCase',true));
else
    error('There was an error with loading the data. Missing data on longitude and latitude.')
end
    
% Assign lon and lat data as well as palceholder-value of 1 to asset value:
entity.assets.lon = raw_data{:,lon_col}; %#ok
entity.assets.lat = raw_data{:,lat_col}; %#ok
entity.assets.Value = ones(1,length(entity.assets.lon));

% for consistency, update Deductible and Cover
entity.assets.Deductible = entity.assets.Value*0;
entity.assets.Cover = entity.assets.Value;
    
% pass over (default) DamageFunID
entity.assets.DamageFunID = entity.assets.Value*0+1;
    
% encode entity
entity = climada_assets_encode(entity, hazard);

% pass over ISO3 codes and NatID to assets
entity.assets.ISO3_list = centroids.ISO3_list;

n_assets = length(entity.assets.Value);
fprintf('get NatID for %i assets ...\n',n_assets);

climada_progress2stdout % init, see terminate below

for asset_i = 1:n_assets
    sel_centroid = entity.assets.centroid_index(asset_i);
    if sel_centroid > 0 && length(centroids.NatID) > sel_centroid
        entity.assets.NatID(asset_i) = centroids.NatID(sel_centroid);
    else
        entity.assets.NatID(asset_i) = 0;
    end
    climada_progress2stdout(asset_i,n_assets,5,'processed assets'); % update
end % asset_i

climada_progress2stdout(0) % terminate

% save filename and comment to ensure transparency
entity.assets.reference_year = climada_global.present_reference_year;
entity.assets.source_file = utilities_file;
entity.assets.comment = sprintf('generated by %s at %s', mfilename,datestr(now)); 

entity_save_file = [climada_global.entities_dir filesep 'GLB_utilities_XXX.mat'];
entity.assets.filename = entity_save_file;

% make sure we have all fields and they are 'correct'
entity.assets = climada_assets_complete(entity.assets); 

% save entity as .mat file for fast access
fprintf('saving entity as %s\n', entity_save_file);
climada_entity_save(entity, entity_save_file);

end % mrio_generate_utilities_entity




