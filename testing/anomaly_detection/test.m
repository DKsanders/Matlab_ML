
% Initialize
clear;
clc;
close all;

load('data2.mat')

algo = AnomalyDetection;
num_iteration = 1000;
%tic
algo.learn(num_iteration, X);
%toc
p = algo.predict(X);
pval = algo.predict(Xval);
[threshold, cost] = algo.sweep_threshold(Xval, yval)
predicted_anomalies = p < threshold;
num_anomalies = sum(predicted_anomalies)
