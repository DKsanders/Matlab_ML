classdef ChessPieceData < handle
%
% Class that contains chess piece graphics data
%
% NOTE: This class is used internally by the ChessMaster GUI and is not
%       intended for public invocation
%
% Brian Moore
% brimoor@umich.edu
%

    %
    % Public properties
    %
    properties (Access = public)
        % Chess piece data
        file;                           % File coordinates
        rank;                           % Rank coordinates
        squareSize = 0;                 % Square size
        White;                          % White piece sprites
        Black;                          % Black piece sprites
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = ChessPieceData()
            % Empty
        end
    end
end
