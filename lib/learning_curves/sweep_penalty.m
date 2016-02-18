% Train with different penalties
function [] = sweep_penalty( brain, hparams, x_training, y_training, x_validation, y_validation)

    lamda = [0.01, 0.02, 0.04, 0.08, 0.16, 0.32, 0.64, 1.28, 2.56, 5.12, 10.24];
    
    % Initialize
    training_err = zeros(1, length(lamda));
    validation_err = zeros(1, length(lamda));
    
    % Learn with various parameters
    for i = 1:length(lamda)
        i

        % Initialize weights
        brain.initialize_weights(hparams.seed);

        % Set penalty
        hparams.penalty = lamda(i);

        % Learn
        brain.learn(hparams, x_training, y_training);

        % Get training and validation errors
        training_err(i) = brain.cost(x_training, y_training);
        validation_err(i) = brain.cost(x_validation, y_validation);
    end

    % Plot
    figure;
    semilogx(lamda, training_err, '-ro', lamda, validation_err, '-bx')
    legend('Training Error', 'Validation Error')
    title('Sweep: Penalization')
    xlabel('Penalty')
    ylabel('Error')
end

