function direct_mainsector_risk = mrio_direct_risk_calc(entity, hazard, climada_mriot) % uncomment to run as function
% mrio direct risk ralc
% MODULE:
%   advanced
% NAME:
%   mrio_direct_risk_calc
% PURPOSE:
%   Caculate direct risk per sector and country given an encoded entity (assets and damage functions), 
%   a hazard event set, a risk measure and a general climada MRIO table.
%
%   NOTE: see PARAMETERS in code
%
%   previous call: 
%   climada_mriot = climada_read_mriot;
%   entity = mrio_entity(climada_mriot);
%   hazard = climada_hazard_load;
%   next call:  % just to illustrate
%   [risk, leontief_inverse, climada_nan_mriot] = mrio_leontief_calc(climada_mriot, risk_direct);
% CALLING SEQUENCE:
%   direct_mainsector_risk = mrio_direct_risk_calc(entity, hazard, climada_mriot);
% EXAMPLE:
%   climada_read_mriot;
%   entity = mrio_entity(climada_mriot);
%   hazard = climada_hazard_load;
%   direct_mainsector_risk = mrio_direct_risk_calc(entity, hazard, climada_mriot);
% INPUTS:
%   entity: a struct, see climada_entity_read for details
%   hazard: a struct, see e.g. climada_tc_hazard_set
%   climada_mriot: a structure with ten fields. It represents a general climada
%   mriot structure whose basic properties are the same regardless of the
%   provided mriot it is based on, see climada_read_mriot;
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   direct_mainsector_risk: the direct risk per country based on the given risk measure 
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20180115, initial
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

country_ISO3 = entity.assets.NatID_RegID.ISO3;
mrio_country_ISO3 = unique(climada_aggregated_mriot.countries_iso);

% calculation for all countries as specified in mrio table
for i = 1:length(mrio_country_ISO3)
    
    % for sector = 1:climada_aggregated_mriot.no_of_sectors (here to have same structure as in mrio)
    
    % entity = mrio_entity(climada_mriot);
    
    country = mrio_country_ISO3(i); % extract ISO code

    if country ~= 'ROW' 
        sel_country_pos = find(ismember(country_ISO3, country)); 
        sel_assets = eq(ismember(entity.assets.NatID,sel_country_pos),~isnan(entity.assets.Value)); % select all non-NaN assets of this country
    else % 'Rest of World' (RoW) is viewed as a country 
        list_RoW_ISO3 = setdiff(country_ISO3,mrio_country_ISO3); % find all countries that are not individually listed in the MRIO table 
        list_RoW_NatID = find(ismember(country_ISO3,list_RoW_ISO3)); % extract NatID
        sel_assets = eq(ismember(entity.assets.NatID,list_RoW_NatID),~isnan(entity.assets.Value)); % select all non-NaN RoW assets
    end
    
    entity_sel = entity;
    entity_sel.assets.Value = entity.assets.Value .* sel_assets;  % set values = 0 for all assets outside country i.
    
    % calculate event damage set
    EDS = climada_EDS_calc(entity_sel,hazard,'','',2,'');
    
    % Calculate Damage exceedence Frequency Curve (DFC)
    DFC = climada_EDS_DFC(EDS);
    
    % convert an event (per occurrence) damage set (EDS) into a year damage set (YDS)
    YDS = climada_EDS2YDS(EDS,hazard);
    
    % quantify risk with specified risk measure 
    switch risk_measure
        case 'EAD' % Expected Annual Damage
            direct_mainsector_risk(i) = YDS.ED;
        case '100y-event' %
            return_period = 100;
            sort_damages = sort(YDS.damage);
            sel_pos = max(find(DFC.return_period >= return_period));
            direct_mainsector_risk(i) = DFC.damage(sel_pos);
        case '50y-event' %
            return_period = 50;
            sort_damages = sort(YDS.damage);
            sel_pos = max(find(DFC.return_period >= return_period));
            direct_mainsector_risk(i) = DFC.damage(sel_pos);
        case '20y-event' %
            return_period = 20;
            sort_damages = sort(YDS.damage);
            sel_pos = max(find(DFC.return_period >= return_period));
            direct_mainsector_risk(i) = DFC.damage(sel_pos);
        case 'worst-case' %
            sel_pos = max(find(DFC.return_period));
            direct_mainsector_risk(i) = DFC.damage(sel_pos);
        otherwise
            % ask user to choose out of a list and return to beginning of switch statement
    end
    %end
end

end % mrio_direct_risk_calc