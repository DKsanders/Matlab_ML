
% Hyper-Parameters
classdef Hyperparams < handle
	properties
		learning_rate;        % if =0, use dynamic learning rate
		momentum;
		penalty;
		batch_size;           % if =0, use all
		num_iteration;
		dropout_rate;
        annealing_constant;   % if =0, ignore annealing
	end

	methods
        function [obj] = Hyperparams()
        	obj.learning_rate = 0;
			obj.momentum = 0;
			obj.penalty = 0;
			obj.batch_size = 0;
			obj.num_iteration = 1;
            obj.dropout_rate = 0;
            obj.annealing_constant = 0;
        end
    end
end
