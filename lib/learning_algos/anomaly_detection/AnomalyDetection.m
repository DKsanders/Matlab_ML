% Class for anomaly detection
classdef AnomalyDetection < handle

    properties
        feature_handler;
        evaluation_function;
    end

    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                     Constructor                       %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Default function for penalty - no penalization
        function [obj] = AnomalyDetection()
            obj.feature_handler = FeatureHandler;
            obj.evaluation_function = EvaluateBinaryClassification;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                 Clustering Algorithm                  %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Cluster the data set using K-Means algorithm
        function [] = learn(obj, num_iteration, x_training_set)

            % Get mean and std
            obj.feature_handler.get_normalization_params(x_training_set);

        end

        function [threshold, cost] = sweep_threshold(obj, x_inputs, y_outputs)
            predictions = obj.predict(x_inputs);
            num_points = 10000;
            step_multiplier = (max(predictions)/min(predictions))^(1/(num_points));
            exponents = [1:num_points];
            thresholds = min(predictions) * (step_multiplier .^ exponents);
            %thresholds = min(predictions):(max(predictions)-min(predictions))/num_points:max(predictions);
            costs = zeros(size(thresholds));
            for i = 1:length(thresholds)
                costs(i) = obj.cost(predictions<thresholds(i), y_outputs);
            end
            [cost, index] = min(costs);
            threshold = thresholds(index);

            figure();
            plot(thresholds, costs)
            legend('Validation 1/F2 Score')
            title('Sweep: Threshold vs 1/F2 Score')
            xlabel('Threshold')
            ylabel('1/F2 Score')
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                 Prediction Function                   %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % See if likelihood of anomaly is below threshold
        function [prediction] = predict(obj, x_inputs)
            prediction = prod(bsxfun(@rdivide, exp(bsxfun(@rdivide, -1*bsxfun(@minus, x_inputs, obj.feature_handler.mu).^2, (2*obj.feature_handler.sigma.^2))), (sqrt(2*pi)*obj.feature_handler.sigma))')';
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                    Cost Function                      %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Cost function
        function [cost] = cost(obj, y_predictions, y_outputs)
            cost = 1/obj.evaluation_function.get_f1_score(y_predictions, y_outputs);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %         Save / Restore / Initialize Weights           %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Save centroids learned by clustering algorithm in a file
        function [] = save_params(obj, file_name);
            save_mu_var = obj.feature_handler.mu;
            save_sigma_var = obj.feature_handler.sigma;
            save(file_name, 'save_mu_var', 'save_sigma_var');
        end

        % Restore weights learned by clustering algorithm from a file
        function [] = restore_params(obj, file_name);
            load(file_name);
            obj.feature_handler.mu = save_mu_var;
            obj.feature_handler.sigma = save_sigma_var;
        end
    end
end
