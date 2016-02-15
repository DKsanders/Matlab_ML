% Neural network learning to recognize the digits 0 to 9.
% Inputs: 28 x 28 pixel image of a number.
% Details: http://yann.lecun.com/exdb/mnist/
% David Sanders

% Initialize
clear;
clc;
close all;

% Read in data, produce training and testing sets
num_labels = 10;

x_training_file = 'train_images';
fileID = fopen(x_training_file);
x_data = fread(fileID);
x_data = x_data(17:length(x_data),1);
x_data = reshape(x_data, 28*28, []);
x_training_set = x_data';
fclose(fileID);

y_training_file = 'train_labels';
fileID = fopen(y_training_file);
y_data = fread(fileID);
y_training_set = y_data(9:length(y_data),1);
fclose(fileID);

x_testing_file = 'test_images';
fileID = fopen(x_testing_file);
x_data = fread(fileID);
x_data = x_data(17:length(x_data),1);
x_data = reshape(x_data, 28*28, []);
x_test_set = x_data';
fclose(fileID);

y_testing_file = 'test_labels';
fileID = fopen(y_testing_file);
y_data = fread(fileID);
y_test_set = y_data(9:length(y_data),1);
fclose(fileID);

% Feature scaling
x_training_set = x_training_set > 127;
x_test_set = x_test_set > 127;

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
            
% Run learning algorithm
[num_test_cases, num_features] = size(x_training_set);
nn_neurons = {num_features, 1000, 1000, num_labels};
nn_layers = {SigmoidLayer, SigmoidLayer, SoftmaxOutputLayer};
%nn_layers = {ReLU_Layer, ReLU_Layer, SoftmaxOutputLayer};
nn = LayeredNetwork(nn_neurons, nn_layers);
nn.penalty_function = Ridge;
%nn.restore_weights('architecture2.weights');
nn.learn(hparams, x_training_set, onehot_encode(num_labels,y_training_set));
%nn.save_weights('architecture2.weights');

% Analyze
training_predictions = nn.predict(x_training_set);
training_guesses = onehot_decode(training_predictions);
training_mistakes = (training_guesses - y_training_set) ~= 0;
training_err = sum(training_mistakes)

test_predictions = nn.predict(x_test_set);
test_guesses = onehot_decode(test_predictions);
test_mistakes = (test_guesses - y_test_set) ~= 0;
test_err = sum(test_mistakes)