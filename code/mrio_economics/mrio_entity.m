function entity=mrio_entity(params)
% mrio entity
% MODULE:
%   advanced
% NAME:
%   mrio_entity
% PURPOSE:
%   load centroids and prepare entities for mrio (multi resolution I/O table project)
%
%   NOTE: see PARAMETERS in code
%
%   previous call: see isimip_gdp_entity to generate the global centroids and entity
%   next call: <note the most usual next function call here>
% CALLING SEQUENCE:
%   entity=mrio_entity(params)
% EXAMPLE:
%   entity=mrio_entity(params)
% INPUTS:
%   params: a structure with the fields
%       plot_centroids: =1 to plot the centroids, =0 not (default)
%       plot_entity: =1 to plot the entity, =0 not (default)
% OPTIONAL INPUT PARAMETERS:
%   param2: as an example
% OUTPUTS:
%   res: the output, empty if not successful
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20171206, initial
%-

entity=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('params','var'),params=struct;end % in case we want to pass all parameters as structure

% locate the module's (or this code's) data folder (usually  a folder
% 'parallel' to the code folder, i.e. in the same level as code folder)
module_data_dir=[fileparts(fileparts(mfilename('fullpath'))) filesep 'data'];

% PARAMETERS
%
% define all parameters here - no parameters to be defined in code below
%
% the global centroids
centroids_file='GLB_NatID_grid_0360as_adv_1';
%
% the global entity
entity_file='GLB_0360as_ismip_2018';

% the (TEST) hazard
hazard_file='GLB_0360as_TC_hist'; % historic
%hazard_file='GLB_0360as_TC'; % probabilistic, 10x more events than hist


% setup structure to pass all parameters:
if isstruct(params)
    if ~isfield(params,'plot_centroids'),params.plot_centroids=[];end
    if ~isfield(params,'plot_entity'),params.plot_entity=[];end
end

% set defaults
if isempty(params.plot_centroids),params.plot_centroids=0;end
if isempty(params.plot_centroids),params.plot_entity=0;end

% load global centroids
centroids=climada_centroids_load(centroids_file);

if params.plot_centroids % plot the centroids
    figure('Name','centroids');
    country_pos=(centroids.centroid_ID<3e6); % find high(er) resolution centroids within countries
    plot(centroids.lon(country_pos),centroids.lat(country_pos),'.g');hold on;
    grid_pos=(centroids.centroid_ID>=3e6); % find coarse resolution centroids for regular grid
    plot(centroids.lon(grid_pos),centroids.lat(grid_pos),'.r','MarkerSize',.1)
    climada_plot_world_borders
    legend({'country centroids [10km]','grid centroids [100km]'})
    title('GLB NatID grid 0360as adv 1')
end % params.plot_centroids

% load global entity
entity=climada_entity_load(entity_file);

if params.plot_entity % plot the centroids
    figure('Name','entity');
    climada_entity_plot(entity);
end % params.plot_entity

% load tropical cyclone hazard set
hazard=climada_hazard_load(hazard_file);

% calculate the event damage set (EDS) to check whether all fine
%EDS=climada_EDS_calc(entity,hazard);

end % mrio_entity