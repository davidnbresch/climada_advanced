function dfs = mrio_generate_damagefunctions(damagefunctions,v_thresh,v_half,scaling,check_plot)
% mrio generate damagefunctions
% MODULE:
%   advanced
% NAME:
%   mrio_generate_damagefunctions
% PURPOSE:
%   Generate damagefunctions for default use in the tropcial cyclone mrio risk modeling
%   process. Damagefunctions are based on the formula proposed in 
%
%   Emanuel, K., 2011: 
%   Global Warming Effects on U.S. Hurricane Damage. 
%   Wea. Climate Soc., 3, 261–268, 
%   https://doi.org/10.1175/WCAS-D-11-00007.1
%
%   Although the resulting value is then multiplied with a further scaling
%   parameter. The function is typically not called by a user but integrated into 
%   the modeling process. There, it's usually called twice, once for a df for the
%   north-west pacific, once for the rest of the world, with distinct parameter 
%   sets, respectively.
%
%   A damagefunctions struct has to be passed and is returned. Also works if an 
%   entire entity is passed, in which case the functions updates the entity's 
%   damagefunctions field.
%
%   NOTE: per default, mrio-process TC damagefunctions have all PAA=1 which is 
%   for now the only possibility. Might be extended to allow user-defined PAA values.
% CALLING SEQUENCE:
%   dfs = mrio_generate_damagefunctions(damagefunctions,v_thresh,v_half,scaling,check_plot);
% EXAMPLE:
%   [entity.damagefunctions] = mrio_generate_damagefunctions(entity.damagefunctions,25,61,0.6)  -- call with user-defined v_threshold, v_half and scaling. 
% INPUTS:
%    damagefunctions: a damagefunctions field (itself a struct) of an entity. Function works also if an
%       entire entity is passed, in which case the damagefunctions field is
%       extracted and the full entity is returned, with the updated damagefunctions.
% OPTIONAL INPUT PARAMETERS:
%   v_thresh: a value for the v_threshold parameter of the underlying
%       Emanuel (2011) function. Default is 25.
%   v_half: a value for the v_half parameter of the underlying Emanuel
%       (2011) function. Default is 61.
%   scaling: value for the scaling used. If not passed, user is prompted for.
%   check_plot: =1 to show a check plot (using
%       climada_damagefunction_plot) or not (=0, default)
%       plots on the same plot on subsequent calls to allow for easy
%       comparison of say two options
% OUTPUTS:
%   damagefunction: a structure with
%       filename: just for information, here 'mrio_generate_damagefunctions'
%       Intensity(i): the hazard intensity (a vector)
%       DamageFunID(i): 1 for all, as default
%       peril_ID{i}: a cell array with peril_ID, here 'TC'
%       MDD(i): the mean damage degree value for Intensity(i)
%       PAA(i): the percentage of affected assets for Intensity(i), here 1
%           for all intensities.
% MODIFICATION HISTORY:
% Kaspar Tobler, 20180520, first version
%-

dfs = []; % init output

% load climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('damagefunctions', 'var'), error('You need to provide either a damagefunctions structure of an entity or an entity itself for the function to work. Please try again.'); end
if ~exist('v_thresh', 'var'), v_thresh = []; end
if ~exist('v_half', 'var'), v_half = []; end
if ~exist('scaling', 'var'), scaling = []; end
if ~exist('check_plot', 'var'), check_plot = []; end

% PARAMETERS
if ismember({'damagefunctions';'measures';'assets'}, fieldnames(damagefunctions))
    is_entity = true;
    damagefunctions = damagefunctions.damagefunctions;
else
    is_entity = false;
end
if isempty(v_thresh), v_thresh = 25; end
if isempty(v_half), v_half = 61; end
if isempty(scaling)
    [sel, ok] = listdlg('ListString',{'Default RoW','Default North-West Pacific'},'SelectionMode','single','PromptString',...
            'Choose which default scaling parameter you would like to use:','ListSize',[300 100]);
        if ~ok 
            warning('No scaling parameter chosen. We set 0.64 which is default for all regions except north-west Pacific.');
            scaling = 0.64;
        else
            switch sel
                case 1
                    scaling = 0.64;
                case 2
                    scaling = 0.08;
            end
        end
end
if isempty(check_plot), check_plot = 0; end

intensities = 0:5:120;
damagefunctions.Intensity = intensities; 
damagefunctions.MDD = zeros(1,length(intensities));  
damagefunctions.PAA = ones(1,length(intensities));
damagefunctions.name = repmat({'Tropical cyclone mrio'},1,length(intensities));
damagefunctions.DamageFunID = ones(1,length(intensities));
damagefunctions.Intensity_unit = damagefunctions.Intensity_unit(1:length(intensities));
damagefunctions.peril_ID = repmat({'TC'},1,length(intensities));
damagefunctions.datenum = damagefunctions.datenum(1:length(intensities));
                    
%%%

% Not ideal since only works for default entity!
% Create function handle to local function which contains key formula (see below):
df_fun = @df_localfun;
% Set respective MDD value for all corresponding intensities.
damagefunctions.MDD = arrayfun(df_fun,intensities);  
% Scale with scaling factor:
damagefunctions.MDD = damagefunctions.MDD .* scaling;

if is_entity
    entity.damagefunctions = damagefunctions;
    dfs = entity;
else
    dfs = damagefunctions;
end %is_entity

if check_plot, climada_damagefunctions_plot(damagefunctions); end

function df = df_localfun(intensity)  % Local function of the actual Emanuel (2013) formula; intensity is wind speed.
   v_n = max([intensity - v_thresh,0])/(v_half - v_thresh);
   df = v_n^3/(1 + v_n^3); 
end % % df_localfun

end % mrio_generate_damagefunctions