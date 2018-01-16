function direct_mainsector_risk = mrio_direct_risk_calc(entity, hazard, climada_mriot, risk_measure) % uncomment to run as function
% mrio direct risk ralc
% MODULE:
%   advanced
% NAME:
%   mrio_direct_risk_calc
% PURPOSE:
%   Caculate direct risk per mainsector and country given an encoded entity (assets and damage functions), 
%   a hazard event set, a risk measure and a general climada MRIO table.
%
%   NOTE: see PARAMETERS in code
%
%   previous call: 
%   climada_mriot = mrio_read_table;
%   entity = mrio_entity_prep(climada_mriot);
%   hazard = climada_hazard_load;
%   next call:  % just to illustrate
%   [risk, leontief_inverse, climada_nan_mriot] = mrio_leontief_calc(climada_mriot, direct_mainsector_risk);
% CALLING SEQUENCE:
%   direct_mainsector_risk = mrio_direct_risk_calc(entity, hazard, climada_mriot);
% EXAMPLE:
%   climada_mriot = mrio_read_table;
%   entity = mrio_entity_prep(climada_mriot);
%   hazard = climada_hazard_load;
%   direct_mainsector_risk = mrio_direct_risk_calc(entity, hazard, climada_mriot);
% INPUTS:
%   entity: a struct, see climada_entity_read for details
%   hazard: a struct, see e.g. climada_tc_hazard_set
%   climada_mriot: a structure with ten fields. It represents a general climada
%   mriot structure whose basic properties are the same regardless of the
%   provided mriot it is based on, see climada_read_mriot;
% OPTIONAL INPUT PARAMETERS:
%   risk_measure: risk measure to be applied (string), default is the Expected Annual Damage (EAD)
% OUTPUTS:
%   direct_mainsector_risk: the direct risk per country based on the given risk measure 
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20180115, initial
%-

direct_mainsector_risk = []; % init output

global climada_global
if ~climada_init_vars, return; end % init/import global variables

% poor man's version to check arguments
if ~exist('entity', 'var'), entity = []; end 
if ~exist('hazard', 'var'), hazard = []; end 
if ~exist('climada_mriot', 'var'), climada_mriot = []; end
if ~exist('risk_measure', 'var'), risk_measure = []; end

% locate the module's data folder (here  one folder
% below of the current folder, i.e. in the same level as code folder)
% module_data_dir = [climada_global.modules_dir filesep 'climada_advanced' filesep 'data']; 

% PARAMETERS
if isempty(hazard), hazard = climada_hazard_load; end
if isempty(climada_mriot), climada_mriot = mrio_read_table; end
if isempty(risk_measure), risk_measure = 'EAD'; end

countries_ISO3 = entity.assets.NatID_RegID.ISO3; % TO DO: entity lösung finden 
mrio_countries_ISO3 = unique(aggregated_mriot.countries_iso, 'stable');

n_mainsectors = length(categories(climada_mriot.climada_sect_name));
n_mrio_countries = length(mrio_countries_ISO3);

for mainsector_i = 1:n_mainsectors
    
    % load centroids and prepare entities for mrio risk estimation 
    % entity = mrio_entity_prep(climada_mriot); % at the moment we are not differentiating between sectors (!!!)

    % calculation for all countries as specified in mrio table
    for mrio_country_i = 1:n_mrio_countries

        country_ISO3 = mrio_countries_ISO3(mrio_country_i); % extract ISO code

        if country_ISO3 ~= 'ROW' 
            country_NatID = find(ismember(countries_ISO3, country_ISO3)); % extract NatID
            sel_assets = eq(ismember(entity.assets.NatID, country_NatID),~isnan(entity.assets.Value)); % select all non-NaN assets of this country
        else % 'Rest of World' (ROW) is viewed as a country 
            list_RoW_ISO3 = setdiff(countries_ISO3, mrio_countries_ISO3); % find all countries that are not individually listed in the MRIO table 
            list_RoW_NatID = find(ismember(countries_ISO3, list_RoW_ISO3)); % extract NatID
            sel_assets = eq(ismember(entity.assets.NatID, list_RoW_NatID),~isnan(entity.assets.Value)); % select all non-NaN RoW assets
        end

        entity_sel = entity;
        entity_sel.assets.Value = entity.assets.Value .* sel_assets;  % set values = 0 for all assets outside country i.

        % calculate event damage set
        EDS = climada_EDS_calc(entity_sel,hazard,'' ,'' ,2 ,'');

        % Calculate Damage exceedence Frequency Curve (DFC)
        % DFC = climada_EDS_DFC(EDS);

        % convert an event (per occurrence) damage set (EDS) into a year damage set (YDS)
        YDS = climada_EDS2YDS(EDS, hazard);

        % quantify risk with specified risk measure 
        switch risk_measure
            case 'EAD' % Expected Annual Damage
                direct_mainsector_risk(mainsector_i+n_mainsectors*(mrio_country_i-1)) = YDS.ED;
            case '100y-event' % TO DO 
                return_period = 100;
                sort_damages = sort(YDS.damage);
                sel_pos = max(find(DFC.return_period >= return_period));
                direct_mainsector_risk(mainsector_i+n_mainsectors*(mrio_country_i-1)) = DFC.damage(sel_pos);
            case '50y-event' % TO DO 
                return_period = 50;
                sort_damages = sort(YDS.damage);
                sel_pos = max(find(DFC.return_period >= return_period));
                direct_mainsector_risk(mainsector_i+n_mainsectors*(mrio_country_i-1)) = DFC.damage(sel_pos);
            case '20y-event' % TO DO 
                return_period = 20;
                sort_damages = sort(YDS.damage);
                sel_pos = max(find(DFC.return_period >= return_period));
                direct_mainsector_risk(mainsector_i+n_mainsectors*(mrio_country_i-1)) = DFC.damage(sel_pos);
            case 'worst-case' % TO DO 
                sel_pos = max(find(DFC.return_period));
                direct_mainsector_risk(mainsector_i+n_mainsectors*(mrio_country_i-1)) = DFC.damage(sel_pos);
            otherwise
                % TO DO
        end % switch risk_measure
        
    end % mrio_country_i
    
end % mainsector_i

end % mrio_direct_risk_calc