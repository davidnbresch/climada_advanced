%function [,] = mrio_master(country_name,sector_name,risk_measure) % uncomment to run as function
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
%-

%global climada_global

% read MRIO table
climada_mriot = climada_read_mriot;

% proceed with aggregated numbers

risk_direct = zeros(0,climada_mriot.no_of_sectors*climada_mriot.no_of_countries);
country_risk_direct = zeros(0,climada_mriot.no_of_countries);

% load centroids and prepare entities for mrio risk estimation 
[entity,hazard] = mrio_entity(climada_mriot);

country_ISO3 = entity.assets.NatID_RegID.ISO3; % above list is too fine-grided for our purpose (e.g. treats Hawaii as own country)
mrio_country_ISO3 = unique(climada_mriot.countries_iso);

% calculation for all countries as specified in mrio table
for i = 1:length(mrio_country_ISO3)
    
    % for sector = 1:climada_mriot.no_of_sectors (here to have same structure as in mrio)
    
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
            risk_direct(i) = YDS.ED;
        case '100y-event' %
            return_period = 100;
            sort_damages = sort(YDS.damage);
            sel_pos = max(find(DFC.return_period >= return_period));
            risk_direct(i) = DFC.damage(sel_pos);
        case '50y-event' %
            return_period = 50;
            sort_damages = sort(YDS.damage);
            sel_pos = max(find(DFC.return_period >= return_period));
            risk_direct(i) = DFC.damage(sel_pos);
        case '20y-event' %
            return_period = 20;
            sort_damages = sort(YDS.damage);
            sel_pos = max(find(DFC.return_period >= return_period));
            risk_direct(i) = DFC.damage(sel_pos);
        case 'worst-case' %
            sel_pos = max(find(DFC.return_period));
            risk_direct(i) = DFC.damage(sel_pos);
        otherwise
            % ask user to choose out of a list and return to beginning of switch statement
    end
    %end
end

% disaggregate direct risk to all subsectors for each country

%country_risk_direct = cumsum(risk_direct);

% estimation of indirect risk using Leontief I/O model 
[risk] = mrio_leontief_calc(climada_mriot, risk_direct)