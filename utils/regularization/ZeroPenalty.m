% Zero penalty function
classdef ZeroPenalty < Penalty

    methods
        function [cost] = cost(obj, lambda, weights)
            cost = 0;
        end

        function [penalty] = penalty(obj, lambda, weights)
            penalty = 0;
        end
    end

end
