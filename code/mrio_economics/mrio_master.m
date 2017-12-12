%function [,]=mrio_master(country_name,sector_name) % uncomment to run as function
% mrio master
% MODULE:
%   advanced
% NAME:
%   mrio_master
% PURPOSE:
%   master script to run mrio calculation (multi regional I/O table project)
%
%   NOTE: see PARAMETERS in code
%
% CALLING SEQUENCE:
%
% EXAMPLE:
%
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
%
% OUTPUTS:
%
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20171207, in construction
%-

%global climada_global

% read MRIO table
climada_read_mriot;

%%for sector=1:6

% load centroids and prepare entities for mrio
[entity,hazard]=mrio_entity;
entity_temp = entity;

% calculate event damage set
EDS=climada_EDS_calc(entity,hazard);

% Calculate Damage exceedence Frequency Curve (DFC)
DFC = climada_EDS_DFC(EDS);

% convert an event (per occurrence) damage set (EDS) into a year damage set (YDS)
YDS = climada_EDS2YDS(EDS,hazard);

% Annual Average Loss per Country
ED_in_country = accumarray(transpose(entity.assets.NatID),YDS.ED_at_centroid);


%%%%%%%%%% in construction 
X = []; x = [];
Y = sort(YDS.damage(YDS.damage > 0));
numOfIt = length(Y);

% 100y-event can be obtained through fitted pareto distribution
for i=1:numOfIt
    X(i) = (numOfIt+1)/sum(Y >= Y(i));
    x(i) = 1/X(i);
end

% fit a pareto distribution
[Param] = gpfit([Y,x]);
%%%%%%%%%%%

%end

%[centroids entity polygon] = climada_cut_out_GDP_entity(entity, centroids, 'USA')
% encode assets to new centroids
%entity.assets = climada_assets_encode(entity.assets,centroids);

%climada_entity_production_adjust
%

% nonzero_pos=find(EDS.ED_at_centroid>(10*eps));
%    if ~isempty(nonzero_pos)
%        nonzero_damage=EDS.ED_at_centroid(nonzero_pos);
%        YDS_ED=sum(YDS.damage)/n_years;
%        EDS_ED=EDS.frequency*EDS.damage';
%        YDS.damage=YDS.damage/YDS_ED*EDS_ED;
%    end % ~isempty(nonzero_pos)
    
 