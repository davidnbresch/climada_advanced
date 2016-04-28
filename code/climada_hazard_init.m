function hazard = climada_hazard_init(hazard)
% init hazard structure
% MODULE:
%   climada advanced
% NAME:
%   climada_hazard_init
% PURPOSE:
%   init a climada hazard struct that contains the necessary fields
%   (e.g. .lon, .lat, .intensity etc), or append add the necessary fields
%   to an existing hazard and order fields
% CALLING SEQUENCE:
%   hazard = climada_hazard_init(hazard)
% EXAMPLE:
%   hazard = climada_hazard_init
% INPUTS: none
% OPTIONAL INPUT PARAMETERS:
%   hazard: an existing hazard structure where one wants to add the
%   necessary fields and order the fields
% OUTPUTS:
%   hazard: a climada hazard struct with all the necessary fields
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20160427, init

if ~exist('hazard','var'), hazard = ''; end
if ~isstruct(hazard), clear hazard; hazard.lon = []; end %init as struct

if ~isfield(hazard,'lon'), hazard.lon = []; end
if ~isfield(hazard,'lat'), hazard.lat = []; end
if ~isfield(hazard,'intensity'), hazard.intensity = []; end
if ~isfield(hazard,'frequency'), hazard.frequency = []; end
if ~isfield(hazard,'centroid_ID'), hazard.centroid_ID = ''; end
if ~isfield(hazard,'peril_ID'), hazard.peril_ID = ''; end
if ~isfield(hazard,'units'), hazard.units = ''; end
if ~isfield(hazard,'event_count'), hazard.event_count = []; end
if ~isfield(hazard,'orig_event_count'), hazard.orig_event_count = []; end
if ~isfield(hazard,'event_ID'), hazard.event_ID = []; end
if ~isfield(hazard,'orig_event_flag'), hazard.orig_event_flag = []; end
if ~isfield(hazard,'datenum'), hazard.datenum = []; end
if ~isfield(hazard,'reference_year'), hazard.reference_year = []; end
if ~isfield(hazard,'filename'), hazard.filename = ''; end
if ~isfield(hazard,'comment'), hazard.comment = ''; end
% if ~isfield(hazard,'yyyy'), hazard.yyyy = []; end
% if ~isfield(hazard,'mm'), hazard.mm = []; end
% if ~isfield(hazard,'dd'), hazard.dd = []; end

% order fields in hazard struct
names = fieldnames(hazard);
given_order = {'lon','lat','intensity','frequency','centroid_ID','peril_ID','units','event_count','orig_event_count','event_ID','orig_event_flag','datenum','reference_year','filename','comment'};
additional_name = ~ismember(names,given_order);
all_names = {given_order{:} names{additional_name}};
hazard = orderfields(hazard,all_names);

