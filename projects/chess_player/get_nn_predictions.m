% Get predictions on neural network
% If more than one is being used, get sum of squares
function [predictions] = get_nn_predictions(FENstr, color, neural_nets)
    nn_input = FEN_to_nn_input(FENstr, color);
    probabilities = zeros(1, 278);
    for i = 1:length(neural_nets)
        probabilities = probabilities + (neural_nets{i}.predict(nn_input).^2);
    end

    [a, predictions] = sort(probabilities);
    predictions = fliplr(predictions);
end