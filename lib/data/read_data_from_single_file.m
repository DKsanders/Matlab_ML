% Read in data, produce training, validation and testing sets
function [num_features, x_data, y_data] = read_data_from_single_file(file, delim)
	% Read from files
	temp = importdata(file,delim);
	[row, col] = size(temp);
	num_features = col-1;
	x_data = temp(:,1:num_features);
	y_data = temp(:,col);
end
