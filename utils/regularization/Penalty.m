% Base class for all penalty functions
% The purpose for this class is to enforce the implementation of required functions
classdef (Abstract) Penalty

    methods (Abstract)
        cost = cost(obj, lambda, weights, num_cases)
        penalty = penalty(obj, lambda, weights, num_cases)
    end

end
