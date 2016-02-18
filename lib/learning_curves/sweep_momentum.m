% Train with different momentum
function [] = sweep_momentum( brain, hparams, x_training, y_training, x_validation, y_validation)

    momentum = [0, 0.5, 0.8, 0.85, 0.9, 0.95, 0.99];
    
    % Initialize
    training_err = zeros(1, length(momentum));
    validation_err = zeros(1, length(momentum));
    
    % Learn with various parameters
    for i = 1:length(momentum)
        i

        % Initialize weights
        brain.initialize_weights(hparams.seed);

        % Set penalty
        hparams.momentum = momentum(i);

        % Learn
        brain.learn(hparams, x_training, y_training);

        % Get training and validation errors
        training_err(i) = brain.cost(x_training, y_training);
        validation_err(i) = brain.cost(x_validation, y_validation);
    end

    % Plot
    figure;
    plot(momentum, training_err, '-ro', momentum, validation_err, '-bx')
    legend('Training Error', 'Validation Error')
    title('Sweep: Momentum')
    xlabel('Momentum')
    ylabel('Error')
end

