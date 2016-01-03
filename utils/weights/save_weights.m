% Saves the learned weights to a text file
% Weights can be restored using restore_weights
function [] = save_weights(filename, weights)
    dlmwrite(filename, ' ');

	% Array of weights
    if iscell(weights)
        for i=1:length(weights)
            dlmwrite(filename, weights{i}, '-append');
            dlmwrite(filename, ' ', '-append');
        end
    else
    % Single matrix of weights
        dlmwrite(filename, weights);
    end
end
