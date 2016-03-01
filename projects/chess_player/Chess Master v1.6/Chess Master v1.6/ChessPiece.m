classdef ChessPiece < handle
%
% Superclass for all chess piece classes
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
        NULL = -1;                  % Null enum
        DRAW =  0;                  % Draw enum
        WHITE = 1;                  % White piece enum
        BLACK = 2;                  % Black piece enum
        BOTH =  3;                  % Both colors enum
    end
    
    %
    % Public GetAccess properties
    %
    properties (SetAccess = private, GetAccess = public)
        % Board state
        BS;                         % BoardState handle
        
        % Piece info
        color;                      % Color
        i;                          % File
        j;                          % Rank
        
        % Graphics handles
        ph;                         % Image handle
    end
    
    %
    % Private properties
    %
    properties (Access = private)
        % Piece information
        CPD;                        % ChessPieceData object
        size = 0;                   % Current sprite size
        
        % Graphics handles
        ax;                         % Axis handle
    end
    
    %
    % Abstract public constants
    %
    properties (Abstract = true, GetAccess = public, Constant = true)
        ID;                         % Piece ID number
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = ChessPiece(ax,BS,color,CPD,i,j)
            % Save piece information
            this.ax = ax;
            this.BS = BS;
            this.color = color;
            this.CPD = CPD;
            
            % Create image object
            this.ph = image(0,'Parent',this.ax, ...
                              'Visible','off');
            
            % Set sprite
            this.SetSprite();
            
            % If coordinates were supplied
            if (nargin >= 6)
                % Assign piece to board
                this.AssignPiece(i,j);
            end
        end
        
        %
        % Assign piece location
        %
        function AssignPiece(this,i,j)
            % Assign piece location
            this.i = i;
            this.j = j;
            
            % If BoardState object provided
            if ~isempty(this.BS)
                % Add piece to board
                this.BS.AddPiece(this);
            end
            
            % Draw piece
            this.DrawPiece();
        end
        
        %
        % Move piece (and perform all dependencies)
        %
        function [move isprom] = MovePiece(this,toi,toj,drawflag,editMode)
            % Parse flags
            drawflag = ((nargin < 4) || (drawflag == true));
            editMode = ((nargin == 5) && (editMode == true));
            
            % Create move object
            fromi = this.i;
            fromj = this.j;
            move = Move(this,toi,toj,editMode);
            
            % Piece-specific moves
            isprom = false;
            switch this.ID
                case Pawn.ID
                    if this.BS.IsValidPromotion(fromi,fromj,toi,toj)
                        % Promotion
                        isprom = true;
                    elseif this.BS.IsValidEnPassant(fromi,fromj,toi,toj)
                        % En passant capture
                        pawn = this.BS.PieceAt(toi,fromj);
                        pawn.CapturePiece(drawflag);
                        move.AddCapture(pawn);
                    end
                case King.ID
                    [isValidCastle rfi rti] = ...
                                this.BS.IsValidCastle(fromi,fromj,toi,toj);
                    if (isValidCastle == true)
                        % Castling
                        rook = this.BS.PieceAt(rfi,fromj);
                        rook.FastMovePiece(rti,fromj,drawflag);
                    end
            end
            
            % Check for captures
            if ~this.BS.IsEmpty(toi,toj)
                % Standard capture
                piece = this.BS.PieceAt(toi,toj);
                piece.CapturePiece(drawflag);
                move.AddCapture(piece);
            end
            
            % Move piece on board
            this.BS.MovePiece(this,toi,toj);
            
            % Update coordinates
            this.i = toi;
            this.j = toj;
            
            % Draw piece, if requested
            if (drawflag == true)
                this.DrawPiece();
            end
        end
        
        %
        % Fast move piece (don't check promotions, captures, or castles)
        %
        function FastMovePiece(this,i,j,drawflag)
            % Parse drawflag
            if (nargin < 4)
                drawflag = true;
            end
            
            % Move piece on board
            this.BS.MovePiece(this,i,j);
            
            % Update coordinates
            this.i = i;
            this.j = j;
            
            % Draw piece at new location
            if (drawflag == true)
                this.DrawPiece();
            end
        end
        
        %
        % Capture this piece
        %
        function CapturePiece(this,drawflag)
            % Parse drawflag
            if (nargin < 2)
                drawflag = true;
            end
            
            % Remove piece from board
            this.BS.RemovePiece(this);
            
            % Turn off piece
            if (drawflag == true)
                this.TurnOff();
            end
        end
        
        %
        % Uncapture piece (for undoing moves)
        %
        function UncapturePiece(this,drawflag)
            % Parse drawflag
            if (nargin < 2)
                drawflag = true;
            end
            
            % Add piece back onto board
            this.BS.AddPiece(this);
            
            % Redraw piece on board
            if (drawflag == true)
                this.DrawPiece();
            end
        end
        
        %
        % Check if piece is under attack by opposition
        %
        function bool = IsUnderAttack(this)
            % Call BoardState routine for this
            attackColor = this.Toggle(this.color);
            bool = this.BS.IsUnderAttack(this.i,this.j,attackColor);
        end
        
        %
        % See if proposed move results in a check for this piece's color
        %
        function bool = IsCheckingMove(this,i,j)
            % Perform move (without drawing)
            move = this.MovePiece(i,j,false);
            
            % See if move was legal
            bool = this.BS.IsInCheck(this.color);
            
            % Undo the move (without drawing)
            ChessPiece.UndoMovePiece(move,this.BS,false);
        end
        
        %
        % Set sprite
        %
        function SetSprite(this)
            % Save current sprite size
            this.size = this.CPD.squareSize;
            
            % Get sprite
            switch this.color
                case ChessPiece.WHITE
                    % White piece
                    piece = this.CPD.White(this.ID);
                case ChessPiece.BLACK
                    % White piece
                    piece = this.CPD.Black(this.ID);
            end
            I = flipdim(piece.I,1);
            alpha = flipdim(piece.alpha,1);
            
            % Set sprite
            set(this.ph,'CData',I, ...
                        'AlphaData',alpha, ...
                        'XData',get(this.ph,'XData'), ...
                        'YData',get(this.ph,'YData'));
        end
        
        %
        % Draw piece at its coordinates
        %
        function DrawPiece(this)
            % Get piece limits
            xlim = this.CPD.file(this.i + [0 1]) - [0 1];
            ylim = this.CPD.rank(this.j + [0 1]) - [0 1];
            
            % Handle board orientation
            if (~isempty(this.BS) && (this.BS.flipped == true))
                % Flip coordinates
                xlim = fliplr(xlim);
                ylim = fliplr(ylim);
            end
            
            % Draw piece
            set(this.ph,'XData',xlim,'YData',ylim);
            
            % Make sure piece is on
            this.TurnOn();
        end
        
        %
        % Draw piece at the (arbitrary) axis coordinates
        %
        function DrawPieceAt(this,x,y)
            % Compute piece limits
            sz = this.CPD.squareSize - 1;
            xlim = x + sz * [-0.5 0.5];
            ylim = y + sz * [-0.5 0.5];
            
            % Handle board orientation
            if (~isempty(this.BS) && (this.BS.flipped == true))
                % Flip coordinates
                xlim = fliplr(xlim);
                ylim = fliplr(ylim);
            end
            
            % Draw piece at new location
            set(this.ph,'XData',xlim,'YData',ylim);
        end
        
        %
        % Make piece active
        %
        function MakeActive(this)
            % Send piece to top of graphics stack
            uistack(this.ph,'top');
            
            % Make sure piece is on
            this.TurnOn();
        end
        
        %
        % Chess pieces are never nans!
        %
        function bool = isnan(this) %#ok
            bool = false;
        end
        
        %
        % Permanently delete piece
        %
        function Delete(this)
            % Delete image handle
            delete(this.ph);
            
            % Delete object itself
            delete(this);
        end
    end
    
    %
    % Public static methods
    %
    methods (Access = public, Static = true)
        %
        % Undo an entire move
        %
        function UndoMovePiece(move,BS,drawflag)
            % Parse drawflag
            if (nargin < 3)
                drawflag = true;
            end
            
            % Get moved piece
            if ~isnan(move.pawn)
                % Promoted pawn
                piece = move.pawn;
            else
                % Moved piece
                piece = BS.PieceAt(move.toi,move.toj);
            end
            
            % Handle castling
            if ((piece.ID == King.ID) && ((move.fromi - piece.i) == 2))                
                % Undo queenside castle
                rook = BS.PieceAt(4,piece.j);
                rook.FastMovePiece(1,piece.j,drawflag);
            elseif ((piece.ID == King.ID) && ...
                    ((move.fromi - piece.i) == -2))
                % Undo kingside castle
                rook = BS.PieceAt(6,piece.j);
                rook.FastMovePiece(8,piece.j,drawflag);
            end
            
            % Move piece to original home
            piece.FastMovePiece(move.fromi,move.fromj,drawflag);
            
            % Handle pawn promotions
            if ~isnan(move.promotion)
                % Delete promoted piece
                move.promotion.CapturePiece(drawflag);
                
                % Uncapture pawn
                piece.UncapturePiece(drawflag);
            end
            
            % Handle captures
            if ~isnan(move.capture)
                % Undo capture
                move.capture.UncapturePiece(drawflag);
            end
        end
        
        %
        % Return other color
        %
        function ocolor = Toggle(color)
            switch color
                case ChessPiece.WHITE
                    % Return black
                    ocolor = ChessPiece.BLACK;
                case ChessPiece.BLACK
                    % Return white
                    ocolor = ChessPiece.WHITE;
            end
        end
    end
    
    %
    % Abstract public methods
    %
    methods (Access = public, Abstract = true)
        %
        % Check if move is valid (i.e., pseudo-legal)
        %
        bool = IsValidMove(this,i,j);
        
        %
        % Return coordinates of all valid (i.e., pseudo-legal) moves
        %
        [ii jj] = ValidMoves(this);
    end
    
    %
    % Private methods
    %
    methods (Access = private)
        %
        % Turn on piece
        %
        function TurnOn(this)
            % If sprite size has changed
            if (this.size ~= this.CPD.squareSize)
                % Set sprite
                this.SetSprite();
            end
            
            % Make piece visible
            set(this.ph,'Visible','on');  
        end
        
        %
        % Turn off piece
        %
        function TurnOff(this)
            % Make piece invisible
            set(this.ph,'Visible','off');   
        end
    end
end
