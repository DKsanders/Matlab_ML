% Backbone for machine learning program
% David Sanders

% Initialize
clear;
clc;
close all;

% Read in data, produce training, validation and testing sets
x_file = 'ClassificationX.txt';
y_file = 'ClassificationY.txt';
[initial_num_features, x_data, y_data] = read_data_from_two_files(x_file,y_file, ' ');
x_training_set(:,1:initial_num_features) = x_data(1:50, 1:initial_num_features);
x_validation_set(:,1:initial_num_features) = x_data(51:100, 1:initial_num_features);
x_test_set(:,1:initial_num_features) = x_data(101:200, 1:initial_num_features);
y_training_set(:,1) = y_data(1:50);
y_validation_set(:,1) = y_data(51:100);
y_test_set(:,1) = y_data(101:200);

% Extend feature set
feature_handler = InputFeatureHandler;
feature_handler.order = 10;
x_training_set = feature_handler.extend_to_mixed_kth_polynomial(x_training_set);
x_validation_set = feature_handler.extend_to_mixed_kth_polynomial(x_validation_set);
x_test_set = feature_handler.extend_to_mixed_kth_polynomial(x_test_set);

% Feature scaling
feature_handler.get_scaling_params(x_training_set);
x_training_set = feature_handler.scale_dataset(x_training_set);
x_validation_set = feature_handler.scale_dataset(x_validation_set);
x_test_set = feature_handler.scale_dataset(x_test_set);

% Initialize Hyperparams
hparams = Hyperparams;
hparams.learning_rate = 0.03;
hparams.num_iteration = 10000;
hparams.penalty = 0.05;
hparams.batch_size = 10;

% Run learning algorithm
[num_test_cases, num_features] = size(x_training_set);
nn_neurons = {num_features, 10*num_features, 10*num_features, 10*num_features, 1};
nn_layers = {SigmoidLayer, SigmoidLayer, SigmoidLayer, SigmoidOutputLayer};
nn = LayeredNetwork(nn_neurons, nn_layers);
nn.penalty_function = Ridge;
%nn.restore_weights('weights.txt');
nn.learn(hparams, x_training_set, y_training_set);
%nn.save_weights('weights.txt');

% Analyze
training_err = nn.cost(x_training_set, y_training_set)
validation_err = nn.cost(x_validation_set, y_validation_set)
test_err = nn.cost(x_test_set, y_test_set)

% Plot
x_axis = linspace(0, 10 , 1000)';
x_temp = feature_handler.extend_to_mixed_kth_polynomial(x_axis);
x_temp = feature_handler.scale_dataset(x_temp);
y_axis = nn.predict(x_temp);
plot(x_data(1:50,:), y_data(1:50,:), 'ro', x_axis(:,1), y_axis(:,1));