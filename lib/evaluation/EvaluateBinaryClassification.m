% Class for evaluating binary classification
classdef EvaluateBinaryClassification < handle
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                     Constructor                       %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Default function for penalty - no penalization
        function [obj] = EvaluateBinaryClassification()
        end

        % Find precision of predictions
        function [precision] = get_precision(obj, label_predictions, y_output)
            tp = obj.get_true_positives(label_predictions, y_output);
            precision = tp ./ sum(label_predictions);
        end

        % Find recall of predictions
        function [recall] = get_recall(obj, label_predictions, y_output)
            tp = obj.get_true_positives(label_predictions, y_output);
            recall = tp ./ sum(y_output);
        end

        % Get F1 score
        function [score] = get_f1_score(obj, label_predictions, y_output)
            precision = obj.get_precision(label_predictions, y_output);
            recall = obj.get_recall(label_predictions, y_output);
            score = 2 * precision .* recall ./ (precision + recall);
        end

        % Get the number of true positives from the predictions
        function [tp] = get_true_positives(obj, label_predictions, y_output)
            tp = sum(and(label_predictions, y_output));
        end
    end
end
