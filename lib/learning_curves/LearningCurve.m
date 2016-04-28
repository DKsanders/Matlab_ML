% Class responsible for plotting learning curves
classdef LearningCurve < handle

    properties
        show_progress;
        plot_graph;

        annealing;
        dropout;
        learning_rate;
        momentum;
        penalty;
    end

    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                     Constructor                       %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function [obj] = LearningCurve()
            obj.show_progress = 1;
            obj.plot_graph = 1;

            obj.annealing = [0, 0.9, 0.95, 0.99, 0.999];
            obj.dropout = [0, 0.1, 0.25, 0.4, 0.5, 0.6];
            obj.learning_rate = [0.001, 0.003, 0.01, 0.03, 0.1, 0.3];
            obj.momentum = [0, 0.5, 0.8, 0.85, 0.9, 0.95, 0.99];
            obj.penalty = [0.01, 0.02, 0.04, 0.08, 0.16, 0.32, 0.64, 1.28, 2.56, 5.12, 10.24];
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                  Plotting Functions                   %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [best_val] = sweep_annealing(obj, brain, hparams, x_training, y_training, x_validation, y_validation)
            best_val = obj.sweep_parameter(brain, hparams, x_training, y_training, x_validation, y_validation, 'Annleaing', hparams.num_iteration*obj.annealing, 1);    
        end

        function [best_val] = sweep_dropout(obj, brain, hparams, x_training, y_training, x_validation, y_validation)
            best_val = obj.sweep_parameter(brain, hparams, x_training, y_training, x_validation, y_validation, 'Dropout', obj.dropout, 0);    
        end

        function [best_val] = sweep_learning_rate(obj, brain, hparams, x_training, y_training, x_validation, y_validation)
            best_val = obj.sweep_parameter(brain, hparams, x_training, y_training, x_validation, y_validation, 'Learning Rate', obj.learning_rate, 1);    
        end

        function [best_val] = sweep_momentum(obj, brain, hparams, x_training, y_training, x_validation, y_validation)
            best_val = obj.sweep_parameter(brain, hparams, x_training, y_training, x_validation, y_validation, 'Momentum', obj.momentum, 0);    
        end

        function [best_val] = sweep_penalty(obj, brain, hparams, x_training, y_training, x_validation, y_validation)
            best_val = obj.sweep_parameter(brain, hparams, x_training, y_training, x_validation, y_validation, 'Penalty', obj.penalty, 1);    
        end

        % Train with different parameters
        function [best_val] = sweep_parameter(obj, brain, hparams, x_training, y_training, x_validation, y_validation, param_name, params, use_log)
            % Initialize
            training_err = zeros(1, length(params));
            validation_err = zeros(1, length(params));
            
            % Learn with various parameters
            for i = 1:length(params)
                if (obj.show_progress)
                    str = sprintf('Sweeping %s: %d of %d', param_name, i, length(params));
                    disp(str);
                end

                % Initialize weights
                brain.initialize_weights(hparams.seed);

                % Set new parameter
                hparams = obj.set_param(hparams, param_name, params(i));

                % Learn
                brain.learn(hparams, x_training, y_training);

                % Get training and validation errors
                training_err(i) = brain.cost(x_training, y_training);
                validation_err(i) = brain.cost(x_validation, y_validation);
            end

            % Get best param to use
            [dummy, index] = min(validation_err);
            best_val = params(index);

            % Plot
            if (obj.plot_graph)
                figure;
                if (use_log)
                    semilogx(params, training_err, '-ro', params, validation_err, '-bx')
                else
                    plot(params, training_err, '-ro', params, validation_err, '-bx')
                end
                legend('Training Error', 'Validation Error')
                title(sprintf('Sweep: %s', param_name))
                xlabel(param_name)
                ylabel('Error')
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                Parameter determination                %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [hparams] = learning_cycle(obj, brain, hparams, x_training, y_training, x_validation, y_validation)
            show_progress = obj.show_progress;
            obj.show_progress = 0;

            plot_graph = obj.plot_graph;
            obj.plot_graph = 0;

            prev = [hparams.learning_rate hparams.momentum hparams.penalty hparams.annealing_constant hparams.dropout_rate];
            
            for num = 1:100
                if (show_progress)
                    str = sprintf('Clycle: %d', num);
                    disp(str);
                end

                learning_rate = obj.sweep_learning_rate(brain, hparams, x_training, y_training, x_validation, y_validation);
                hparams.learning_rate = learning_rate;

                momentum = obj.sweep_momentum(brain, hparams, x_training, y_training, x_validation, y_validation);
                hparams.momentum = momentum;

                penalty = obj.sweep_penalty(brain, hparams, x_training, y_training, x_validation, y_validation);
                hparams.penalty = penalty;

                annealing = obj.sweep_annealing(brain, hparams, x_training, y_training, x_validation, y_validation);
                hparams.annealing_constant = annealing;

                dropout = 0;
                %dropout = sweep_dropout(brain, hparams, x_training, y_training, x_validation, y_validation);
                %close all;
                %hparams.dropout_rate = dropout;

                new = [learning_rate momentum penalty annealing dropout];
                if (sum(new ~= prev) == 0)
                    break;
                end

                prev = [hparams.learning_rate hparams.momentum hparams.penalty hparams.annealing_constant hparams.dropout_rate];
            end

            obj.show_progress = show_progress;
            obj.plot_graph = plot_graph;
        end

        function [hparams] = set_param(obj, hparams, param_name, param_value)
            if (strcmp(param_name,'Annealing'))
                hparams.annealing_constant = param_value;
            elseif (strcmp(param_name,'Dropout'))
                hparams.dropout_rate = param_value;
            elseif (strcmp(param_name,'Learning Rate'))
                hparams.learning_rate = param_value;
            elseif (strcmp(param_name,'Momentum'))
                hparams.momentum = param_value;
            elseif (strcmp(param_name,'Penalty'))
                hparams.penalty = param_value;
            end
        end
    end
end
