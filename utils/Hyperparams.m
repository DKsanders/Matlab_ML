
% Hyper-Parameters
classdef Hyperparams
	properties
		learning_rate;
		momentum;
		penalty;
		batch_size; % if =0, use all
		num_iteration;
		dropout_rate;
	end

	 methods
        function [obj] = hyperparams()
        	obj.learning_rate = 0.01;
			obj.momentum = 0;
			obj.penalty = 0;
			obj.batch_size = 0;
			obj.num_iteration = 100;
			obj.dropout_rate = 0;
        end
    end
end
