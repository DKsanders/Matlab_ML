% Onehot encode a value, used to covert classification label to network output format
function [encoded_output] = onehot_encode(num_labels, y_outputs)
    [num_cases, garbage] = size(y_outputs);
    
    % Create a matrix of 0s and 1s, where 1 corresponds to y==label
    encoded_output = zeros(num_cases, num_labels);
    rows = [1:num_cases]';
    indices = sub2ind(size(encoded_output),rows,y_outputs+1);
    encoded_output(indices) = 1;
end
