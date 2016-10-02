function res=climada_entity_plot_all
% climada template
% MODULE:
%   module name
% NAME:
%   climada_entity_plot_all
% PURPOSE:
%   plot ALL entities in the current entity folder, does take some time...
%
%   usually rather use: climada_entity_plot
% CALLING SEQUENCE:
%   res=climada_entity_plot_all
% EXAMPLE:
%   climada_entity_plot_all;
% INPUTS:
% OPTIONAL INPUT PARAMETERS:
% OUTPUTS:
%   res: the output, empty if not successful
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20161001
%-

res=[]; % init output

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% PARAMETERS
%
nplots_hor=5;nplots_ver=3;
figure_Position=[22 14 1869 1081];

entity_files=dir(climada_global.entities_dir);

figure('Name','all entities','Position',figure_Position);next_plot=1;
fprintf('plotting approx. %i entities (skipping non-entities in %s)\n',length(entity_files),climada_global.entities_dir);
for file_i=1:length(entity_files)
    if ~entity_files(file_i).isdir
        [~,entity_filename,fE]=fileparts(entity_files(file_i).name);
        if ~isempty(entity_filename) && isempty(strfind(entity_filename,'_future')) && strcmpi(fE,'.mat')
            if isentity(entity)
                fprintf('%s\n',entity_filename);
                subplot(nplots_ver,nplots_hor,next_plot);
                climada_entity_plot(entity_filename,[],1);
                title(strrep(entity_filename,'_',' '));
                next_plot=next_plot+1;
                if next_plot>nplots_hor*nplots_ver,figure('Name','all entities','Position',figure_Position);next_plot=1;end
            end % isentity(entity)
        end % ~isempty(entity_filename) && isempty(strfind(entity_filename,'_future'))
    end % not isdir
end % file_i

end % climada_entity_plot_all