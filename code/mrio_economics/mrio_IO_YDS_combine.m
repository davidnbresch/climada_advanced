function [IO_YDS, STATUS] = mrio_IO_YDS_combine(IO_YDS, IO_YDS2, params)
% mrio IO YDS combine
% MODULE:
%   advanced
% NAME:
%   mrio_IO_YDS_combine
% PURPOSE:
%   Combine two climada Input-Output year damage sets (IO_YDS), i.e. add
%   damages. 
%
%   Note that ONLY damages are added, we do NOT add Values, as most 
%   often the sub-peril is on the same asset base. Hence edit the resulting 
%   IO_YDS yourself in case Value should be additive.
%
%   previous steps: 
%       mrio_direct_risk_calc and mrio_leontief_calc
%   next step: 
% CALLING SEQUENCE:
%   IO_YDS = mrio_IO_YDS_combine(IO_YDS,IO_YDS2)
% EXAMPLE:
%   IO_YDS = mrio_IO_YDS_combine(IO_YDS,IO_YDS2)
% INPUTS:
%   IO_YDS, the Input-Output year damage set, a struct with the fields:
%       direct, a struct itself with the field
%           ED: the total expected annual damage
%           reference_year: the year the damages are references to
%           yyyy(i): the year i
%           damage(year_i): the damage amount for year_i (summed up over all
%               assets and events)
%           Value: the sum of all Values used in the calculation (to e.g.
%               express damages in percentage of total Value)
%           frequency(i): the annual frequency, =1
%           orig_year_flag(i): =1 if year i is an original year, =0 else
%       indirect, a struct itself with the field
%           ED: the total expected annual damage
%           reference_year: the year the damages are references to
%           yyyy(i): the year i
%           damage(year_i): the damage amount for year_i (summed up over all
%               assets and events)
%           Value: the sum of all Values used in the calculation (to e.g.
%               express damages in percentage of total Value)
%           frequency(i): the annual frequency, =1
%           orig_year_flag(i): =1 if year i is an original year, =0 else
%       If IO_YDS is empty on input, IO_YDS2 is returned. This can be
%       useful to start summing up entities in a loop
%       IO_YDS_c = climada_IO_YDS_combine(IO_YDS_c, IO_YDS)...  
%   IO_YDS2: an Input-Output year damage set (see above)
% OPTIONAL INPUT PARAMETERS:
%   params: a structure with the fields            
%       verbose: whether we printf progress to stdout (=1, default) or not (=0)
% OUTPUTS:
%   IO_YDS, the combined Input-Output year damage set, a struct with the fields:
%       direct, a struct itself with the field
%           ED: the total expected annual damage
%           reference_year: the year the damages are references to
%           yyyy(i): the year i
%           damage(year_i): the damage amount for year_i (summed up over all
%               assets and events)
%           Value: the sum of all Values used in the calculation (to e.g.
%               express damages in percentage of total Value)
%           frequency(i): the annual frequency, =1
%           orig_year_flag(i): =1 if year i is an original year, =0 else
%       indirect, a struct itself with the field
%           ED: the total expected annual damage
%           reference_year: the year the damages are references to
%           yyyy(i): the year i
%           damage(year_i): the damage amount for year_i (summed up over all
%               assets and events)
%           Value: the sum of all Values used in the calculation (to e.g.
%               express damages in percentage of total Value)
%           frequency(i): the annual frequency, =1
%           orig_year_flag(i): =1 if year i is an original year, =0 else
%   STATUS: =1 if combination successful, =0 otherwise, also if the basic
%       combination worked (same length of damage vector), but some issues
%       with either reference_year or frequency occurred. 
%       In some instances, it might still be justified to use the
%       combined IO_YDS, even if ok = 0 upon return.
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20180620, initial
%-

STATUS = 0; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('IO_YDS','var'), IO_YDS = []; end
if ~exist('IO_YDS2','var'), IO_YDS2 = []; end
if ~exist('params','var'), params = struct; end

% PARAMETERS
if ~isfield(params,'verbose'), params.verbose = 1; end
if isempty(IO_YDS) && ~isempty(IO_YDS2) % special case to add start adding up with an empty one to start with
    IO_YDS = IO_YDS2;
    IO_YDS2 = [];
end

if length(IO_YDS)>1 % a bit of analysis of IO_YDS
    damage_length = zeros(1,length(IO_YDS)); % init
    for IO_YDS_i = 1:length(IO_YDS)
        damage_length(IO_YDS_i) = size(IO_YDS(IO_YDS_i).direct.damage,1);
    end % IO_YDS_i
    
    % we now call climada_IO_YDS_combine for all IO_YDSs with the same length of
    % IO_YDS(i).direct.damage
    unique_damage_length = unique(damage_length);
    pos_vect = 1:length(damage_length); % init
    IO_YDS_STATUS = ones(1,length(damage_length)); % init
    for unique_i = 1:length(unique_damage_length)
        % find all IO_YDSs with same damage vector length (all other checks happen below)
        ismember_i = ismember(damage_length,unique_damage_length(unique_i));
        ismember_i = pos_vect(ismember_i); % convert boolean to index
        for member_i = 2:length(ismember_i) % more than one with same length
            if params.verbose
                fprintf('combining %i (%s) and %i (%s)\n',...
                ismember_i(1),       IO_YDS(ismember_i(1)).hazard.peril_ID,...
                ismember_i(member_i),IO_YDS(ismember_i(member_i)).hazard.peril_ID);
            end
            % kind of recursively calling climada_IO_YDS_combine
            [IO_YDS_one,comb_STATUS] = climada_IO_YDS_combine(IO_YDS(ismember_i(1)),IO_YDS(ismember_i(member_i)));
            if comb_STATUS
                IO_YDS(ismember_i(1)) = IO_YDS_one;
                IO_YDS_STATUS(ismember_i(member_i)) = 0; % mark the added one
            end
        end % member_i
    end % unique_i
    IO_YDS = IO_YDS(logical(IO_YDS_STATUS)); % keep only non-touched and combined ones
end % length(IO_YDS)>1

if isempty(IO_YDS2)
    return % all done with IO_YDS
elseif length(IO_YDS2)>1
    % just add to IO_YDS, then call climada_IO_YDS_combine for the full IO_YDS again
    IO_YDS = [IO_YDS IO_YDS2];
    if params.verbose, fprintf('more than one IO_YDS in IO_YDS2 - recursion\n'); end
    IO_YDS = climada_IO_YDS_combine(IO_YDS);
    return
end

% by now, IO_YDS and IO_YDS2 should be one IO_YDS each
if length(IO_YDS)>1 || length(IO_YDS2)>1
    fprintf('ERROR: more than one IO_YDS in IO_YDS2 (after recursion, should not occurr ;-)\n');
    return
end

if length(IO_YDS.direct.damage)==length(IO_YDS2.direct.damage) && length(IO_YDS.indirect.damage)==length(IO_YDS2.indirect.damage)
    IO_YDS.direct.damage = IO_YDS.direct.damage + IO_YDS2.direct.damage;
    IO_YDS.indirect.damage = IO_YDS.indirect.damage + IO_YDS2.indirect.damage;
    % Note: do NOT add IO_YDS.(in)direct.Value, as most often the sub-peril is on the same asset base
    IO_YDS.comment = sprintf('combined %s & %s',char(IO_YDS.hazard.peril_ID),char(IO_YDS2.hazard.peril_ID));
    IO_YDS.direct.annotation_name = [IO_YDS.direct.annotation_name ' & ' IO_YDS2.direct.annotation_name];
    IO_YDS.indirect.annotation_name = [IO_YDS.indirect.annotation_name ' & ' IO_YDS2.indirect.annotation_name];
    IO_YDS.direct.ED = mean(IO_YDS.direct.damage,1); % re-calculate ED
    IO_YDS.indirect.ED = mean(IO_YDS.indirect.damage,1); % re-calculate ED
    STATUS = 1;
    
    % consistency checks
    
    if abs(IO_YDS2.direct.reference_year-IO_YDS.direct.reference_year)>0
        IO_YDS.direct.reference_year = max(IO_YDS2.direct.reference_year,IO_YDS.direct.reference_year);
        fprintf('Warning: reference_year, latest taken: %g\n',IO_YDS.reference_year);
        STATUS = 0;
    end
    
    if sum(IO_YDS2.direct.frequency-IO_YDS.direct.frequency)>0
        fprintf('Severe warning: frequency does not match, IO_YDS taken\n');
        STATUS = 0;
    end
    
else
    fprintf('ERROR: IO_YDS.direct.damage or IO_YDS.indirect.damage length does not match, nothing added\n');
    STATUS = 0;
end

end % mrio_IO_YDS_combine