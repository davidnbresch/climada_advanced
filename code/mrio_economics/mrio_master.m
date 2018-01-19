% function [subsector_risk, country_risk, leontief_inverse, climada_nan_mriot] = mrio_master(admin0_name, subsector_name, risk_measure) % uncomment to run as function
% mrio master
% MODULE:
%   advanced
% NAME:
%   mrio_master
% PURPOSE:
%   master script to run mrio calculation (multi regional I/O table project)
% CALLING SEQUENCE:
%   mrio_master(country_name, sector_name, risk_measure)
% EXAMPLE:
%   mrio_master('Switzerland', 'Agriculture', 'EAD')
%   mrio_master
% INPUTS:
%  
% OPTIONAL INPUT PARAMETERS:
%   admin0_name: the country name, either full (like 'Puerto Rico')
%       or ISO3 (like 'PRI'). See climada_country_name for names/ISO3
%   subsector_name: the subsector name, see e.g. mrio_read_table
%   risk_measure: the risk measure to be applied (string), default is ='EAD' (Expected Annual Damage)
% OUTPUTS:
%   risk: risk per country and sector based on the risk measure chosen
%   leontief_inverse: the leontief inverse matrix which relates final demand to production
%   climada_nan_mriot: matrix with the value 1 in relations (trade flows) that cannot be accessed
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20171207, initial (under construction)

% import/setup global variables
% global climada_global
% if ~climada_init_vars,return;end
         
% poor man's version to check arguments
if ~exist('risk_measure', 'var'), risk_measure = []; end
%if ~exist('admin0_name', 'var'), country_name = []; end
%if ~exist('subsector_name', 'var'), sector_name = []; end
%if ~exist('silent_mode','var'), silent_mode = 0; end

% PARAMETERS
climada_global.waitbar = 0;
if isempty(risk_measure), risk_measure = 'EAD'; end
params.centroids_file = 'GLB_NatID_grid_0360as_adv_1'; % the global centroids
params.entity_file.agri = 'GLB_0360as_ismip_2018'; % the global Agriculture (agri) entity
params.entity_file.for = 'GLB_0360as_ismip_2018'; % the global Forestry and Fishing (for) entity
params.entity_file.min = 'GLB_0360as_ismip_2018'; % the global Mining and Quarrying (min) entity
params.entity_file.manu = 'GLB_0360as_ismip_2018'; % the global Manufacturing (manu) entity
params.entity_file.serv = 'GLB_0360as_ismip_2018'; % the global Services (serv) entity
params.entity_file.utilities = 'GLB_0360as_ismip_2018'; % the global Electricity, Gas and Water supply (utilities) entity
params.hazard_file = 'GLB_0360as_TC_hist'; % historic
% params.hazard_file='GLB_0360as_TC'; % probabilistic, 10x more events than hist

% read MRIO table
fprintf('Reading MRIO table...\n');tic;
climada_mriot = mrio_read_table;toc

% aggregated MRIO table:
fprintf('Aggregating MRIO table...\n');tic;
aggregated_mriot = mrio_aggregate_table(climada_mriot);toc

% load (TEST) hazard
fprintf('Loading hazard set...\n');tic;
hazard = climada_hazard_load(params.hazard_file);toc

% load centroids and prepare entities for mrio risk estimation 
fprintf('Loading centroids and prepare entities for mrio risk estimation...\n');tic;
entity = mrio_entity_prep(params.entity_file.agri, params.centroids_file, climada_mriot);toc

% calculate direct risk for all countries and sectors as specified in mrio table
fprintf('Calculating direct risk for all countries and sectors as specified in mrio table...\n');tic;
[direct_subsector_risk, direct_country_risk] = mrio_direct_risk_calc(entity, hazard, climada_mriot, aggregated_mriot, risk_measure);toc

% finally, quantifying indirect risk using the Leontief I-O model
fprintf('Quantifying indirect risk using the Leontief I-O model...\n');tic;
[subsector_risk, country_risk] = mrio_leontief_calc(direct_subsector_risk, climada_mriot);toc

% end % mrio_master