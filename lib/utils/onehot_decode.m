% Onehot decode a value
function [decoded_output] = onehot_decode(encoded_y)
    [temp1, temp2] = max(encoded_y, 2);
    decoded_output = temp2 - 1;
end
