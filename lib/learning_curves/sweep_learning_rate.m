% Train with different learning rates
function [] = sweep_learning_rate( brain, hparams, x_training, y_training, x_validation, y_validation)

    learning_rate = [0.001, 0.003, 0.01, 0.03, 0.1, 0.3];
    
    % Initialize
    training_err = zeros(1, length(learning_rate));
    validation_err = zeros(1, length(learning_rate));
    
    % Learn with various parameters
    for i = 1:length(learning_rate)
        i

        % Initialize weights
        brain.initialize_weights(hparams.seed);

        % Set penalty
        hparams.learning_rate = learning_rate(i);

        % Learn
        brain.learn(hparams, x_training, y_training);

        % Get training and validation errors
        training_err(i) = brain.cost(x_training, y_training);
        validation_err(i) = brain.cost(x_validation, y_validation);
    end

    % Plot
    figure;
    semilogx(learning_rate, training_err, '-ro', learning_rate, validation_err, '-bx')
    legend('Training Error', 'Validation Error')
    title('Sweep: Learning Rate')
    xlabel('Learning Rate')
    ylabel('Error')
end

