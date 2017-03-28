function features = readKaldiFeaturesBatch(filename)
% READKALDIFEATURESBATCH Reads a set of features in Kaldi format, pay attention
% to the memory size of your machine. 
% Or you can use the other function named "readKaldiFeaturesIter" 
%
% features=readkaldifeaturesBatch(filename)
%
% Inputs:
% filename: Feature filename in kaldi format, i.e. ark:feats.ark or
% scp:feats.scp
% 
% Output:
% features: a cell with a size of f x 2, f is the file number
% the first column is the file ID, the second column is a matrix of
% features with size nf x dim, where nf is the number of frames, dim is the
% dimension of features
%
% If you use this software in a publication, please cite
% 
% 
    % checking input arguments
    C = strsplit(filename, ':');
    if length(C) ~= 2
        error(['Input file name (%s) is not in kaldi format (ark:feats.ark ' ...
            'or scp:feats.scp), please check it.'], filename);
    end
    
    if ~strcmp(C{1}, 'ark') && ~strcmp(C{1}, 'scp')
        error(['Input file name (%s) is not in kaldi format (ark:feats.ark ' ...
            'or scp:feats.scp), please check it.'], filename);
    end
    
    kaldi_feats = C{2};
    if ~exist(kaldi_feats, 'file')
        error('Input file (%s) do not exist, please check it.', kaldi_feats);
    end
    
    features = {}; f = 1;
    if strcmp(C{1}, 'ark')
        ark_handle = fopen(kaldi_feats, 'rb');
        while ~feof(ark_handle)
            utt_id = '';
            c = fread(ark_handle, 1, 'uint8=>char');
            if isempty(c)
                break;
            end
            while c ~= ' '
                utt_id = [utt_id c];
                c = fread(ark_handle, 1, 'uint8=>char'); 
            end
            position = ftell(ark_handle);
            [utt_mat, ark_handle] = readKaldiFeatureArk(ark_handle, position);
            features{f, 1} = utt_id;
            features{f, 2} = utt_mat;
            f = f + 1;
        end
        fclose(ark_handle);
    else
        scp_handle = fopen(kaldi_feats, 'r');
        while ~feof(scp_handle)
            line = fgetl(scp_handle);
            if strcmp(line, '')
                continue;
            end
            S = strsplit(line, ' ');
            if length(S) ~= 2
                error(['Line "(%s)" is not in kaldi format in scp file (%s),' ...
                    'please check it.'], line, kaldi_feats);
            end
            utt_id = S{1};
            SS = strsplit(S{2}, ':');
            if length(SS) ~= 2
                error(['Line "(%s)" is not in kaldi format in scp file (%s),' ...
                    'please check it.'], line, kaldi_feats);
            end
            ark_file = SS{1};
            position = str2num(SS{2});
            if ~exist(ark_file, 'file')
                error('Ark file (%s) do not exist, please check it.', ark_file);
            end
            ark_handle = fopen(ark_file, 'rb'); 
            utt_mat = readKaldiFeatureArk(ark_handle, position);
            if utt_mat == -1
                error('Ark file (%s) is not in kaldi format, please check it.', ark_file);
            end
            fclose(ark_handle);
            features{f, 1} = utt_id;
            features{f, 2} = utt_mat;
            f = f + 1;
        end
        fclose(scp_handle);
    end
end

function [utt_mat, ark_handle] = readKaldiFeatureArk(ark_handle, position)
    fseek(ark_handle, position, 'bof');
    ark_head = fread(ark_handle, 5, 'uint8=>char');
    binary = ark_head(2);
    if binary == 'B'
        MV = ark_head(4);
        if MV == 'M'
            fseek(ark_handle, 1, 'cof');
            rows = fread(ark_handle, 1, 'int32');
            fseek(ark_handle, 1, 'cof');
            cols = fread(ark_handle, 1, 'int32');
            tmp_mat = fread(ark_handle, rows * cols, 'float32');
            utt_mat = reshape(tmp_mat, cols, rows)';
        elseif MV == 'V'
            fseek(ark_handle, 1, 'cof');
            rows = fread(ark_handle, 1, 'int32');
            utt_mat = fread(ark_handle, rows, 'float32');
        else
            utt_mat = -1;
            return;
        end
    else
        fseek(ark_handle, position, 'bof');
        line{1} = strstrip(fgetl(ark_handle));
        if line{1}(end) == '['
            line{1} = strstrip(fgetl(ark_handle));
            while line{end}(end) ~= ']'
                line{end+1} = strstrip(fgetl(ark_handle));
            end
            line{end} = strrep(line{end}, ' ]', '');
        else
            line{1} = strrep(line{1}, '[', '');
            line{1} = strrep(line{1}, ']', '');
        end
        rows = length(line);
        cols = length(strsplit(line{1}, ' '));
        utt_mat = zeros(rows, cols);
        for i = 1 : rows
            utt_mat(i, :) = str2double(strsplit(line{i}, ' '));
        end
    end
end

function str = strstrip(str)
    str = regexprep(str, '^ *', '');
    str = regexprep(str, ' *$', '');
end
