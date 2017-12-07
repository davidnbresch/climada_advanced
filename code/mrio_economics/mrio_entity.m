function [entity,hazard]=mrio_entity(params) % uncomment to run as function
% mrio entity
% MODULE:
%   advanced
% NAME:
%   mrio_entity
% PURPOSE:
%   load centroids and prepare entities for mrio (multi regional I/O table project)
%
%   NOTE: see PARAMETERS in code
%
%   previous call: see isimip_gdp_entity to generate the global centroids and entity
%   next call: EDS=climada_EDS_calc(entity,hazard); % just to illustrate
% CALLING SEQUENCE:
%   [entity,hazard]=mrio_entity(params)
% EXAMPLE:
%   [entity,hazard]=mrio_entity;
%   params.plot_centroids=1;params.plot_entity=1;
%   [entity,hazard]=mrio_entity(params)
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%   params: a structure with the fields
%       plot_centroids: =1 to plot the centroids, =0 not (default)
%       plot_entity: =1 to plot the entity, =0 not (default)
% OUTPUTS:
%   entity: the global entity
%   hazard: the global historic TC hazard set
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20171206, initial
% Ediz Herms, ediz.herms@outlook.com, 20171207, normalize assets per country
%-

entity=[]; % init output
hazard=[]; % init output

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('params','var'),params=struct;end % in case we want to pass all parameters as structure

% locate the module's (or this code's) data folder (usually  a folder
% 'parallel' to the code folder, i.e. in the same level as code folder)
%module_data_dir=[fileparts(fileparts(mfilename('fullpath'))) filesep 'data'];

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
fprintf('loading centroids %s\n',centroids_file);
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
fprintf('loading entity %s\n',entity_file);
entity=climada_entity_load(entity_file);

% loop over countries
for country=unique(entity.assets.NatID)
    % select all non-NaN entities in a country
    sel_pos = intersect(find(entity.assets.NatID==country),find(~isnan(entity.assets.Value)));
    % normalize assets
    entity.assets.Value(sel_pos) = entity.assets.Value(sel_pos)/sum(entity.assets.Value(sel_pos));
end
        
if params.plot_entity % plot the centroids
    figure('Name','entity');
    climada_entity_plot(entity);
end % params.plot_entity

% load tropical cyclone hazard set
fprintf('loading hazard %s\n',hazard_file);
hazard=climada_hazard_load(hazard_file);

% calculate the event damage set (EDS) to check whether all fine
%EDS=climada_EDS_calc(entity,hazard);

end % mrio_entity