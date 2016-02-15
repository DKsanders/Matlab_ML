% Produces weights w_ij from uniform random variable
% Inputs:
%   i - number of features
%   j - number of hidden units
%   from - min value weight initialized to
%   to - max value weight initialized to
%   seed - seed; set to 0 for no seed
function [weights] = initial_weights_uniform(i, j, from, to, seed)
	if seed ~= 0
    	s = RandStream('mt19937ar','Seed', seed);
    	RandStream.setGlobalStream(s);
	end
	weights = rand(i,j)*(to-from)+from;
end
