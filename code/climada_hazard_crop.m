function hazard = climada_hazard_crop(hazard, polygon_focus_area)
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
%                       .lon and .lat, that define the focus area
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:      
%   hazard            : a climada hazard structure, with .lon, .lat and .intensity,
%                        where all coordinates are within ghe given polygon focus area.
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20150724, init
% Lea Mueller, muellele@gmail.com, 20151106, move to advanced
% Lea Mueller, muellele@gmail.com, 20151125, rename to climada_hazard_crop from climada_hazard_focus_area
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
polygon_lonlat = climada_concatenate_lon_lat(polygon_focus_area.lon, polygon_focus_area.lat);

% create indx for focus area
focus_area_indx = inpoly(hazard_lonlat,polygon_lonlat);


%% cut out relevant data
hazard.lon         = hazard.lon(focus_area_indx);
hazard.lat         = hazard.lat(focus_area_indx);
hazard.centroid_ID = 1:numel(hazard.lat);
hazard.intensity   = hazard.intensity(:,focus_area_indx);
hazard.comment     = [hazard.comment ', value only for focus area'];
hazard.focus_area  = polygon_focus_area;





    



