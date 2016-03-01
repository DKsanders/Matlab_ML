function [neural_nets] = initialize_nn(nn_neurons, nn_layers, nn_weight_files)
    for i = 1:length(nn_weight_files)
        neural_nets{i} =  LayeredNetwork(nn_neurons{i}, nn_layers{i});
        neural_nets{i}.restore_weights(nn_weight_files{i});
    end
end