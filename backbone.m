% Backbone for machine learning program
% David Sanders

% Initialize
clear;
clc;
close all;

% Read in data, produce training, validation and testing sets

% Extend feature set
feature_handler = FeatureHandler;
feature_handler.order = 20;
x_training_set = feature_handler.extend_to_mixed_kth_polynomial(x_training_set);
x_validation_set = feature_handler.extend_to_mixed_kth_polynomial(x_validation_set);
x_test_set = feature_handler.extend_to_mixed_kth_polynomial(x_test_set);

% Feature scaling
feature_handler.get_normalization_params(x_training_set);
x_training_set = feature_handler.normalize_dataset(x_training_set);
x_validation_set = feature_handler.normalize_dataset(x_validation_set);
x_test_set = feature_handler.normalize_dataset(x_test_set);

% Initialize Hyperparams
hparams = Hyperparams;
hparams.seed = 0;
hparams.num_iteration = 1000;
hparams.learning_rate = 0.03;
hparams.annealing_constant = 0;
hparams.momentum = 0.9;
hparams.penalty = 0.05;
hparams.batch_size = 100;
hparams.dropout_rate = 0;

% Initialize weights
[num_test_cases, num_features] = size(x_training_set);
min_init_weight = -1;
max_init_weight = 1;
seed = 1;
weights = initial_weights_uniform(num_features, 1, min_init_weight, max_init_weight, seed);

% Run learning algorithm

% Analyze
training_err = funcs.cost(x_training_set, y_training_set, funcs.prediction(x_training_set, weights))
validation_err = funcs.cost(x_validation_set, y_validation_set, funcs.prediction(x_validation_set, weights))
test_err = funcs.cost(x_test_set, y_test_set, funcs.prediction(x_test_set, weights))
