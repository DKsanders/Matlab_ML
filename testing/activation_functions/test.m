% Backbone for machine learning program
% David Sanders

% Initialize
clear;
clc;
close all;

epsilon = 0.00001;
x = [-10, -1, -1*epsilon, 0, epsilon, 1, 10; -10, -1, -1*epsilon, 0, epsilon, 1, 10];

activation_function{1} = LinearActivation;
activation_function{2} = ReLU_Activation;
activation_function{3} = SigmoidActivation;
activation_function{4} = SoftplusActivation;
activation_function{5} = TanhActivation;
activation_function{6} = SoftmaxActivation;

for i=1:length(activation_function)
    derivative = activation_function{i}.derivative(x);
    check = (activation_function{i}.activation(x+epsilon) - activation_function{i}.activation(x-epsilon))./(2*epsilon);
    if(sum(sum((derivative - check) > epsilon)) || sum(size(derivative)~=size(check))>0)
        activation_function{i}
        derivative
        check
    end
end