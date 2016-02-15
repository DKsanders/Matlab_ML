% Zero penalty function
classdef ZeroPenalty < Penalty

    methods
        function [cost] = cost(obj, lambda, weights, num_cases)
            cost = zeros(size(weights));
        end

        function [penalty] = penalty(obj, lambda, weights, num_cases)
            penalty = zeros(size(weights));
        end
    end

end
