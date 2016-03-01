classdef Bishop < ChessPiece
%
% Class representing the Bishop piece
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
        ID = 3;                     % ID number
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = Bishop(varargin)
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
            if (abs(dfile) == abs(drank))
                % Diagonal move

                % Check path from (this.i,this.j) to (i,j)
                sgni = sign(dfile);
                sgnj = sign(drank);
                dtot = abs(drank);
                for dij = 1:(dtot - 1)
                    it = this.i + sgni * dij;
                    jt = this.j + sgnj * dij;
                    if (this.BS.IsEmpty(it,jt) == false)
                        return;
                    end
                end

                % Check for vacancy
                if ((this.BS.IsEmpty(i,j) == true) || ...
                   (this.color ~= this.BS.ColorAt(i,j)))
                    bool = true;
                end
            end
        end
        
        %
        % Return coordinates of all valid moves
        %
        function [ii jj] = ValidMoves(this)
            % Start with empty move list
            ii = [];
            jj = [];
            
            % Try all diagonal moves
            sgni = [-1 1];
            sgnj = [-1 1];
            for x = 1:2
                for y = 1:2
                    k = 1;
                    while 1
                        i = this.i + k * sgni(x);
                        j = this.j + k * sgnj(y);
                        if ((i < 1) || (i > 8) || ...
                            (j < 1) || (j > 8))
                            % Not on the board
                            break;
                        end
                        
                        % Check if bishop can move/capture @(i,j)
                        if (this.color ~= this.BS.ColorAt(i,j))
                            % Valid move
                            ii = [ii i]; %#ok
                            jj = [jj j]; %#ok
                        end
                        
                        % Check if bishop can move past (i,j)
                        if (this.BS.IsEmpty(i,j) == false)
                            % Can't go past this square
                            break;
                        end
                        
                        k = k + 1;
                    end
                end
            end
        end
    end
end
