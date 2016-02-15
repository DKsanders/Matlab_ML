% Restores the learned weights from a text file
% Weights must be saved using save_weights
function [weights] = restore_weights(filename)
    % Open file
    fid = fopen(filename, 'r');

    % Read line by line
    tline = fgetl(fid);
    
    % If file starts with empty line, read in an array of weights
    if is_break(tline)
        weight_index = 0;
        row_num = 1;
        while ischar(tline)
            if is_break(tline)
                weight_index = weight_index + 1;
                row_num = 1;
            else
                weights{weight_index}(row_num,:) = str2double(strsplit(tline, ','));
                row_num = row_num + 1;
            end
            tline = fgetl(fid);
        end
    % If file starts without empty line, read in single matrix of weights
    else
        row_num = 1;
        while ischar(tline)
            if ~is_break(tline)
                weights(row_num,:) = str2double(strsplit(tline, ','));
                tline = fgetl(fid);
                row_num = row_num + 1;
            end
        end
    end

    % Close file
    fclose(fid);
end

function [tf] = is_break(tline)
    tf = strcmp(tline, ' ');
end