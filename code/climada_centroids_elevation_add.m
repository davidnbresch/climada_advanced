function centroids = climada_centroids_elevation_add(centroids,centroids_rectangle,check_plot)
% climada 
% NAME:
%   climada_centroids_elevation_add
% PURPOSE:
%   add elevation to given centroids or create centroids given a rectangle of
%   lon/lat. Uses SRTM data (90 m digitial elevation data, climada module dem)
% CALLING SEQUENCE:
%   centroids = climada_centroids_elevation_add(centroids,centroids_rectangle)
% EXAMPLE:
%   centroids = climada_centroids_elevation_add;
%   centroids = climada_centroids_elevation_add(centroids);
%   centroids = climada_centroids_elevation_add('',[-89.15 -89.1 13.695 13.73]);
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   centroids: climada centroids with lon,lat but not elevation_m info
%   centroids_rectangle: rectangle that indicates the area where centroids
%          should be created (on a 90 m resolution, as given by SRTM) 
%          including elevation_m field
%   if both inputs are empty, the user can choose a country and define a
%   rectangle area in a figure
%   check_plot: =1, do show check plot 
% OUTPUTS:
%   centroids: a climada centroids structure with fields
%       .lon, .lat, .elevation_m for elevation in meters
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20151123, init
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('centroids','var'),centroids = []; end
if ~exist('centroids_rectangle','var'),centroids_rectangle = []; end
if ~exist('check_plot','var'),check_plot = 0; end

% PARAMETERS

%init
SRTM = [];

% option 1)
% we have a climada centroids structure as input, where we want to add
% elevation data
if isstruct(centroids) && isempty(centroids_rectangle)
    if ~isfield(centroids,'elevation_m')
        % get elevation data
        buffer = 0.01/2; %0.01 deg equals 1000m, so we have a buffer of 500 m
        centroids_rect = [min(centroids.lon)-buffer max(centroids.lon)+buffer...
                          min(centroids.lat)-buffer max(centroids.lat)+buffer];
        SRTM = climada_srtm_get(centroids_rect);
        % append elevation data to given centroids
        centroids.elevation_m = interp2(SRTM.x,SRTM.y,SRTM.h, centroids.lon,centroids.lat);
        
        %F_DEM = scatteredInterpolant(lon_crop,lat_crop,elev_crop);
        %centroids.elevation_m = F_DEM(centroids.lon',centroids.lat')';
        SRTM = []; % reset to empty
    end
end

% option 2)
% we have a box that indicate the limits of lon/lat of centroids
if isempty(centroids) && isnumeric(centroids_rectangle) && numel(centroids_rectangle) == 4
    % get elevation data for the required area
    SRTM = climada_srtm_get(centroids_rectangle,0,0);
end

% option 3)
% we dont have anyhting given, so we create a plot for the user to
% define the area
if isempty(centroids) && isempty(centroids_rectangle)
    close all
    fprintf('Please select a country a draw a rectangle for the region you are interested in\n')
    SRTM = climada_srtm_get('',1,0);
    shape = climada_shape_selector(1,1);
    centroids_rectangle = [min(shape.X) max(shape.X) min(shape.Y) max(shape.Y)];
    SRTM = climada_srtm_get(centroids_rectangle,1,0);
end

% for option 2 and 3
% create centroids from elevation data
if isempty(centroids) && ~isempty(SRTM)
    centroids.lon = SRTM.x(:)';
    centroids.lat = SRTM.y(:)';
    centroids.elevation_m = SRTM.h(:)';
    centroids.centroid_ID = 1:numel(centroids.lon);
    centroids.onLand = ones(size(centroids.lon));
    centroids.comment = 'Created from SRTM 90m DEM';
    centroids.sourcefile = SRTM.filename;
    centroids.filename = 'Created from SRTM 90m DEM';
end


if check_plot
    figure('Name','centroids with elevation data','Color',[1 1 1]);
    [X, Y]        = meshgrid(unique(centroids.lon),unique(centroids.lat));
    gridded_VALUE = griddata(centroids.lon,centroids.lat,centroids.elevation_m,X,Y);
    %contourf(X, Y, gridded_VALUE,'edgecolor','none')
    imagesc([min(centroids.lon) max(centroids.lon)], [min(centroids.lat) max(centroids.lat)], gridded_VALUE)
    set(gca,'YDir','normal')
    hold on
    colorbar
    axis equal
    climada_plot_world_borders
    axis([min(centroids.lon(:)) max(centroids.lon(:)) min(centroids.lat(:)) max(centroids.lat(:))]);
    %climada_figure_axis_limits_equal_for_lat_lon([min(SRTM.x(:)) max(SRTM.x(:)) min(SRTM.y(:)) max(SRTM.y(:))])
    climada_figure_scale_add
end
 

