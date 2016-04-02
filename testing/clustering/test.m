
% Initialize
clear;
clc;
close all;

load('data.mat')

algo = ClusteringFunction;
num_iteration = 100;
k=3;
tic
algo.learn(num_iteration, X, k);
toc
plot(X(:,1)', X(:,2)', 'rx', algo.cluster_centroids(:,1), algo.cluster_centroids(:,2), 'bo')

recommended_k = algo.sweep_k(num_iteration, X, 10)
