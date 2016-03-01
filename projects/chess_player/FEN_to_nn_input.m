% Convert FEN string to nn input format
function [nn_input] = FEN_to_nn_input(FENstr, color)
    % Constants
    BLACK = 2;

    % Convert board position into 64 ints
    square = 1;
    board = zeros(1, 64);
    for i = 1:length(FENstr)
        switch (FENstr(i))
        case ' '
            break;
        case '/'
            % Ignore
            square = square - 1;
        case 'k'
            board(square) = 6;
        case 'q'
            board(square) = 5;
        case 'r'
            board(square) = 4;
        case 'b'
            board(square) = 3;
        case 'n'
            board(square) = 2;
        case 'p'
            board(square) = 1;
        case 'K'
            board(square) = -6;
        case 'Q'
            board(square) = -5;
        case 'R'
            board(square) = -4;
        case 'B'
            board(square) = -3;
        case 'N'
            board(square) = -2;
        case 'P'
            board(square) = -1;
        otherwise
            square = square + str2num(FENstr(i)) - 1;
        end

        square = square + 1;
    end

    % Flip board if necessary
    if (color == BLACK)
        board = -1 * fliplr(board);
    end

    % Convert baord to nn input format
    nn_input = zeros(1, 64*13);
    board = board + 7;
    for i = 1:length(board)
        nn_input(13*(i-1) + board(i)) = 1;
    end
end