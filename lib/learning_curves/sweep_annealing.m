% Train with different annealing constants
function [] = sweep_annealing( brain, hparams, x_training, y_training, x_validation, y_validation)

    annealing = [1, 0.1, 0.01, 0.001];
    
    % Initialize
    training_err = zeros(1, length(annealing));
    validation_err = zeros(1, length(annealing));
    
    % Learn with various parameters
    for i = 1:length(annealing)
        i

        % Initialize weights
        brain.initialize_weights(hparams.seed);

        % Set penalty
        hparams.annealing_constant = (1-annealing(i))*hparams.num_iteration;

        % Learn
        brain.learn(hparams, x_training, y_training);

        % Get training and validation errors
        training_err(i) = brain.cost(x_training, y_training);
        validation_err(i) = brain.cost(x_validation, y_validation);
    end

    % Plot
    figure;
    semilogx(annealing, training_err, '-ro', annealing, validation_err, '-bx')
    legend('Training Error', 'Validation Error')
    title('Sweep: Annealing')
    xlabel('Annealing Constant')
    ylabel('Error')
end

