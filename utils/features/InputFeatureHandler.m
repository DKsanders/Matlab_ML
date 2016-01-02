% Class responsible for handling extension and scaling of input features
classdef InputFeatureHandler < handle

    properties
        num_features;       % Number of input features (including x0 and extended features)
        order;              % Polynomial degree initial features get extended to
        myu;                % Averages of each input feature
        sigma;              % std's of each input feature
    end

    methods
        % Constructors
        function [obj] = InputFeatureHandler()
            obj.num_features = 0;
            obj.order = 1;
            obj.myu = [];
            obj.sigma = [];
        end

        % Extend inputs to kth polynomial without mixed polynomials
        % e.g. if inputs = [x1, x2] and order = 3:
        % outputs = [1, x1, x1^2, x1^3, x2, x1x2, x1^2x2, x2^2, x1x2^2, x2^3]
        function [output_set] = extend_to_mixed_kth_polynomial(obj, input_set)
            % Find size of data set
            [num_cases, original_num_features] = size(input_set);

            % Find how many features there are in the extended set
            output_num_features = count_num_features(original_num_features, obj.order);
            obj.num_features = output_num_features;

            % Generate output vector
            output_set = ones(num_cases, output_num_features);
            powers = zeros(1, original_num_features);
            for i=2:output_num_features
                powers = increment_power_vector(powers, obj.order);
                output_set(:,i) = prod(bsxfun(@power, input_set, powers),2);
            end
        end

        % Extend inputs to kth polynomial without mixed polynomials
        % e.g. if inputs = [x1, x2] and order = 3:
        % outputs = [1, x1, x1^2, x1^3, x2, x2^2, x2^3]
        function [output_set] = extend_to_kth_polynomial(obj, input_set)
            % Find size of data set
            [num_cases, num_features] = size(input_set);

            % Extend training set input to kth polynomial
            k = obj.order;
            output_set = zeros(num_cases, k*(num_features)+1);
            output_set(:,1) = 1;
            for i=1:num_features
                for j=1:k
                    output_set(:,(i-1)*k+j+1) = input_set(:,i).^j;
                end
            end
            obj.num_features = k*(num_features)+1;
        end

        % Get the myu and sigma for the data set
        function [] = get_scaling_params(obj, input_set)
            obj.myu = mean(input_set(:,2:obj.num_features));
            obj.sigma = sqrt(var(input_set(:,2:obj.num_features)));
        end

        % After getting data on μ and σ from get_scaling_params,
        % call this function to scale datasets
        function [output_set] = scale_dataset(obj, input_set)
            % Initialization
            [num_cases, num_features] = size(input_set);
            output_set = zeros(num_cases, obj.num_features);
            
            % Set x0 to 1
            output_set(:,1) = 1;

            % Normalize x： x' = (x-μ)/σ
            output_set(:,2:obj.num_features) = (input_set(:,2:obj.num_features)-repmat(obj.myu,num_cases,1))./repmat(obj.sigma,num_cases,1);
        end
    end
end

% Counts the number of output features there are
% given the number of input features and the polynomial order 
% out_num_features = (in_num_features + order)!/in_num_features!order!
function [count] = count_num_features(features, order)
    m = min(features, order);
    n = max(features, order);
    count = 1;
    for i=1:m
        count = count * (n+i) / i;
    end
end

% Produces the next set of vectors indicating what power
% to exponentiate output by
function [powers] = increment_power_vector(powers, k)
    is_valid = 0;
    current_index = 1;
    while ~is_valid
       powers(1,current_index) = powers(1,current_index) + 1;
       if sum(powers,2) > k
           powers(1,current_index) = 0;
           current_index = current_index+1;
       else
           is_valid = 1;
       end
    end
end