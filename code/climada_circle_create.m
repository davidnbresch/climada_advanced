function circle = climada_circle_create(center_lon,center_lat,radius_deg,check_plot)
% climada create circle polygon
% MODULE:
%   climada advanced
% NAME:
%   climada_circle_create
% PURPOSE:
%   Create a circe polygon (circle.lon, .lat) based on a given center (lon,
%   lat) and radius_deg. Hint: 1° is roughly 100km.
% CALLING SEQUENCE:
%   circle = climada_circle_create(center_lon,center_lat,radius_deg)
% EXAMPLE:
%   circle = climada_circle_create(115,23,0.1)
% INPUTS:
%   center_lon: longitude of center point
%   center_lat: latitude of center point
%   radius_km: radius in km of circle
% OPTIONAL INPUT PARAMETERS:
%   check_plot: set to 1 to show a plot
% OUTPUTS:
%   circle: a struct with fields .lon, .lat, .center_lon, .center.lat and .radius_deg
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20160509, init
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('center_lon','var'),center_lon = []; end
if ~exist('center_lat','var'),center_lat = []; end
if ~exist('radius_deg','var'),radius_deg = []; end
if ~exist('check_plot','var'),check_plot = []; end

% locate the module's (or this code's) data folder (usually  afolder
% 'parallel' to the code folder, i.e. in the same level as code folder)
% module_data_dir=[fileparts(fileparts(mfilename('fullpath'))) filesep 'data'];

% PARAMETERS
% define all parameters here - no parameters to be defined in code below
% set default value for param2 if not given
if isempty(center_lon), return; end
if isempty(center_lat), return; end
if isempty(radius_deg), return; end
if isempty(check_plot), check_plot = 0; end

n_circles = numel(center_lon);
if numel(center_lon) ~= numel(center_lat), return, end
if numel(center_lon)>1 && numel(radius_deg)==1, radius_deg = ones(n_circles,1)*radius_deg; end

th = 0:pi/50:2*pi;

for c_i = 1:n_circles
    % create circle structure
    circle(c_i).lon = radius_deg(c_i) * cos(th) + center_lon(c_i);
    circle(c_i).lat = radius_deg(c_i) * sin(th) + center_lat(c_i);
    circle(c_i).center_lon = center_lon(c_i);
    circle(c_i).center_lat = center_lat(c_i);
    circle(c_i).radius_deg = radius_deg(c_i);
end

if check_plot
    climada_shapeplotter(circle)
end





