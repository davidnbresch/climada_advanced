function climada_hazard2xls(hazard, hazard_xls_file)
% climada hazard save in xls
% MODULE:
%   advanced
% NAME:
%   climada_hazard2xls
% PURPOSE:
%   Save hazard as xls file
% CALLING SEQUENCE:
%   climada_hazard2xls(hazard, hazard_xls_file)
% EXAMPLE:
%   climada_hazard2xls(hazard)
% INPUTS:
%   hazard: hazard strucure to write out in excel file
%   hazard_xls_file: the filename of the Excel file to be written
% OUTPUTS:
%   excel file
% MODIFICATION HISTORY:
% Lea Mueller, muellele@gmail.com, 20160308, init
%-

global climada_global
if ~climada_init_vars,return;end % init/import global variables

% poor man's version to check arguments
if ~exist('hazard', 'var'), hazard = []; end
if ~exist('hazard_xls_file', 'var'), hazard_xls_file = [];end
warning off MATLAB:xlswrite:AddSheet

% prompt for entity_file if not given
hazard = climada_hazard_load(hazard);

% prompt for entity_file if not given
if isempty(hazard_xls_file) % local GUI
    hazard_xls_file = [climada_global.data_dir filesep 'hazards' filesep 'hazard_out.xls'];
    [filename, pathname] = uiputfile(hazard_xls_file, 'Save hazard as:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        hazard_xls_file = fullfile(pathname,filename);
    end
end

% check if number of assets smaller than excel limit
[pathstr,name,ext] = fileparts(hazard_xls_file);
if strcmp(ext,'.xls')
    xls_row_limit = 65536;
    if isfield(hazard,'lon')
        if length(hazard.lon)>xls_row_limit 
            fprintf('\t\t ERROR: The number of lon/lat in the hazard structure (%d) exceed the number of rows in excel (.xls). (%d)\n \t\t Try .xlsx format.\n',length(hazard.lon),xls_row_limit)
            return
        end
    end
end

fprintf('Save hazard as excel-file\n')


% all other fields directly in hazard
fprintf('\t\t - All other fields sheet\n')
fields_2 =  fieldnames(hazard);
counter  = 0;
matr     = cell(100,5); % a wild guess
for row_i = 1:length(fields_2)
    if ~strcmp(fields_2{row_i},'intensity') && ~strcmp(fields_2{row_i},'intensity_orig')
        if isnumeric(hazard.(fields_2{row_i})) && numel(hazard.(fields_2{row_i})) > 0
            counter = counter+1;
            matr{1,counter} = fields_2{row_i};
            values = full(hazard.(fields_2{row_i}))'; [a,b] = size(values); 
            if a>1 && b>1, values = values(:,1); end
            matr(2:numel(values)+1,counter) = num2cell(values);
        elseif ischar(hazard.(fields_2{row_i})) || iscell(hazard.(fields_2{row_i}))
            counter = counter+1;
            matr{1,counter} = fields_2{row_i};
            values = hazard.(fields_2{row_i}); %[a,b] = size(values); 
            %if a>1 && b>1, values = values(:,1); end
            %fields_2{row_i}
            %values
            if ischar(values), values = {values}; end
            matr(2:numel(values)+1,counter) = values;
        end
    end
end
xlswrite(hazard_xls_file, matr, 'others')


% intensity in hazard
if isfield(hazard,'intensity')
    fprintf('\t\t - Intensity sheet\n')
    matr = cell(100,5); % a wild guess
    matr{1,1} = sprintf('Intensity (%s)', hazard.units);
    values = full(hazard.intensity);
    [a,b] = size(values);
    matr(2:a+1,1:b) = num2cell(values);
    xlswrite(hazard_xls_file, matr, 'intensity')
end


fprintf('\t\t Save hazard as xls file\n')
cprintf([113 198 113]/255,'\t\t %s\n',hazard_xls_file);


end

