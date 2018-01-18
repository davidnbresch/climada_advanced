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
if isempty(risk_measure), risk_measure = 'EAD'; end
climada_global.waitbar = 0;
hazard_file = 'GLB_0360as_TC_hist'; % historic
% hazard_file='GLB_0360as_TC'; % probabilistic, 10x more events than hist

% read MRIO table
fprintf('Reading MRIO table...\n');tic;
climada_mriot = mrio_read_table;toc

% aggregated MRIO table:
fprintf('Aggregating MRIO table...\n');tic;
aggregated_mriot = mrio_aggregate_table(climada_mriot);toc

% load (TEST) hazard
fprintf('Loading hazard set...\n');tic;
hazard = climada_hazard_load(hazard_file);toc

% load centroids and prepare entities for mrio risk estimation 
fprintf('Loading centroids and prepare entities for mrio risk estimation...\n');tic;
entity = mrio_entity_prep(climada_mriot);toc

% calculate direct risk for all countries and sectors as specified in mrio table
fprintf('Calculating direct risk for all countries and sectors as specified in mrio table...\n');tic;
direct_mainsector_risk = mrio_direct_risk_calc(entity, hazard, climada_mriot, risk_measure);toc

% disaggregate direct risk to all subsectors for each country
fprintf('Disaggregate direct risk to all subsectors for each country...\n');tic;
[direct_subsector_risk, direct_country_risk] = mrio_disaggregate_risk(direct_mainsector_risk, climada_mriot, aggregated_mriot);toc

% finally, quantifying indirect risk using the Leontief I-O model
fprintf('Quantifying indirect risk using the Leontief I-O model...\n');tic;
[subsector_risk, country_risk] = mrio_leontief_calc(direct_subsector_risk, climada_mriot);toc

% end % mrio_master