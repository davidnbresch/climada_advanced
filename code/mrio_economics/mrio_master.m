%function [,] = mrio_master(country_name, sector_name, risk_measure) % uncomment to run as function
% mrio master
% MODULE:
%   advanced
% NAME:
%   mrio_master
% PURPOSE:
%   master script to run mrio calculation (multi regional I/O table project)
% CALLING SEQUENCE:
%   mrio_master(country_name, sector_name)
% EXAMPLE:
%   mrio_master('Switzerland','Agriculture','EAD')
% INPUTS:
%   country_name: name of country (string)
%   sector_name: name of sector (string)
% OPTIONAL INPUT PARAMETERS:
%   risk_measure: risk measure to be applied (string), default is the Expected Annual Damage (EAD)
% OUTPUTS:
%
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20171207, initial (under construction)
% Kaspar Tobler, 20180105, added line to obtain aggregated mriot using function climada_aggregate_mriot
% Kaspar Tobler, 20180105, added some notes/questions; see "Note KT".

% import/setup global variables
%global climada_global
%if ~climada_init_vars,return;end

climada_global.waitbar = 0;

% PARAMETERS
%           
if ~exist('risk_measure', 'var'), risk_measure = []; end
if isempty(risk_measure),risk_measure = 'EAD'; end

% read MRIO table
climada_mriot = climada_read_mriot;

% proceed with aggregated numbers / rough sector classification
climada_aggregated_mriot = climada_aggregate_mriot(climada_mriot);

% load centroids and prepare entities for mrio risk estimation 
% Note KT: once separate entity for each climada sector is ready, probably
%   first get [~,hazard] separately as this is the same for every sector
%   and then obtain the 6 entities with the above loop so as to avoid
%   multiple loadings of the hazard. (?)
[entity] = mrio_entity(climada_mriot);

% the (TEST) hazard
hazard_file = 'GLB_0360as_TC_hist'; % historic
%hazard_file='GLB_0360as_TC'; % probabilistic, 10x more events than hist
hazard = climada_hazard_load(hazard_file);

% calculate direct risk for all countries and sectors as specified in mrio table
[direct_risk] = mrio_direct_risk_calc(entity, hazard, climada_mriot)

% disaggregate direct risk to all subsectors for each country
% climada_disaggregate_risk(....)   Not finished building yet.

%country_risk_direct = cumsum(risk_direct);

% Finally, quantifying indirect risk using the Leontief I-O model
[risk] = mrio_leontief_calc(climada_mriot, risk_direct)