% Train with different dropout rates
function [] = sweep_dropout( brain, hparams, x_training, y_training, x_validation, y_validation)

    dropout = [0, 0.1, 0.25, 0.4, 0.5, 0.6];
    
    % Initialize
    training_err = zeros(1, length(dropout));
    validation_err = zeros(1, length(dropout));
    
    % Learn with various parameters
    for i = 1:length(dropout)
        i

        % Initialize weights
        brain.initialize_weights(hparams.seed);

        % Set penalty
        hparams.dropout_rate = dropout(i);

        % Learn
        brain.learn(hparams, x_training, y_training);

        % Get training and validation errors
        training_err(i) = brain.cost(x_training, y_training);
        validation_err(i) = brain.cost(x_validation, y_validation);
    end

    % Plot
    figure;
    semilogx(dropout, training_err, '-ro', dropout, validation_err, '-bx')
    legend('Training Error', 'Validation Error')
    title('Sweep: Dropout')
    xlabel('Dropout Rate')
    ylabel('Error')
end

