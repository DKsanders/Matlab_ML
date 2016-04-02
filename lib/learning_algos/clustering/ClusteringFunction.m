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
            prev_cluster_ids = [];

            for i = 1:100
                % Randomly initialize cluster centroids
                obj.initialize_centroids(x_training_set, k, 0);

                for j = 1:num_iteration
                    % index clusters closest to x
                    cluster_id = obj.predict(x_training_set);

                    if (best_cost ~= -1 && ~sum(cluster_id ~= prev_cluster_ids))
                        break;
                    end

                    % Find new cluster centroids
                    for l = 1:k
                        current_ids = (cluster_id == l);
                        obj.cluster_centroids(l, :) = sum(bsxfun(@times, x_training_set, current_ids)) ./ sum(current_ids);
                    end

                    prev_cluster_ids = cluster_id;
                end

                % Keep track of best performing clustering
                cost = obj.cost(x_training_set);
                if (cost < best_cost || best_cost == -1) 
                    best_cost = cost;
                    best_centroids = obj.cluster_centroids;
                end
            end

            % Set cluster centroids to best performing out of 100
            obj.cluster_centroids = best_centroids;
        end

        % Try clustering with multiple values of K and plot cost of each
        function [recommended_k] = sweep_k(obj, num_iteration, x_training, max_k)
            % Initialize
            k = [1:max_k];
            cost = zeros(1, max_k);
            
            % Learn with various parameters
            for i = 1:max_k
                i
                % Learn with i clusters
                obj.learn(num_iteration, x_training, i);

                % Get cost
                cost(i) = obj.cost(x_training);
            end

            % Plot
            figure;
            plot(k, cost, '-bx')
            title('Sweep: Number of Clusters')
            xlabel('Number of Clusters')
            ylabel('Error')

            % Find recommended k
            measure = zeros(1, max_k);
            for i = 2:max_k-1
                measure(i) = (cost(i-1) - cost(i)) / (cost(i) - cost(i+1));
            end
            [dummy, recommended_k] = max(measure);
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
