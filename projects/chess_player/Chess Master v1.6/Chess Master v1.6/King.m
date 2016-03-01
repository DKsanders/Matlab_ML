classdef King < ChessPiece
%
% Class representing the King piece
%
% NOTE: This class is used internally by the ChessMaster GUI and is not
%       intended for public invocation
%
% Brian Moore
% brimoor@umich.edu
%

    %
    % Public constants
    %
    properties (GetAccess = public, Constant = true)
        % Piece ID
        ID = 6;                     % ID number
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = King(varargin)
            % Call ChessPiece constructor
            this = this@ChessPiece(varargin{:});
        end
        
        %
        % Check if move is valid
        %
        function bool = IsValidMove(this,i,j)
            % Assume invalid by default
            bool = false;
            
            % Get movement
            dfile = i - this.i;
            drank = j - this.j;
            
            % Check move validity
            if ((abs(dfile) <= 1) && (abs(drank) <= 1))
                % Check for valid destination
                if (this.BS.IsEmpty(i,j) || ...
                   (this.color ~= this.BS.ColorAt(i,j)))
                    % Valid king movement
                    bool = true;
                end
            elseif this.BS.IsValidCastle(this.i,this.j,i,j)
                % Valid castling move
                bool = true;
            end
        end
        
        %
        % Return coordinates of all valid moves
        %
        function [ii jj] = ValidMoves(this)
            % Try all possible moves
            ii = this.i + [-1  0  1 -1  1  -1  0  1  2 -2];
            jj = this.j + [-1 -1 -1  0  0   1  1  1  0  0];
            kk = (ii >= 1) .* (ii <= 8) .* (jj >= 1) .* (jj <= 8);
            for k = 1:10
                if ((kk(k) == true) && ~this.IsValidMove(ii(k),jj(k)))
                    kk(k) = 0;
                end
            end
            
            % Return valid moves
            ii = ii(logical(kk));
            jj = jj(logical(kk));
        end
    end
end
