classdef Pawn < ChessPiece
%
% Class representing the Pawn piece
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
        ID = 1;                     % ID number
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = Pawn(varargin)
            % Call ChessPiece constructor
            this = this@ChessPiece(varargin{:});
        end
        
        %
        % Check if move is valid
        %
        function bool = IsValidMove(this,toi,toj)
            % Assume invalid by default
            bool = false;
            
            % Parse movement
            fromi = this.i;
            fromj = this.j;
            dfile = toi - fromi;
            drank = toj - fromj;
            
            % Parse color
            switch this.color
                case ChessPiece.WHITE
                    % White movement
                    sgn = 1;
                    rank2 = 2;
                    captColor = ChessPiece.BLACK;
                case ChessPiece.BLACK
                    % Black movement
                    sgn = -1;
                    rank2 = 7;
                    captColor = ChessPiece.WHITE;
                otherwise
                    % Hmmm...
                    return;
            end
            drank = sgn * drank;
            
            % Quick movement check
            if ((sign(drank) ~= 1) || (abs(dfile) > 1))
                % Invalid movement
                return;
            end
            
            % Single-step moves
            if ((drank == 1) && (dfile == 0))
                if this.BS.IsEmpty(toi,toj)
                    % Valid movement
                    bool = true;
                end
                return;
            end
            
            % Standard captures
            destColor = this.BS.ColorAt(toi,toj);
            if ~isnan(destColor)
                if ((destColor == captColor) && (drank == 1))
                    % Valid capture
                    bool = true;
                end
                return;
            end
            
            % Two-step moves
            if (drank == 2)
                if ((fromj == rank2) && (dfile == 0) && ...
                     this.BS.IsEmpty(toi,toj - sgn))
                    % Valid move
                    bool = true;
                end
                return;
            end
            
            % En passant captures
            if this.BS.IsValidEnPassant(fromi,fromj,toi,toj)
                % Valid en passant
                bool = true;
            end
        end
        
        %
        % Return coordinates of all valid moves
        %
        function [ii jj] = ValidMoves(this)
            % Process based on pawn color
            switch this.color
                case ChessPiece.WHITE
                    % White pawn
                    sgnj = 1;
                case ChessPiece.BLACK
                    % Black pawn
                    sgnj = -1;
            end
            
            % Try all possible moves
            ii = this.i + [0  0 -1  1];
            jj = this.j + sgnj * [2  1  1  1];
            kk = (ii >= 1) .* (ii <= 8) .* (jj >= 1) .* (jj <= 8);
            for k = 1:4
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
