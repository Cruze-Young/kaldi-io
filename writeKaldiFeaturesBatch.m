function stats = writeKaldiFeaturesBatch(filename, features)
% WRITEKALDIFEATURESBATCH Writes a set of features in Kaldi format
% Or you can use the other function named "writeKaldiFeaturesIter" 
%
% features=readkaldifeaturesBatch(filename)
%
% Inputs:
% filename: Feature filename in kaldi format, i.e. ark:feats.ark '
% 'ark,t:feats.ark or ark,scp:feats.ark,feats.scp
%
% features: A cell with a size of f x 2, where f is the number of files.
% The first column is the file ID, the second column is a matrix of
% features with size nf x dim, where nf is the number of frames, dim is the
% dimension of features
% 
% Output:
% stats: writing stats, 0 means success, otherwise may appear errors
%
% If you use this software in a publication, please cite
% 
% 

    % checking input arguments
    stats = 0;
    C = strsplit(filename, ':');
    if length(C) ~= 2
        error(['Input file name (%s) is not in kaldi format (for example: ark:feats.ark ' ...
            'ark,t:feats.ark or scp:feats.scp), please check it.'], filename);
    end
    
    T = strsplit(C{1}, ',');
    for t = 1 : length(T)
        if ~strcmp(T{t}, 'ark') && ~strcmp(T{t}, 'scp') && ~strcmp(T{t}, 't')
            error(['Input file name (%s) is not in kaldi format (for example: ark:feats.ark ' ...
                 'ark,t:feats.ark or ark,scp:feats.ark,feats.scp), please check it.'], filename);
        end
    end
    
    kaldi_feats = C{2};
    if isempty(strfind(C{1}, 'scp')) % only ark file need to be write
        ark_file = kaldi_feats;
        if isempty(strfind(C{1}, 't')) % write in binary mode
            ark_handle = fopen(ark_file, 'wb');
            for f = 1 : size(features, 1)
                utt_id = features{f, 1};
                utt_mat = features{f, 2};
                fwrite(ark_handle, [utt_id ' '], 'char*1');
                ark_handle = writeKaldiFeatureArk(ark_handle, utt_mat, 1);
            end
        else % write in readable mode
            ark_handle = fopen(ark_file, 'w');
            for f = 1 : size(features, 1)
                utt_id = features{f, 1};
                utt_mat = features{f, 2};
                fwrite(ark_handle, [utt_id ' '], 'char*1');
                ark_handle = writeKaldiFeatureArk(ark_handle, utt_mat, 0);
            end
        end
        fclose(ark_handle);
    else % only ark and scp files need to be write
        F = strsplit(kaldi_feats, ',');
        ark_file = F{1};
        scp_file = F{2};
        if isempty(strfind(C{1}, 't')) % write in binary mode
            ark_handle = fopen(ark_file, 'wb');
            scp_handle = fopen(scp_file, 'w');
            for f = 1 : size(features, 1)
                utt_id = features{f, 1};
                utt_mat = features{f, 2};
                fwrite(ark_handle, [utt_id ' '], 'char*1');
                position = ftell(ark_handle);
                ark_handle = writeKaldiFeatureArk(ark_handle, utt_mat, 1);
                fprintf(scp_handle, '%s %s:%d\n', utt_id, ark_file, position); 
            end
        else % write in readable mode
            ark_handle = fopen(ark_file, 'w');
            scp_handle = fopen(scp_file, 'w');
            for f = 1 : size(features, 1)
                utt_id = features{f, 1};
                utt_mat = features{f, 2};
                fwrite(ark_handle, [utt_id ' '], 'char*1');
                position = ftell(ark_handle);
                ark_handle = writeKaldiFeatureArk(ark_handle, utt_mat, 0);
                fprintf(scp_handle, '%s %s:%d\n', utt_id, ark_file, position); 
            end
        end
        fclose(ark_handle);
        fclose(scp_handle);
    end
    
end

function ark_handle = writeKaldiFeatureArk(ark_handle, utt_mat, binary)
    [rows, cols] = size(utt_mat);
    if binary % write in binary mode
        if rows == 1
            fwrite(ark_handle, 0, 'int8');
            fwrite(ark_handle, 'BFV ', 'int8');
            fwrite(ark_handle, 4, 'int8');
            fwrite(ark_handle, cols, 'int32');
        else 
            fwrite(ark_handle, 0, 'int8');
            fwrite(ark_handle, 'BFM ', 'int8');
            fwrite(ark_handle, 4, 'int8');
            fwrite(ark_handle, rows, 'int32');
            fwrite(ark_handle, 4, 'int8');
            fwrite(ark_handle, cols, 'int32');
            utt_mat = reshape(utt_mat', 1, rows * cols);
        end
        fwrite(ark_handle, utt_mat, 'float32');
    else % write in readable mode
        if rows == 1
            fprintf(ark_handle, ' [');
            for i = 1 : cols
                fprintf(ark_handle, ' %f', utt_mat(i));
            end
            fprintf(ark_handle, ' ]\n');
        else
            fprintf(ark_handle, ' [\n ');
            for i = 1 : rows
                for j = 1 : cols
                    fprintf(ark_handle, ' %f', utt_mat(i, j));
                end
                if i == rows
                    fprintf(ark_handle, ' ]\n');
                else
                    fprintf(ark_handle, ' \n ');
                end
            end
        end
    end
end