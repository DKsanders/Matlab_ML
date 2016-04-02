% Class for clustering function
classdef ClusteringFunction < handle

    properties
        cluster_centroids;
    end

    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                     Constructor                       %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Default function for penalty - no penalization
        function [obj] = ClusteringFunction()
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                 Clustering Algorithm                  %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Cluster the data set using K-Means algorithm
        function [] = learn(obj, num_iteration, x_training_set, k)

            % Repeat the algorithm 100 times and get the best
            best_cost = -1;
            best_centroids = [];

            for i = 1:1
                % Randomly initialize cluster centroids
                obj.initialize_centroids(x_training_set, k, 0);

                for i = 1:num_iteration
                    % index clusters closest to x
                    cluster_id = obj.predict(x_training_set);

                    % Find new cluster centroids
                    for i = 1:k
                        current_ids = (cluster_id == i);
                        obj.cluster_centroids(i, :) = sum(bsxfun(@times, x_training_set, current_ids)) ./ sum(current_ids);
                    end
                end

                cost = obj.cost(x_training_set);
                if (cost < best_cost || best_cost == -1) 
                    best_cost = cost;
                    best_centroids = obj.cluster_centroids;
                end
            end

            obj.cluster_centroids = best_centroids;
            best_cost
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                 Prediction Function                   %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Assign inputs to a cluster
        function [prediction] = predict(obj, x_inputs)
            [num_case, num_features] = size(x_inputs);
            prediction = zeros(num_case, 1);
            for i = 1:num_case
                [dummy, prediction(i)] = min(sum((bsxfun(@minus, obj.cluster_centroids, x_inputs(i,:)).^2)')');
            end
        end

        % Get cluster centroids corresponding to indices
        function [centroid] = get_centroid(obj, indices)
            centroid = obj.cluster_centroids(indices, :);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                    Cost Function                      %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Cost function
        function [cost] = cost(obj, x_inputs)
            [num_case, num_features] = size(x_inputs);
            cluster_centroids = obj.get_centroid(obj.predict(x_inputs));
            cost = sum(sum((cluster_centroids - x_inputs) .^ 2)) / num_case;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %         Save / Restore / Initialize Weights           %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Random initialize centroids
        function [] = initialize_centroids(obj, x_inputs, k, seed)
            [num_case, num_features] = size(x_inputs);
            random_indices = randperm(num_case, k)';
            obj.cluster_centroids = x_inputs(random_indices, :);
        end

        % Save centroids learned by clustering algorithm in a file
        function [] = save_centroids(obj, file_name);
            save_weights_var = obj.cluster_centroids;
            save(file_name, 'save_centroids_var');
        end

        % Restore weights learned by clustering algorithm from a file
        function [] = restore_centroids(obj, file_name);
            load(file_name);
            obj.cluster_centroids = save_centroids_var;
        end
    end
end
