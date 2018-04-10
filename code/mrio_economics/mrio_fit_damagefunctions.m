function [damagefunctions,dmf_info_str] = mrio_fit_damagefunctions(reference_points,intensity,dmf_min_intens,dmf_max,dmf_shape,peril_ID,check_plot,dmf_max_intens)
% mrio fit damagefunction
% MODULE:
%   advanced
% NAME:
%   mrio_fit_damagefunctions
% PURPOSE:
%   fit damagefunction to the reference_points with the damagefunction
%   shape specified in dmf_shape
%
%   See also: climada_damagefunctions_map and _plot ...
% CALLING SEQUENCE:
%   [damagefunctions,dmf_info_str] = mrio_fit_damagefunctions(reference_points,intensity,dmf_min_intens,dmf_max,dmf_shape,peril_ID,check_plot,dmf_max_intens)
% EXAMPLE:
%   [damagefunctions,dmf_info_str] = mrio_fit_damagefunctions([],[],20,1,'lognormal','TC',1)
% INPUTS:
%   reference_points: reference points (x,y) to be used to fit the 
%       damagefunctions.  Any vector of intensities, ascending in value, 
%       such as 1:10:100, and the corresponding damage ratio observed or
%       provided by a survey of experts
%   intensity: the hazard intensity scale, i.e. the horizontal axis of the
%       damage function. Any vector of intensities, ascending in value,
%       such as 1:10:100
%   dmf_min_intens: minimum intensity for MDD and PPA >0, default=0
%   dmf_max: the maximum value of MDD (and PAA), default=1
%   dmf_shape: the shape of the damage function, implemented is 'lognormal'
%   peril_ID: the 2-digit peril_ID, such as 'TC','EQ',...
% OPTIONAL INPUT PARAMETERS:
%   check_plot: =1 to show a check plot (using
%       climada_damagefunction_plot) or not (=0, default)
%       plots on the same plot on subsequent calls to allow for easy
%       comparison of say two options
%   dmf_max_intens: minimum intensity for MDD and PPA, set
%       MDD(intensity>dmf_max_intens) = max(damagefunctions.MDR)
% OUTPUTS:
%   damagefunction: a structure with
%       filename: just for information, here 'climada_damagefunctions_generate'
%       Intensity(i): the hazard intensity (a vector)
%       DamageFunID(i): =ones(1,length(Intensity)
%       peril_ID{i}: a cell array with peril_ID
%       MDD(i): the mean damage degree value for Intensity(i)
%       PAA(i): the percentage of affected assets for Intensity(i)
%   dmf_info_str: the parameters returned as a string (e.g. for annotation)
% MODIFICATION HISTORY:
% Ediz Herms, ediz.herms@outlook.com, 20180403, initial
%-

damagefunctions = []; % init output
dmf_info_str = ''; % init output

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
% and to set default value where  appropriate
if ~exist('reference_points', 'var'), reference_points = []; end
if ~exist('intensity', 'var'), intensity = []; end
if ~exist('dmf_min_intens', 'var'), dmf_min_intens = []; end
if ~exist('dmf_max', 'var'), dmf_max = []; end
if ~exist('dmf_shape', 'var'), dmf_shape = ''; end
if ~exist('peril_ID', 'var'), peril_ID = ''; end
if ~exist('check_plot', 'var'), check_plot = []; end
if ~exist('dmf_max_intens', 'var'), dmf_max_intens = []; end

% PARAMETERS
%
% define all default parameters
if isempty(reference_points), reference_points = [00 0; 10 0; 20 0; 30 .01; 40 0.1; 50 .2; 70 .5; 120 1]; end
if isempty(intensity), intensity = 0:10:120; end
if isempty(dmf_min_intens), dmf_min_intens=20; end
if isempty(dmf_max), dmf_max = 1; end
if isempty(dmf_shape), dmf_shape = 'lognormal'; end
if isempty(peril_ID), peril_ID = 'TC'; end
if isempty(check_plot), check_plot = 1; end
if isempty(dmf_max_intens), dmf_max_intens = max(intensity); end

dmf_info_str = sprintf('%s %s %3.3f*(i-%i)',peril_ID,dmf_shape,dmf_max,dmf_min_intens);

if size(intensity,1) < size(intensity,2), intensity=intensity'; end

damagefunctions.filename = mfilename;
damagefunctions.Intensity = intensity;
damagefunctions.DamageFunID = damagefunctions.Intensity*0+1;
damagefunctions.peril_ID = cellstr(repmat(peril_ID,length(damagefunctions.Intensity),1));

intensity_tmp = damagefunctions.Intensity(damagefunctions.Intensity <= dmf_max_intens);

switch dmf_shape
    case 'lognormal'
        % log-nomal damage function
        rfr_x = reference_points(:,1);
        rfr_y = reference_points(:,2);
        lognormal_func = @ (fit,xdata) logncdf(xdata, fit(1), fit(2));
        fit = lsqcurvefit(lognormal_func, [4 0.3], rfr_x, rfr_y);
        damagefunctions.MDD = logncdf(intensity_tmp,fit(1),fit(2));
        damagefunctions.PAA = damagefunctions.Intensity*0+1;
    otherwise
        fprintf('Error: %s not implemented yet\n',dmf_shape)
        return
end % switch dmf_shape

% fill upper part
damagefunctions.MDD(damagefunctions.Intensity>dmf_max_intens) = max(damagefunctions.MDD);
damagefunctions.PAA(damagefunctions.Intensity>dmf_max_intens) = max(damagefunctions.PAA);

if check_plot, climada_damagefunctions_plot(damagefunctions); end

end % mrio_fit_damagefunctions