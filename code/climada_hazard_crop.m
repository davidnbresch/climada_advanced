function hazard = climada_hazard_crop(hazard,polygon_focus_area)
% climada_hazard_crop
% MODULE:
%   advanced
% NAME:
%   climada_hazard_crop
% PURPOSE:
%   Reduce hazard to focus only on a given area. Very useful for large hazards, 
%   that contain gridded information and only a speficic area is need. 
%   Usually this is the case after climada_asci2hazard.m. 
% CALLING SEQUENCE:
%   hazard = climada_hazard_crop(hazard, polygon_focus_area)
% EXAMPLE:
%   hazard = climada_hazard_crop(hazard, polygon_focus_area)
% INPUTS: 
%   hazard            : a climada hazard structure
%   polygon_focus_area: structure with polygon coordinate information in fields
%                       .lon and .lat, or .X and .Y that define the focus
%                       area, can be multiple polygon_focus_area(2) or more
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:      
%   hazard            : a climada hazard structure, with .lon, .lat and .intensity,
%                        where all coordinates are within ghe given polygon focus area.
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150724, init
% Lea Mueller, muellele@gmail.com, 20151106, move to advanced
% Lea Mueller, muellele@gmail.com, 20151125, rename to climada_hazard_crop from climada_hazard_focus_area
% Lea Mueller, muellele@gmail.com, 20160224, enable for multiple polygons
% Lea Mueller, muellele@gmail.com, 20160314, loop over segments divided by nans
%-


global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('hazard','var'),hazard = []; end
if ~exist('polygon_focus_area','var'),polygon_focus_area=[];end

if isempty(hazard),climada_hazard_load; end
if isempty(polygon_focus_area)
    fprintf('Please specify focus area, with focus_area.lon and focus_area.lat\n')
end

% create concatenated matrices for inpoly
hazard_lonlat  = climada_concatenate_lon_lat(hazard.lon, hazard.lat);
focus_area_indx = zeros(numel(hazard.lon),1);  
polygon_tolerance = 1.0; 

% loop over multiple polygons
for polygon_i = 1:numel(polygon_focus_area)
    polygon_lonlat = []; %init
    % do we have lon,lat or X,Y data
    if isfield(polygon_focus_area(polygon_i),'lon')
        lon = polygon_focus_area(polygon_i).lon; 
        lat = polygon_focus_area(polygon_i).lat;
    elseif isfield(polygon_focus_area(polygon_i),'X')
        lon = polygon_focus_area(polygon_i).X; 
        lat = polygon_focus_area(polygon_i).Y;
    end
    % make sure there are non nans in the polgyon_focus_area
    %lon(isnan(lon) = []; lat(isnan(lat) = [];   
    
    % create concatenated matrices for inpoly
    polygon_lonlat = climada_concatenate_lon_lat(lon, lat);
      
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
           focus_area_indx_temp = inpoly(hazard_lonlat,polygon_lonlat(nan_position(pos_i)+1:nan_position(pos_i+1)-1,:),'',polygon_tolerance);
           focus_area_indx = focus_area_indx+focus_area_indx_temp;
        end   

        %focus_area_indx_temp = inpoly(hazard_lonlat,polygon_lonlat,'',polygon_tolerance);
        %focus_area_indx = focus_area_indx+focus_area_indx_temp;
    end 
    
    
end

%% cut out relevant data
focus_area_indx = logical(focus_area_indx);
hazard.lon         = hazard.lon(focus_area_indx);
hazard.lat         = hazard.lat(focus_area_indx);
hazard.centroid_ID = 1:numel(hazard.lat);
hazard.intensity   = hazard.intensity(:,focus_area_indx);
hazard.comment     = [hazard.comment ', value only for focus area'];
hazard.focus_area  = polygon_focus_area;
    






    



