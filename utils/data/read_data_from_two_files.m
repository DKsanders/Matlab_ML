% Read in data, produce training, validation and testing sets
function [num_features, x_data, y_data] = read_data_from_two_files(x_file, y_file, delim)
	% Read from files
	x_data = importdata(x_file, delim);
	y_data = importdata(y_file, delim);
	[row, num_features] = size(x_data);
end
