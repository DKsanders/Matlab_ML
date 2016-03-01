% Neural network playing chess!

% Initialize
clear;
clc;
close all;

% Set up brains
input_size = 64*13;
output_size = 278;
nn_neurons = {...
    {input_size, 1000, 1000, 1000, output_size}...
};
nn_layers = {...
    {ReLU_Layer, ReLU_Layer, ReLU_Layer, SoftmaxOutputLayer}...
};
nn_weight_files = {...
    'win_1.weights'...
};
neural_nets = initialize_nn(nn_neurons, nn_layers, nn_weight_files);

% Start game
mm = MoveManager
WHITE=1;
BLACK=2;
player_color = get_color();
if (player_color == WHITE)
    cpu_color = BLACK;
else
    cpu_color = WHITE;
end
cm = ChessMaster;
if (player_color == BLACK)
   cm.FlipBoard(); 
end
while (~cm.isGameOver && cm.winner ~= NaN)
    if cm.turnColor == cpu_color
        cm.BlockGUI(true);
        FENstr = cm.GetFENstr();
        predictions = get_nn_predictions(FENstr, cpu_color, neural_nets);
        
        % Iterate through predictions from best to worst
        for i = 1:length(predictions)
            [piece, id, change] = mm.move_id_to_move_data(predictions(i));
            SANstr = cm.MyMove(piece, id, change);
            if (length(SANstr) > 1 )
                % Found a legal move - exit
                break;
            end
        end
        cm.BlockGUI(false);
    end
    pause(0.01);
end