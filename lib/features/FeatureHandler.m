% Class responsible for handling extension and scaling of features
classdef FeatureHandler < handle

    properties
        num_features;       % Number of input features (excluding x0, including extended features)
        order;              % Polynomial degree initial features get extended to

        mu;                % Averages of each input feature
        sigma;              % std's of each input feature

        transform_matrix;
        eigen_matrix;
    end

    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                     Constructor                       %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function [obj] = FeatureHandler()
            obj.num_features = 0;
            obj.order = 1;
            obj.mu = [];
            obj.sigma = [];
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                  Feature Extension                    %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Extend x0
        function [output_set] = extend_x0(obj, input_set)
            % Find size of data set
            [num_cases, original_num_features] = size(input_set);

            output_set = ones(num_cases, original_num_features+1);
            output_set(:, 2:original_num_features+1) = input_set;
        end

        % Extend inputs to kth polynomial without mixed polynomials
        % e.g. if inputs = [x1, x2] and order = 3:
        % outputs = [x1, x1^2, x1^3, x2, x1x2, x1^2x2, x2^2, x1x2^2, x2^3]
        function [output_set] = extend_to_mixed_kth_polynomial(obj, input_set)
            % Find size of data set
            [num_cases, original_num_features] = size(input_set);

            % Find how many features there are in the extended set
            output_num_features = count_num_features(original_num_features, obj.order) - 1;

            % Generate output vector
            output_set = zeros(num_cases, output_num_features);
            powers = zeros(1, original_num_features);
            for i=1:output_num_features
                powers = increment_power_vector(powers, obj.order);
                output_set(:,i) = prod(bsxfun(@power, input_set, powers),2);
            end
        end

        % Extend inputs to kth polynomial without mixed polynomials
        % e.g. if inputs = [x1, x2] and order = 3:
        % outputs = [x1, x1^2, x1^3, x2, x2^2, x2^3]
        function [output_set] = extend_to_kth_polynomial(obj, input_set)
            % Find size of data set
            [num_cases, num_features] = size(input_set);

            % Extend training set input to kth polynomial
            k = obj.order;
            output_set = zeros(num_cases, k*num_features);
            for i=1:num_features
                for j=1:k
                    output_set(:,(i-1)*k+j) = input_set(:,i).^j;
                end
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                    Normalization                      %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Get the mu and sigma for the data set
        function [] = get_normalization_params(obj, input_set)
            [num_cases, num_features] = size(input_set);
            obj.num_features = num_features;

            obj.mu = mean(input_set);
            obj.sigma = sqrt(sum(bsxfun(@minus, input_set, obj.mu).^2)./num_cases);
            
            % For 0 variance data sets, use unit variance
            obj.sigma = obj.sigma + (obj.sigma == 0);
        end

        % After getting data on μ and σ from get_scaling_params,
        % call this function to normalize dataset
        function [output_set] = normalize_dataset(obj, input_set)
            % Initialization
            [num_cases, num_features] = size(input_set);
            output_set = zeros(num_cases, obj.num_features);

            % Normalize x： x' = (x-μ)/σ
            output_set(:,:) = (input_set(:,:)-repmat(obj.mu,num_cases,1))./repmat(obj.sigma,num_cases,1);
        end


        % After getting data on μ and σ from get_scaling_params,
        % call this function to denormalize dataset
        function [output_set] = denormalize_dataset(obj, input_set)
            % Initialization
            [num_cases, num_features] = size(input_set);
            output_set = zeros(num_cases, obj.num_features);

            % Normalize x： x = (x' * σ) + μ
            output_set(:,:) = input_set(:,:).*repmat(obj.sigma,num_cases,1) + repmat(obj.mu,num_cases,1);
        end        

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %             Principal Component Analysis              %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function [] = get_covariance(obj, input_set)
            % Find size of data set
            [num_cases, num_features] = size(input_set);

            % Compute Covariance Matrix
            % Σ = 1/m * Σ(xi * xi')
            Covariance = input_set' * input_set / num_cases;

            % Compute Eigen Vectors of Sigma
            [obj.transform_matrix, obj.eigen_matrix, V] = svd(Covariance);
        end

        function [output_set, variance_retained] = reduce_to_dim(obj, input_set, dim)
            output_set = input_set * obj.transform_matrix(:, 1:dim);
            variance_retained = sum(diag(obj.eigen_matrix(1:dim, 1:dim)))/ trace(obj.eigen_matrix);
        end

        function [output_set, dim] = reduce_to_variance_retained(obj, input_set, variance_retained)
            current = 0;
            dim = 0;
            target = trace(obj.eigen_matrix) * variance_retained;
            while current < target
                dim = dim + 1;
                current = current + obj.eigen_matrix(dim, dim);
            end

            output_set = input_set * obj.transform_matrix(:, 1:dim);
        end

        function [output_set] = reconstruct(obj, input_set)
            [num_cases, num_features] = size(input_set);
            output_set = input_set * obj.transform_matrix(:, 1:num_features)';
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