function assets = climada_assets_crop(assets,polygon_focus_area)
% climada_assets_crop
% MODULE:
%   advanced
% NAME:
%   climada_assets_crop
% PURPOSE:
%   Reduce assets to focus only on a given area. Very useful for large assets, 
%   where only a speficic area is need. 
%   Usually this is the case after climada_nightlight_entity or 
%   climada_create_centroids_entity_base. Analogue to climada_hazard_crop.
% CALLING SEQUENCE:
%   assets = climada_assets_crop(assets,polygon_focus_area)
% EXAMPLE:
%   assets = climada_assets_crop(assets,polygon_focus_area)
% INPUTS: 
%   assets: a climada assets structure
%   polygon_focus_area: structure with polygon coordinate information in fields
%                       .lon and .lat, or .X and .Y that define the focus
%                       area, can be multiple polygon_focus_area(2) or more
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:      
%   assets: a climada assets structure, with .lon, .lat and .Value,
%                        where all coordinates are within the given polygon focus area.
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20160314, init
%-


global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('assets','var'),assets = []; end
if ~exist('polygon_focus_area','var'),polygon_focus_area=[];end

if isempty(assets),entity = climada_entity_load; assets = entity.assets; end
if isempty(polygon_focus_area)
    fprintf('Please specify focus area, with focus_area.lon and focus_area.lat\n')
end

if isfield(assets,'assets'), assets = assets.assets; end

% create concatenated matrices for inpoly
assets_lonlat  = climada_concatenate_lon_lat(assets.lon, assets.lat);
focus_area_indx = zeros(numel(assets.lon),1);  
polygon_tolerance = 1.0; 

% loop over multiple polygons
for polygon_i = 1:numel(polygon_focus_area)
    polygon_lonlat = []; lon = []; lat = []; %init
    % do we have lon,lat or X,Y data
    if isfield(polygon_focus_area(polygon_i),'lon')
        lon = polygon_focus_area(polygon_i).lon; 
        lat = polygon_focus_area(polygon_i).lat;
    elseif isfield(polygon_focus_area(polygon_i),'X')
        lon = polygon_focus_area(polygon_i).X; 
        lat = polygon_focus_area(polygon_i).Y;
    end
    % create concatenated matrices for inpoly
    polygon_lonlat = climada_concatenate_lon_lat(lon,lat);
     
    if ~isempty(polygon_lonlat)
        nan_position = find(isnan(polygon_lonlat(:,1)));
        if ~isempty(nan_position)
           nan_position = [0; nan_position];
        else
           nan_position = [0 numel(lon)+1];
        end
        % create indx for focus area
        % loop over different segments, divided by nans
        for pos_i = 1:numel(nan_position)-1
           focus_area_indx_temp = inpoly(assets_lonlat,polygon_lonlat(nan_position(pos_i)+1:nan_position(pos_i+1)-1,:),'',polygon_tolerance);
           focus_area_indx = focus_area_indx+focus_area_indx_temp;
        end  

        % create indx for focus area
        %if ~isempty(polygon_lonlat)
        %    focus_area_indx_temp = inpoly(assets_lonlat,polygon_lonlat);
        %    focus_area_indx = focus_area_indx+focus_area_indx_temp;
        %end
    end
    
end

%% cut out relevant data
focus_area_indx    = logical(focus_area_indx);
assets.Value       = assets.Value(focus_area_indx);
assets.lon         = assets.lon(focus_area_indx);
assets.lat         = assets.lat(focus_area_indx);
assets.centroid_index = 1:numel(assets.lat);
assets.comment     = [assets.comment ', value only for focus area'];
assets.focus_area  = polygon_focus_area;
    






    



