% Neural network learning to recognize the digits 0 to 9.
% Inputs: 28 x 28 pixel image of a number.
% Details: http://yann.lecun.com/exdb/mnist/
% David Sanders

% Initialize
clear;
clc;
close all;

% Read in data, produce training and testing sets
num_labels = 278;
training_file = 'nn_files/win_1';
[num_cases, x_data, y_data] = read_data_from_single_file(training_file, ' ');

% Initialize Hyperparams
hparams = Hyperparams;
hparams.seed = 1;
hparams.num_iteration = 3000;
hparams.learning_rate = 0.03;
hparams.annealing_constant = 0;
hparams.momentum = 0.9;
hparams.penalty = 0.5;
hparams.batch_size = 100;
%hparams.batch_size = 100;
hparams.dropout_rate = 0;
            
% Run learning algorithm
[num_test_cases, num_features] = size(x_data);
nn_neurons = {num_features, 1000, 1000, 1000, num_labels};
nn_layers = {ReLU_Layer, ReLU_Layer, ReLU_Layer, SoftmaxOutputLayer};
%nn_neurons = {num_features, 1000, num_labels};
%nn_layers = {ReLU_Layer, SoftmaxOutputLayer};
nn = LayeredNetwork(nn_neurons, nn_layers);
nn.penalty_function = Ridge;
nn.restore_weights('win1.mat');
tic
nn.learn(hparams, x_data, onehot_encode(num_labels,y_data));
toc
nn.save_weights('win_1.mat');
