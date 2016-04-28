% Run to verify logistic regression works
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
feature_handler = FeatureHandler;
feature_handler.order = 10;
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
hparams.seed = 1;
hparams.num_iteration = 10000;
hparams.learning_rate = 0.03;
hparams.annealing_constant = 0;
hparams.momentum = 0.9;
hparams.penalty = 0.05;
hparams.batch_size = 0;
%obj.dropout_rate = 0;

% Sweep a hyperparameter
brain = LogisticRegression;
brain.penalty_function = Ridge;
lc = LearningCurve;
recommended_val = lc.sweep_learning_rate(brain, hparams, x_training_set, y_training_set, x_validation_set, y_validation_set)
