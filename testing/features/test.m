% Testing code to verify that feature handlers are implemented correctly
% David Sanders

% Initialize
clear;
clc;
close all;

f = FeatureHandler;
load('faces.mat');
varaince_retained = 0.99;
x_training = X(1:100, :);
x_test = X(100:5000, :);
f.get_normalization_params(x_training);
compressed_im_training = f.normalize_dataset(x_training);
compressed_im_test = f.normalize_dataset(x_test);

f.get_covariance(compressed_im_training);
[compressed_im_tr, dim] = f.reduce_to_variance_retained(compressed_im_training, varaince_retained);
[compressed_im_tst, var] = f.reduce_to_dim(compressed_im_test, dim);

uncompressed_tr = f.reconstruct(compressed_im_tr);
uncompressed_tst = f.reconstruct(compressed_im_tst);

uncompressed_tr = f.denormalize_dataset(uncompressed_tr);
uncompressed_tst = f.denormalize_dataset(uncompressed_tst);

% Show the 100 faces used for training
figure;
visualize_faces(uncompressed_tr);

% Show 100 random faces
figure;
random_indices = randperm(4900, 100)';
visualize_faces(uncompressed_tst(random_indices, :));

