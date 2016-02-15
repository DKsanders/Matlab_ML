% Testing code to verify that activation functions are implemented
% correctly
% David Sanders

% Initialize
clear;
clc;
close all;

epsilon = 0.0001;
num_cases = 100;
num_features = 7;
num_outputs = 10;

x = initial_weights_uniform(num_cases, num_features, -1, 1, 1);
w = initial_weights_uniform(num_features, num_outputs, -1, 1, 1);
z = x * w;

cost_function{1} = WeightedSumOfSquares;
activation_function{1} = LinearActivation;
y{1} = round(activation_function{1}.activation(z));

cost_function{2} = CrossEntropyCostFunction;
activation_function{2} = SigmoidActivation;
y{2} = activation_function{2}.activation(z) > 0.5;

cost_function{3} = CrossEntropyCostFunction;
activation_function{3} = SoftmaxActivation;
y{3} = onehot_encode(num_outputs, randi([0,num_outputs-1],num_cases,1));

for i=1:length(cost_function)
    y_predictions = activation_function{i}.activation(z);
    real_derivative = cost_function{i}.derivative(x, y{i}, y_predictions);
    
    numeric_derivative = zeros(size(real_derivative));
    for j = 1:num_features
        for k = 1:num_outputs
            w_plus = w;
            w_plus(j,k) = w_plus(j,k) + epsilon;
            y_plus = activation_function{i}.activation(x * w_plus);
            cost_plus = cost_function{i}.cost(y{i}, y_plus);
            
            w_minus = w;
            w_minus(j,k) = w_plus(j,k) - epsilon;
            y_minus = activation_function{i}.activation(x * w_minus);
            cost_minus = cost_function{i}.cost(y{i}, y_minus);
            numeric_derivative(j,k) = (cost_plus - cost_minus) / (2*epsilon);
        end
    end
    real_derivative = reshape(real_derivative, num_features * num_outputs,1);
    numeric_derivative = reshape(numeric_derivative, num_features * num_outputs,1);
    
    %a = [real_derivative, numeric_derivative]
    
    if (sum(sum((real_derivative - numeric_derivative) > epsilon))  > 0)
        cost_function{i}
    end
end