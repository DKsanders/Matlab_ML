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
        function [precision] = get_precision(obj, predictions, y_output)
            tp = obj.get_true_positives(predictions, y_output);
            precision = tp ./ sum(predictions);
        end

        % Find recall of predictions
        function [recall] = get_recall(obj, predictions, y_output)
            tp = obj.get_true_positives(predictions, y_output);
            recall = tp ./ sum(y_output);
        end

        % Get F1 score
        function [score] = get_f1_score(obj, predictions, y_output)
            precision = obj.get_precision(predictions, y_output);
            recall = obj.get_recall(predictions, y_output);
            score = 2 * precision .* recall ./ (precision + recall);
        end

        % Get the number of true positives from the predictions
        function [tp] = get_true_positives(obj, predictions, y_output)
            tp = sum(and(predictions, y_output));
        end
    end
end
