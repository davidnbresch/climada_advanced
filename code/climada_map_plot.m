function [input_structure, fig] = climada_map_plot(input_structure,fieldname_to_plot,plot_method,event_no,struct_no)
% Generate a map plot
% MODULE:
%   advanced
% NAME:
%   climada_map_plot
% PURPOSE:
%   create a map, for a selected input structure and a fieldname, i.e.
%   'elevation_m' of centroids, 'Value' of entity.assets, 'intensity' of
%   hazard
% PREVIOUS STEP:
%   multiple
% CALLING SEQUENCE:
%   [input_structure, fig] = climada_map_plot(input_structure,fieldname_to_plot,plot_method,event_no,struct_no)
% EXAMPLE:
%   [input_structure, fig] = climada_map_plot
%   [input_structure, fig] = climada_map_plot(entity,'Value')
%   [input_structure, fig] = climada_map_plot(centroids,{'elevation_m' 'slope_deg'})
%   [input_structure, fig] = climada_map_plot(hazard,'intensity','contourf',7121)
%   [input_structure, fig] = climada_map_plot(EDS,'ED_at_centroid','',1,3) % plot EDS number 3
% INPUTS:
%   input_structure:  a climada stucture, i.e. centroids, entity,
%        entity.assets, hazard, EDS
%   fieldname_to_plot: string or cell, i.e. 'Value', or {'elevation_m' 'slope_deg'}
% OPTIONAL INPUT PARAMETERS:
%   plot_method: a string, default is 'plotclr', can also be 'contourf'
%   event_no: an array, only important to select a specific event for 'intensity'
%   struct_no: an array, only important to select a specific struct,i.e. if EDS holds more than one EDS
% OUTPUTS:
%   input_structure:  a climada stucture, i.e. centroids, entity,
%        entity.assets, hazard, EDS
%   fig: handle on the figure with a map displaying the selected field 
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20151124, init
% -

fig = []; % init

global climada_global
if ~climada_init_vars, return; end

% check arguments
if ~exist('input_structure', 'var'), input_structure = []; end
if ~exist('fieldname_to_plot', 'var'), fieldname_to_plot = []; end
if ~exist('plot_method', 'var'), plot_method = []; end
if ~exist('event_no', 'var'), event_no = []; end
if ~exist('struct_no', 'var'), struct_no = []; end
  
if isempty(plot_method), plot_method = 'plotclr'; end 
if isempty(event_no), event_no = 1; end 
if isempty(struct_no), struct_no = 1; end 

if isempty(input_structure) 
    [input_structure, struct_name] = climada_load; 
    fprintf('You have loaded a %s\n',struct_name);
end 
if isempty(input_structure), fprintf('No structure (centroids, hazard, entity) selected to plot on a map\n'); return, end

% take only first structure if it contains more than one (e.g. EDS)
if numel(input_structure)>1, input_structure = input_structure(struct_no);end

% make sure fieldname_to_plot is a cell
if ischar(fieldname_to_plot) && ~isempty(fieldname_to_plot), fieldname_to_plot = {fieldname_to_plot}; end

if isempty(fieldname_to_plot) || any(ismember(fieldname_to_plot,'ED_at_centroid'))
    
    % special case for EDS, copy EDS.assets.lon into EDS.lon
    if isfield(input_structure,'ED_at_centroid')
        if isfield(input_structure,'assets')
            if isfield(input_structure.assets,'lon') && isfield(input_structure.assets,'lat')
                lon = getfield(input_structure.assets,'lon');
                lat = getfield(input_structure.assets,'lat');
                input_structure = setfield(input_structure,'lon',lon); 
                input_structure = setfield(input_structure,'lat',lat); 
            end
        end
    end
    
    % special case for entity assets
    if isfield(input_structure,'assets') && ~isfield(input_structure,'ED_at_centroid')
        input_structure = getfield(input_structure,'assets'); 
        if isempty(input_structure), return,end
    end
    names = fieldnames(input_structure);
    fieldname_to_plot = {'elevation_m' 'slope_deg' 'TWI' 'intensity' 'Value' 'ED_at_centroid'};
    has_fieldname = ismember(fieldname_to_plot,names);
    if any(has_fieldname)
        % we have found one or more fieldnames to plot
        fieldname_to_plot = fieldname_to_plot(has_fieldname);       
    end
end     

if isempty(fieldname_to_plot), return, end 



% make sure that we have .lon and .lat information
if ~isfield(input_structure,'lon') || ~isfield(input_structure,'lat')
    fprintf('This struct does not have .lon and .lat fields\n')
    return
end
    

% plot centroids characteristics
% -----------
% parameters
% plot_method = 'contour'; %'plotclr';%
% plot_method = 'plotclr'; 
npoints = 2000; plot_centroids = 0;
interp_method = []; stencil_ext = [];
caxis_range = '';

% create figures
% fieldnames_to_plot = {'elevation_m' 'slope_deg' 'TWI' 'aspect_deg'};
% title_strings = {'Elevation (m)' 'Slope (deg)' 'Topographical wetness index' 'Aspect (deg)'};
counter = 0;
for f_i = 1:numel(fieldname_to_plot)
    if isfield(input_structure,fieldname_to_plot{f_i})
        values = full(getfield(input_structure,fieldname_to_plot{f_i}));
        [values_i, values_j] = size(values);
        if values_j>1
            values = values(event_no,:);
        elseif values_i>1
            values = values(:,event_no);
        else
            values = []; % no vector, but only one value, so we cannot plot
        end
        if any(values) || ~isempty(values)
            counter = counter+1;
            % special colormap for hazard intensities
            if strcmp(fieldname_to_plot{f_i},'intensity') && isfield(input_structure,'peril_ID')
                cmap = climada_colormap(input_structure.peril_ID);
            else
                cmap = jet(64);
            end
            %title_str = title_strings{f_i};
            title_str = strrep(fieldname_to_plot{f_i},'_',' ');
            if event_no>1 && struct_no>1
                title_str = sprintf('%s, event %d, struct %d',strrep(fieldname_to_plot{f_i},'_',' '), event_no, struct_no);
            end
            if event_no>1 && struct_no<=1
                title_str = sprintf('%s, event %d',strrep(fieldname_to_plot{f_i},'_',' '), event_no);
            end
            if event_no<=1 && struct_no>1
                title_str = sprintf('%s, struct %d',strrep(fieldname_to_plot{f_i},'_',' '), struct_no);
            end
            fig(counter) = climada_color_plot(values, input_structure.lon, input_structure.lat,fieldname_to_plot{f_i},...
                                title_str,plot_method,interp_method,npoints,plot_centroids,caxis_range,cmap,stencil_ext);
        end
    end
end






