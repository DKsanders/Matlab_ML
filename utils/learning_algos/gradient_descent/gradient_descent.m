% Gradient descent
% Inputs:
%  hyperparams: Hyperparams object
%  descent_functions: GradientDescentFunctions object
%  x_training_set: Training set inputs
%  y_training_set: Training set outputs
%  weights: Initialized weights
% Output:
%  weights: Learned weights
function [weights] = gradient_descent(hyperparams, descent_functions, x_training_set, y_training_set, weights)
    % Extend x0
    feature_handler = InputFeatureHandler;
    x_training_set = feature_handler.extend_x0(x_training_set);

    [num_cases, num_features] = size(x_training_set);
    for i=1:hyperparams.num_iteration
        % Gradient Descent
        y_prediction = descent_functions.activation(x_training_set, weights);
        delta = descent_functions.descent(x_training_set, y_training_set, y_prediction);
        weights = weights - hyperparams.learning_rate*delta;

        % Penalization
        weights = weights - hyperparams.learning_rate*descent_functions.penalty(hyperparams.penalty, weights, num_cases);
    end
end