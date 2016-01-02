% Produces weights w_ij from uniform random variable
% Inputs:
%   i - number of features
%   j - number of hidden units
function [weights] = initial_weights_zero(i, j, from, to, seed)
	weights = zeros(i,j);
end
