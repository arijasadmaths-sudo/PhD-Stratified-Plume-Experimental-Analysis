function selectedFiles = image_saver(sourceFolder, destinationFolder, firstIndex, stride, lastIndex, operation)
%IMAGE_SAVER Copy or move selected TIFF files from an existing image sequence.
%   selectedFiles = image_saver(sourceFolder, destinationFolder, ...
%       firstIndex, stride, lastIndex, operation)
%
%   Files are sorted alphabetically by filename, ignoring case. Indices refer
%   to this order, so use zero-padded filenames if they contain frame numbers.
%   Both .tif and .tiff files are included. Selection is firstIndex:stride:lastIndex.
%
%   lastIndex defaults to the last TIFF file. operation defaults to 'copy';
%   use 'move' explicitly to remove the selected files from the source folder.
%   Existing destination files are never intentionally overwritten.
%   selectedFiles is a column cell array containing the selected filenames.

    narginchk(4, 6);
    sourceFolder = folderText(sourceFolder, 'sourceFolder');
    destinationFolder = folderText(destinationFolder, 'destinationFolder');
    if ~isfolder(sourceFolder)
        error('image_saver:MissingSource', 'The source folder does not exist.');
    end
    validateattributes(firstIndex, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'integer', 'positive'}, mfilename, 'firstIndex');
    validateattributes(stride, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'integer', 'positive'}, mfilename, 'stride');

    if nargin < 6 || isempty(operation)
        operation = 'copy';
    end
    if isstring(operation) && isscalar(operation)
        operation = char(operation);
    end
    if ~ischar(operation) || ~isrow(operation) || ...
            ~any(strcmpi(operation, {'copy', 'move'}))
        error('image_saver:Operation', 'operation must be ''copy'' or ''move''.');
    end
    operation = lower(operation);

    % Collect the sequence before creating the destination folder.
    files = dir(sourceFolder);
    files = files(~[files.isdir]);
    names = {files.name};
    isTiff = ~cellfun('isempty', regexpi(names, '\.tiff?$'));
    names = names(isTiff);
    lowerNames = cellfun(@lower, names, 'UniformOutput', false);
    [~, order] = sort(lowerNames);
    names = names(order);
    if isempty(names)
        error('image_saver:NoImages', 'The source folder contains no TIFF files.');
    end

    if nargin < 5 || isempty(lastIndex)
        lastIndex = numel(names);
    end
    validateattributes(lastIndex, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'integer', 'positive'}, mfilename, 'lastIndex');
    if firstIndex > lastIndex || lastIndex > numel(names)
        error('image_saver:IndexRange', ...
            'Require firstIndex <= lastIndex <= the number of TIFF files (%d).', numel(names));
    end
    selectedFiles = names(firstIndex:stride:lastIndex).';

    % Check every destination before copying or moving any files.
    if exist(destinationFolder, 'file') && ~isfolder(destinationFolder)
        error('image_saver:InvalidDestination', ...
            'The destination path exists and is not a folder.');
    end
    for k = 1:numel(selectedFiles)
        destinationFile = fullfile(destinationFolder, selectedFiles{k});
        rejectExisting(destinationFile);
    end
    if ~isfolder(destinationFolder)
        [ok, message] = mkdir(destinationFolder);
        if ~ok
            error('image_saver:CreateFolder', '%s', message);
        end
    end

    for k = 1:numel(selectedFiles)
        sourceFile = fullfile(sourceFolder, selectedFiles{k});
        destinationFile = fullfile(destinationFolder, selectedFiles{k});
        rejectExisting(destinationFile);
        if strcmp(operation, 'move')
            [ok, message] = movefile(sourceFile, destinationFile);
        else
            [ok, message] = copyfile(sourceFile, destinationFile);
        end
        if ~ok
            error('image_saver:TransferFailed', ...
                'Could not %s "%s": %s. Earlier files may already have been transferred.', ...
                operation, selectedFiles{k}, message);
        end
    end
end

function value = folderText(value, name)
    if isstring(value) && isscalar(value)
        value = char(value);
    end
    if ~ischar(value) || ~isrow(value) || isempty(strtrim(value))
        error('image_saver:FolderInput', '%s must be a non-empty folder path.', name);
    end
end

function rejectExisting(path)
    if exist(path, 'file') || isfolder(path)
        error('image_saver:DestinationExists', ...
            'The destination already exists: %s. No overwrite is allowed.', path);
    end
end
