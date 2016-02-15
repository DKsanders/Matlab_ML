
% Hyper-Parameters
classdef Hyperparams < handle
	properties
        % Weight Initialization
        seed;                 % if =0, random initialization

        % Learning rates
        num_iteration;
		learning_rate;        % if =0, use dynamic learning rate
        annealing_constant;   % if =0, ignore annealing
		momentum;

        % Regularization
		penalty;
		batch_size;           % if =0, use all
		dropout_rate;
	end

	methods
        function [obj] = Hyperparams()
            obj.seed = 0;
            obj.num_iteration = 1;
            obj.learning_rate = 0;
            obj.annealing_constant = 0;
            obj.momentum = 0;
			obj.penalty = 0;
			obj.batch_size = 0;
            obj.dropout_rate = 0;
        end
    end
end
