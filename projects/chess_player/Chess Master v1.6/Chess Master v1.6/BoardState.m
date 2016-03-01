classdef BoardState < handle
%
% Class for sharing board state information between ChessPiece objects
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
        % Mate "enum"
        NOMATE = 0;                 % No mate
        CHECKMATE = 1;              % Checkmate
        STALEMATE = 2;              % Stalemate
        
        % Standard starting FEN string
        STARTPOS = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -';
    end
    
    %
    % Public properties
    %
    properties (Access = public)
        % Move info
        moveList;                   % List of moves in game
        editList;                   % List of edits on position
        currentMove;                % Current halfmove
        currentEdit;                % Current edit number
        flipped = false;            % Board orientation flag
    end
    
    %
    % Public GetAccess properties
    %
    properties (GetAccess = public, SetAccess = private)
        % Position info
        startPos;                   % Starting position structure
    end
    
    %
    % Private properties
    %
    properties (Access = private)
        % Piece containers
        board;                      % Cell array of ChessPiece objects
        whitePieces = {};           % Cell array of white piece handles
        blackPieces = {};           % Cell array of black piece handles
        whiteKing;                  % White king
        blackKing;                  % Black king
        
        % Check status
        whiteInCheck;               % White check flag
        blackInCheck;               % Black check flag
        whiteMate;                  % White mate status
        blackMate;                  % White mate status
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = BoardState()
            % Empty
        end
        
        function [is_valid, fromi, fromj, toi, toj, pID] = GetMyMove(this, piece_id, id, change, color)
            is_valid = true;
            fromi = 0;
            fromj = 0;
            toi = 0;
            toj = 0;
            pID='';
            pieces = [];
            WHITE = 1;
            BLACK = 2;
            if (color == WHITE)
                pieces = this.whitePieces;
            else
                pieces = this.blackPieces;
            end

            current_index = 1;
            square = [];
            for i = 1:length(pieces)
                piece = pieces{i};
                if (piece.ID == piece_id)
                    if (color == WHITE)
                        square(current_index) = piece.i + 8*(piece.j-1);
                    else
                        square(current_index) = (9-piece.i) + 8*(8-piece.j);
                    end
                    current_index = current_index + 1;
                end
            end
            [a, b] = sort(square);
            if (id > length(a))
                is_valid = false;
                return;
            end
            from_square = a(id);
            to_square = from_square + change;

            if (from_square < 1 || from_square > 64 || to_square < 1 || to_square > 64)
                is_valid = false;
                return;
            end

            fromj = floor((from_square-1) / 8)+1;
            fromi = mod(from_square-1, 8)+1;
            toj = floor((to_square-1) / 8)+1;
            toi = mod(to_square-1, 8)+1;
            if (toi == 8 && piece_id == 1)
                pID = 'Q';
            end
            
            if (color == BLACK)
                fromj = 9 - fromj;
                fromi = 9 - fromi;
                toj = 9 - toj;
                toi = 9 - toi;
            end
        end

        %
        % Add piece @(i,j)
        %
        function AddPiece(this,obj)
            % Add piece to board
            this.board{obj.i,obj.j} = obj;
            
            % Add piece to color collection
            switch obj.color
                case ChessPiece.WHITE
                    % White piece
                    this.whitePieces{end + 1} = obj;
                    
                    % Store dedicated copy of king pointer
                    if (obj.ID == King.ID)
                        this.whiteKing = obj;
                    end
                case ChessPiece.BLACK
                    % Black piece
                    this.blackPieces{end + 1} = obj;
                    
                    % Store dedicated copy of king pointer
                    if (obj.ID == King.ID)
                        this.blackKing = obj;
                    end
            end
        end
        
        %
        % Remove piece
        %
        function RemovePiece(this,obj)
            % Remove piece from board
            this.board{obj.i,obj.j} = nan;
            
            % Remove piece from color collection
            iseq = @(p) (p == obj);
            switch obj.color
                case ChessPiece.WHITE
                    % White piece
                    this.whitePieces(cellfun(iseq,this.whitePieces)) = [];
                case ChessPiece.BLACK
                    % Black piece
                    this.blackPieces(cellfun(iseq,this.blackPieces)) = [];
            end
        end
        
        %
        % Move given piece to (i,j)
        %
        function MovePiece(this,obj,i,j)
            % Remove piece from old location
            this.board{obj.i,obj.j} = nan;
            
            % Add piece to new location
            this.board{i,j} = obj;
        end
        
        %
        % Return handle to piece @(i,j)
        %
        function obj = PieceAt(this,i,j)
            % Get piece handle (if any)
            obj = this.board{i,j};
        end
        
        %
        % Return king of given color
        %
        function king = KingOfColor(this,color)
            % Process based on color
            switch color
                case ChessPiece.WHITE
                    % White king
                    king = this.whiteKing;
                case ChessPiece.BLACK
                    % Black king
                    king = this.blackKing;
            end
        end
        
        %
        % Return color of piece at (i,j)
        %
        function color = ColorAt(this,i,j)
            % If square is empty
            if (this.IsEmpty(i,j) == true)
                % No color
                color = nan;
            else
                % Get piece color
                color = this.PieceAt(i,j).color;
            end
        end
        
        %
        % Check if (i,j) empty
        %
        function bool = IsEmpty(this,i,j)
            % Check if square is empty
            bool = isnan(this.board{i,j});
        end
        
        %
        % Check if (i,j) is occupied by a white piece
        %
        function bool = IsWhite(this,i,j)
            % Check for white piece
            if (~this.IsEmpty(i,j) && ...
                (this.board{i,j}.color == ChessPiece.WHITE))
                % Found white piece
                bool = true;
            else
                % No white piece
                bool = false;
            end
        end
        
        %
        % Check if (i,j) is occupied by a black piece
        %
        function bool = IsBlack(this,i,j)
            % Check for black piece
            if (~this.IsEmpty(i,j) && ...
                (this.board{i,j}.color == ChessPiece.BLACK))
                % Found black piece
                bool = true;
            else
                % No black piece
                bool = false;
            end
        end
        
        %
        % Return handles to pieces of given color and ID that can attack
        % square (i,j)
        %
        function pieces = Attackers(this,i,j,color,ID)
            % Get locations of all opposing pieces
            switch color
                case ChessPiece.WHITE
                    % Opponents are white
                    pieces = this.whitePieces;
                case ChessPiece.BLACK
                    % Opponents are black
                    pieces = this.blackPieces;
            end
            
            % Only return attacking pieces
            isattacking = @(p) ((p.ID ~= ID) || ~p.IsValidMove(i,j));
            pieces(cellfun(isattacking,pieces)) = [];
        end
        
        %
        % Determine whether square (i,j) is under attack by given color
        %
        function bool = IsUnderAttack(this,i,j,color)
            % Get locations of all opposing pieces
            switch color
                case ChessPiece.WHITE
                    % Opponents are white
                    pieces = this.whitePieces;
                case ChessPiece.BLACK
                    % Opponents are black
                    pieces = this.blackPieces;
            end
            
            % Loop over opposing pieces
            bool = false;
            for k = 1:length(pieces)
                % Check if opponent can capture
                if pieces{k}.IsValidMove(i,j)
                    % Found an attacker
                    bool = true;
                    return;
                end
            end
        end
        
        %
        % Update check status of both colors
        %
        function UpdateChecks(this)
            % Update white check status
            this.whiteInCheck = this.IsInCheck(ChessPiece.WHITE);
            
            % Update black check status
            this.blackInCheck = this.IsInCheck(ChessPiece.BLACK);
        end
        
        %
        % Update check status of given color
        % 
        function UpdateCheckStatus(this,color)
            % Get check status
            bool = this.IsInCheck(color);
            
            % Save check status
            switch color
                case ChessPiece.WHITE
                    % White check
                    this.whiteInCheck = bool;
                case ChessPiece.BLACK
                    % Black check
                    this.blackInCheck = bool;
            end
        end
        
        %
        % Get (last computed) check status of given color
        %
        function bool = GetCheckStatus(this,color)
            % Process based on color
            switch color
                case ChessPiece.WHITE
                    % White king check status
                    bool = this.whiteInCheck;
                case ChessPiece.BLACK
                    % Black king check status
                    bool = this.blackInCheck;
            end
        end
        
        %
        % See if given color is in check
        %
        function bool = IsInCheck(this,color)
            % Process based on color
            switch color
                case ChessPiece.WHITE
                    % White pieces
                    king = this.whiteKing;
                    attackColor = ChessPiece.BLACK;
                case ChessPiece.BLACK
                    % Black pieces
                    king = this.blackKing;
                    attackColor = ChessPiece.WHITE;
            end
            
            % Get check status
            if isnan(king)
                % No king
                bool = false;
            else
                % Check if king is under attack
                bool = this.IsUnderAttack(king.i,king.j,attackColor);
            end
        end
        
        %
        % Update mate status of given color
        %
        function UpdateMateStatus(this,color)
            % Compute mate status
            mate = this.IsInMate(color);
            
            % Save mate status
            switch color
                case ChessPiece.WHITE
                    % White mate status
                    this.whiteMate = mate;
                case ChessPiece.BLACK
                    % Black mate status
                    this.blackMate = mate;
            end
        end
        
        %
        % Get (last computed) mate status of given color
        %
        function mate = GetMateStatus(this,color)
            % Process based on color
            switch color
                case ChessPiece.WHITE
                    % White king mate status
                    mate = this.whiteMate;
                case ChessPiece.BLACK
                    % Black king mate status
                    mate = this.blackMate;
            end
        end
        
        %
        % See if given color is in mate
        %
        function mate = IsInMate(this,color)
            % Check if given color has any legal moves
            isLegalMove = this.AnyLegalMoves(color);
            
            % Determine mate status
            if (isLegalMove == true)
                % No mate
                mate = BoardState.NOMATE;
            elseif (this.IsInCheck(color) == true)
                % Checkmate
                mate = BoardState.CHECKMATE;
            else
                % Stalemate
                mate = BoardState.STALEMATE;
            end
        end
        
        %
        % Check if any piece of given color can legally move
        %
        function bool = AnyLegalMoves(this,color)
            % Get pieces of given color
            switch color
                case ChessPiece.WHITE
                    % Get white pieces
                    pieces = this.whitePieces;
                case ChessPiece.BLACK
                    % Get white pieces
                    pieces = this.blackPieces;
            end
            
            % Loop over pieces
            bool = false;
            for k = 1:length(pieces)
                % Get piece's valid moves
                [ii jj] = pieces{k}.ValidMoves();
                
                % Loop over valid moves
                for kk = 1:length(ii)
                    % Check for legal move
                    if (pieces{k}.IsCheckingMove(ii(kk),jj(kk)) == false)
                        % Found legal move
                        bool = true;
                        return;
                    end
                end
            end
        end
        
        %
        % Check if given color has sufficient mating material
        %
        function bool = SufficientMatingMaterial(this,color)
            % Process based on color
            switch color
                case ChessPiece.WHITE
                    if (length(this.whitePieces) > 1)
                        % Sufficient mating material
                        bool = true;
                    else
                        % Insufficient mating material
                        bool = false;
                    end
                case ChessPiece.BLACK
                    if (length(this.blackPieces) > 1)
                        % Sufficient mating material
                        bool = true;
                    else
                        % Insufficient mating material
                        bool = false;
                    end
            end                
        end
        
        %
        % Check if proposed move is valid castle
        %
        function [bool rfi rti] = IsValidCastle(this,fromi,fromj,toi,toj)
            % Initialize outputs
            bool = false; % Assume invalid to start
            rfi = [];
            rti = [];
            
            % Quick coordinate checks
            if ((fromi ~= 5) || (fromj ~= toj))
                % Invalid castle
                return;
            end
            
            % Parse color
            switch fromj
                case 1
                    % White castle
                    rank = 1;
                    color = ChessPiece.WHITE;
                    attackColor = ChessPiece.BLACK;
                case 8
                    % Black castle 
                    rank = 8;
                    attackColor = ChessPiece.WHITE;
                    color = ChessPiece.BLACK;
                otherwise
                    % Invalid...
                    return;
            end
            if (fromj ~= rank)
                % Wrong rank
                return;
            end
            
            % Parse destination
            switch toi
                case 3
                    % Queenside
                    rfi = 1;        % Rook's "from" rank
                    rti = 4;        % Rook's "to" rank
                    openSq = 2:4;   % Open files
                    attackSq = 3:5; % Unattacked files
                case 7
                    % Kingside
                    rfi = 8;        % Rook's "from" rank
                    rti = 6;        % Rook's "to" rank
                    openSq = 6:7;   % Open files
                    attackSq = 5:7; % Unattacked files
                otherwise
                    % Hmmm...
                    return;
            end
            
            % Verify king location
            king = this.PieceAt(fromi,fromj);
            if (isnan(king) || (king.ID ~= King.ID) || ...
               (king.color ~= color))
                % King not active
                return;
            end
            
            % Verify rook location
            rook = this.PieceAt(rfi,rank);
            if (isnan(rook) || (rook.ID ~= Rook.ID) || ...
               (rook.color ~= color))
                % Rook in wrong location
                return;
            end
            
            % Verify open squares
            for i = 1:length(openSq)
                if ~this.IsEmpty(openSq(i),rank)
                    % Square not open
                    return;
                end
            end
            
            % Verify unattacked squares
            for i = 1:length(attackSq)
                if this.IsUnderAttack(attackSq(i),rank,attackColor)
                    % Square attacked
                    return;
                end
            end
            
            % Verify castling rights
            state = this.GetCurrentEncoding();
            if any(~bitget(state([5 rfi],rank),7))
                % King or rook has already moved
                return;
            end
            
            % Valid castle
            bool = true;
        end
        
        %
        % Check if proposed move is valid en passant capture
        %
        function bool = IsValidEnPassant(this,fromi,fromj,toi,toj)
            % Assume invalid to start
            bool = false;
            
            % Quick file check
            if (abs(fromi - toi) ~= 1)
                % Invalid movement
                return;
            end
            
            % Verify destiation is empty
            if ~this.IsEmpty(toi,toj)
                % Invalid destination
                return;
            end
            
            % Parse movement
            switch toj
                case 3
                    % Black en passant
                    moveColor = ChessPiece.BLACK;
                    captColor = ChessPiece.WHITE;
                    fromRank = 4;
                    toRank = 3;
                case 6
                    % White en passant
                    moveColor = ChessPiece.WHITE;
                    captColor = ChessPiece.BLACK;
                    fromRank = 5;
                    toRank = 6;
                otherwise
                    % Invalid destination
                    return;
            end
            if ((fromj ~= fromRank) || (toj ~= toRank))
                % Invalid movement
                return;
            end
            
            % Verify moving piece
            piece = this.PieceAt(fromi,fromj);
            if (isnan(piece) || (piece.ID ~= Pawn.ID) || ...
               (piece.color ~= moveColor))
                % Invalid mover
                return;
            end
            
            % Verify captured piece
            captPiece = this.PieceAt(toi,fromj);
            if (isnan(captPiece) || (captPiece.ID ~= Pawn.ID) || ...
               (captPiece.color ~= captColor))
                % Invalid capture
                return;
            end
            
            % Check en passant rights
            state = this.GetCurrentEncoding();
            if (bitget(state(toi,toj),6) ~= 1)
                % No en passant rights
                return;
            end
            
            % Valid en passant
            bool = true;
        end
        
        %
        % Check if proposed move is valid promotion
        %
        function bool = IsValidPromotion(this,fromi,fromj,toi,toj)
            % Assume invalid to start
            bool = false;
            
            % Get piece
            piece = this.PieceAt(fromi,fromj);
            if (isnan(piece) || (piece.ID ~= Pawn.ID))
                % Invalid mover
                return;
            end
            
            % Process color
            switch piece.color
                case ChessPiece.WHITE
                    % White promotion rank
                    rank = 8;
                case ChessPiece.BLACK
                    % Black promotion rank
                    rank = 1;
            end
            if (toj ~= rank)
                % Invalid move
                return;
            end
            
            % Make sure move is valid
            if ~piece.IsValidMove(toi,toj)
                % Invalid move
                return;
            end
            
            % Valid promotion
            bool = true;
        end
        
        %
        % Undo current move in move list
        %
        function UndoMove(this)
            % If no more moves to undo
            if (this.currentMove <= 0)
                % Quick return
                return;
            end
            
            % Get current move
            move = this.moveList(this.currentMove);
            
            % Undo move
            ChessPiece.UndoMovePiece(move,this);
            
            % Decrement move index
            this.currentMove = this.currentMove - 1;
        end
        
        %
        % Redo next move in move list
        %
        function RedoMove(this)
            % If no more moves to perfom
            if (this.currentMove >= length(this.moveList))
                % Quick return
                return;
            end
            
            % Get next move
            move = this.moveList(this.currentMove + 1);
            
            % Get moving piece
            piece = this.PieceAt(move.fromi,move.fromj);
            
            % Perform move
            piece.MovePiece(move.toi,move.toj);
            
            % Handle promotions
            if ~isnan(move.pawn)
                % Make pawn disappear
                move.pawn.CapturePiece();
                
                % Reinstate promoted piece
                move.promotion.UncapturePiece();
            end
            
            % Increment move index
            this.currentMove = this.currentMove + 1;
        end
        
        %
        % Get random move for given color
        %
        function LANstr = GetRandomMove(this,color)
            % Get pieces of specified color
            switch color
                case ChessPiece.WHITE
                    % Get white pieces
                    promRank = 8;
                    pieces = this.whitePieces;
                case ChessPiece.BLACK
                    % Get black pieces
                    promRank = 1;
                    pieces = this.blackPieces;
            end
            
            % Search for a random (legal) move
            np = length(pieces);
            idx = 1;
            ids = randperm(np); % Loop through pieces in random order
            bool = false;
            while ((bool == false) && (idx <= np))
                % Get all valid moves for this piece
                piece = pieces{ids(idx)};
                [ii jj] = piece.ValidMoves();
                
                % Loop over valid moves
                nv = length(ii);
                ids2 = randperm(nv); % Loop through moves in random order
                ii = ii(ids2);
                jj = jj(ids2);
                for kk = 1:nv
                    % Check for legal move
                    if (piece.IsCheckingMove(ii(kk),jj(kk)) == false)
                        % Found a legal move
                        fmi = piece.i;
                        fmj = piece.j;
                        toi = ii(kk);
                        toj = jj(kk);
                        
                        % Add a promotion, if necessary
                        if ((piece.ID == Pawn.ID) && (toj == promRank))
                            % Random promotion
                            promID = randi([2 5]);
                        else
                            promID = [];
                        end
                        
                        % Return LAN string
                        LANstr = Move.GenerateLAN(fmi,fmj,toi,toj,promID);
                        return;
                    end
                end
                
                % Increment counter
                idx = idx + 1;
            end
            
            % No legal moves found... (this should never happen)
            msgid = 'BS:NOLEGALMOVES';
            errmsg = 'No legal moves found';
            error(msgid,errmsg);
        end
        
        %
        % Record move
        %
        function RecordMove(this,move)
            % Increment move counter
            this.currentMove = this.currentMove + 1;
            
            % If future moves were overwritten
            if (length(this.moveList) > this.currentMove)
                % Remove (now invalid) future moves
                this.moveList((this.currentMove + 1):end) = [];
            end
            
            % Save move
            this.moveList(this.currentMove) = move;
        end
        
        %
        % Record edit
        %
        function RecordEdit(this,FENstr)            
            % Increment edit counter
            if ~isempty(this.editList)
                % Only save if something changed
                currentFEN = this.editList{this.currentEdit};
                inc = double(~strcmp(FENstr,currentFEN));
            else
                % Always save first edit
                inc = 1;
            end
            this.currentEdit = this.currentEdit + inc;
            
            % If future edits were overwritten
            if (length(this.editList) > this.currentEdit)
                % Remove (now invalid) future edits
                this.editList((this.currentEdit + 1):end) = [];
            end
            
            % Save edit
            this.editList{this.currentEdit} = FENstr;
        end
        
        %
        % Get number of halfmoves since last capture or pawn movement
        %
        function count = GetReversibleMoves(this)
            if (this.currentMove > 0)
                % Get count from last saved move
                count = this.moveList(this.currentMove).reversibleMoves;
            else
                % No moves yet, so return starting position count
                count = this.startPos.reversibleMoves;
            end
        end
        
        %
        % Determine if threefold repetition has just occured
        %
        function bool = Is3FoldRep(this)
            bool = false;
            if (this.currentMove > 0)
                % Only need to search last consecutive reversible moves
                Nrev = this.GetReversibleMoves();
                
                % Current state
                cMove = this.currentMove;
                cstate = this.GetCurrentEncoding();
                
                % Iterate backwards through previous moves
                count = 1;
                Nmoves = min(cMove,Nrev) - 1;
                for i = 1:Nmoves
                    % Check for equality with current state
                    pstate = this.moveList(cMove - i).state;
                    if all(cstate(:) == pstate(:))
                        % Found a repetition
                        count = count + 1;
                        if (count >= 3)
                            % Found threefold repetition
                            bool = true;
                            return;
                        end
                    end
                end
            end
        end
        
        %
        % Get current (i.e., most recently performed) board encoding
        %
        function state = GetCurrentEncoding(this)
            % See if any moves have been performed
            if (this.currentMove > 0)
                % Get current encoding from move list
                state = this.moveList(this.currentMove).state;
            else
                % Return starting position encoding 
                state = this.startPos.state;
            end
        end
        
        %
        % Encode board state
        % * = Updated in Move.EncodeBoardState()
        %
        %  Bit | Description
        % -----+-------------
        %  1-3 | ID
        %  4-5 | Not used
        %   6  | En passant*
        %   7  | Castling*
        %   8  | Color
        %
        function state = BaseEncoding(this,copyFlag)
            % Parse copy flag
            copyFlag = ((nargin < 2) || (copyFlag == true));
            
            % Empty state matrix
            state = zeros(8,8,'uint8');
            
            % Encode white pieces
            for k = 1:length(this.whitePieces)
                piece = this.whitePieces{k};
                i = piece.i;
                j = piece.j;
                state(i,j) = piece.ID;
            end
            
            % Encode black pieces
            for k = 1:length(this.blackPieces)
                piece = this.blackPieces{k};
                i = piece.i;
                j = piece.j;
                state(i,j) = 128 + piece.ID;
            end
            
            % Copy previous castling rights, if requested
            if (copyFlag == true)
                lastState = this.GetCurrentEncoding();
                val = bitget(lastState([1 5 8],[1 8]),7);
                state([1 5 8],[1 8]) = bitset(state([1 5 8],[1 8]),7,val);
            end
        end
        
        %
        % Generate FEN string describing current board position with given
        % color to move
        %
        function FENstr = GetCurrentFENstr(this,color)
            % Get encoded board state
            state = this.GetCurrentEncoding();
            
            % Get # reversible moves
            revMoves = this.GetReversibleMoves();
            
            % Get turn #
            turnNumber = floor(this.currentMove / 2) + 1;
            
            % Generate FEN string
            FENstr = this.GenerateFEN(state,color,revMoves,turnNumber);            
        end
        
        %
        % Refresh pieces
        %
        function RefreshPieces(this)
            % Refresh white pieces
            for i = 1:length(this.whitePieces)
                this.whitePieces{i}.DrawPiece();
            end
            
            % Refresh black pieces
            for i = 1:length(this.blackPieces)
                this.blackPieces{i}.DrawPiece();
            end
        end
        
        %
        % Clear edit list
        %
        function ClearEditList(this)
            % Clear edit list
            this.editList = {};
            this.currentEdit = 0;
        end
        
        %
        % Reset board state to given FEN string
        %
        function success = Reset(this,FENstr)
        % Syntax: success = Reset(this);
        %         success = Reset(this,'');
        %         success = Reset(this,'startpos');
        %         success = Reset(this,FENstr);
        
            % Parse inputs
            if ((nargin < 2) || isempty(FENstr))
                % Standard starting position
                FENstr = 'startpos';
            end
            
            try
                % Parse FEN string
                this.startPos = BoardState.ParseFEN(FENstr);
                success = true;
            catch %#ok
                % Invalid FEN string
                success = false;
                return;
            end
            
            % Clear white pieces
            for i = 1:length(this.whitePieces)
                this.whitePieces{i}.Delete();
            end
            this.whitePieces = {};
            this.whiteKing = nan;
            this.whiteInCheck = false;
            this.whiteMate = BoardState.NOMATE;
            
            % Clear black pieces
            for i = 1:length(this.blackPieces)
                this.blackPieces{i}.Delete();
            end
            this.blackPieces = {};
            this.blackKing = nan;
            this.blackInCheck = false;
            this.blackMate = BoardState.NOMATE;
            
            % Clear board
            this.board = num2cell(nan(8,8));
            
            % Clear move list
            this.moveList = Move.empty(0,1);
            this.currentMove = 0;
        end
    end
    
    %
    % Public static methods
    %
    methods (Access = public, Static = true)
        %
        % Parse FEN string
        %
        % posInfo.FENstr          = Starting FEN string
        % posInfo.isStdStartPos   = Standard starting position flag
        % posInfo.colorToMove     = Current color to move
        % posInfo.reversibleMoves = Current # reversible moves
        % posInfo.state           = Encoded board state
        %
        % NOTE: The turn # field is ignored
        %
        function posInfo = ParseFEN(FENstr)
        % Syntax:   posInfo = ParseFEN(FENstr);
        
            % Parse FEN string
            startpos = BoardState.STARTPOS;
            FENstr = strtrim(FENstr);
            if strcmpi(FENstr,'startpos')
                % Standard starting position
                FENstr = startpos;
            end
            
            % Split FEN into chunks
            strs = regexp(FENstr,'\s+','split');
            if (length(strs) < 3)
                strs{3} = '-'; % Append empty castling rights
            end
            if (length(strs) < 4)
                strs{4} = '-'; % Append empty en passant rights
            end
            if (length(strs) < 5)
                strs{5} = '0'; % Append default # reversible moves
            end
            strs{6} = '1'; % Overwrite turn #
            
            % Parse pieces positions
            replace = '${repmat(''_'',1,double($1) - 48)}';
            pos = regexprep(strs{1},'(\d)',replace);
            pieces = cell2mat(flipud(regexp(pos,'/','split')'))';
            assert(numel(pieces) == 64); % Sanity check
            
            % Convert pieces to board state
            state = zeros(8,8,'uint8');
            bInds = isstrprop(pieces,'lower');
            pieces = upper(pieces);
            symbols = Move.SYMBOLS;
            for i = 1:length(symbols)
                state(pieces == symbols(i)) = i;
            end
            state(bInds) = bitset(state(bInds),8);
            
            % Parse turn color
            colorStr = strs{2};
            if strcmpi(colorStr,'w')
                % White to move
                posInfo.colorToMove = ChessPiece.WHITE;
            elseif strcmpi(colorStr,'b')
                % Black to move
                posInfo.colorToMove = ChessPiece.BLACK;
            else
                % Invalid turn color argument
                error('Invalid turn color');
            end
            
            % Parse castling rights
            castleRights = strs{3};
            if ismember('K',castleRights)
                % Allow white kingside castling
                state([5 8],1) = bitset(state([5 8],1),7);
            end
            if ismember('Q',castleRights)
                % Allow white queenside castling
                state([1 5],1) = bitset(state([1 5],1),7);
            end
            if ismember('k',castleRights)
                % Allow black kingside castling
                state([5 8],8) = bitset(state([5 8],8),7);
            end
            if ismember('q',castleRights)
                % Allow black queenside castling
                state([1 5],8) = bitset(state([1 5],8),7);
            end
            
            % Parse en-passant square
            EPstr = strs{4};
            if ~strcmp(EPstr,'-')
                % Record square
                i = find(Move.FILES == lower(EPstr(1)));
                j = find(Move.RANKS == EPstr(2));
                state(i,j) = bitset(state(i,j),6);
            end
            
            % Parse reversible halfmove count
            posInfo.reversibleMoves = str2double(strs{5});
            assert(~isnan(posInfo.reversibleMoves)); % Sanity check
            
            % Return final state encoding
            FENstr = sprintf('%s %s %s %s',strs{1:4});
            posInfo.FENstr = sprintf('%s %s %s',FENstr,strs{5:6});
            posInfo.isStdStartPos = strcmp(FENstr,startpos);
            posInfo.state = state;
        end
        
        %
        % Generate FEN string from board state encoding
        %
        function FENstr = GenerateFEN(state,color,revMoves,turnNumber)
        % Syntax:   FENstr = GenerateFEN(state,color);
        % Syntax:   FENstr = GenerateFEN(state,color,revMoves);
        % Syntax:   FENstr = GenerateFEN(state,color,revMoves,turnNumber);
            
            % Piece locations
            pcolor = bitget(state,8); % 0 = White, 1 = Black
            pSyms = [Move.SYMBOLS '1'];
            pieces = bitand(state,7);
            pieces(pieces == 0) = length(pSyms);
            plStrs = pSyms(pieces);
            plStrs(pcolor == 0) = upper(plStrs(pcolor == 0));
            plStrs(pcolor == 1) = lower(plStrs(pcolor == 1));
            plStrs = cellstr(flipud(plStrs'));
            fcn = @(str)regexprep(str,'1+','${num2str(length($&))}');
            plStrs = cellfun(fcn,plStrs,'UniformOutput',false);
            
            % Turn color
            switch color
                case ChessPiece.WHITE
                    % White to move
                    tcStr = 'w';
                case ChessPiece.BLACK
                    % Black to move
                    tcStr = 'b';
            end
            
            % Castling
            cStr = '';
            cRights = bitget(state([1 5 8],[1 8]),7);
            if (cRights(2,1) == 1)
                if (cRights(3,1) == 1)
                    % White kingside castle is legal
                    cStr = [cStr 'K'];
                end
                if (cRights(1,1) == 1)
                    % White queenside castle is legal
                    cStr = [cStr 'Q'];
                end
            end
            if (cRights(2,2) == 1)
                if (cRights(3,2) == 1)
                    % Black kingside castle is legal
                    cStr = [cStr 'k'];
                end
                if (cRights(1,2) == 1)
                    % Black queenside castle is legal
                    cStr = [cStr 'q'];
                end
            end
            if isempty(cStr)
                % No valid castles
                cStr = '-';
            end
            
            % En passant
            [i j] = find(bitget(state,6));
            if ~isempty(i)
                % Record en-passant target square
                epStr = [Move.FILES(i) Move.RANKS(j)];
            else
                % No en-passant targets
                epStr = '-';
            end
            
            % Reversible moves
            if (nargin < 3)
                % Default # reversible moves
                revMoves = 0;
            end
            
            % Turn number
            if (nargin < 4)
                % Default turn #
                turnNumber = 1;
            end
            
            % Generate FEN string
            FENstr = sprintf('%s/%s/%s/%s/%s/%s/%s/%s %s %s %s %i %i', ...
                           plStrs{:},tcStr,cStr,epStr,revMoves,turnNumber);
            FENstr = strtrim(FENstr);
        end
        
        %
        % Filter castling rights string
        %
        function cStr = FilterCastlingRights(cStr,state)
            % Check for no castling rights
            if strcmp(cStr,'-')
                return;
            end
            
            % Check for invalid characters
            if ~isempty(regexp(cStr,'[^KQkq]','once'))
                % Invalid
                cStr = '-';
                return;
            end
            
            % Remove repeated characters
            cStr = unique(cStr);
            
            % Handle state info, if given
            if (nargin == 2)
                % White kingside
                Kidx = (cStr == 'K');
                if ~isempty(Kidx)
                    pieces = state([5 8],1);
                    colors = bitget(pieces,8);
                    IDs = bitand(pieces,7);
                    if (any(colors ~= 0) || ...
                       (IDs(1) ~= King.ID) || (IDs(2) ~= Rook.ID))
                        % Invalid
                        cStr(Kidx) = [];
                    end
                end
                
                % White queenside
                Qidx = (cStr == 'Q');
                if ~isempty(Qidx)
                    pieces = state([1 5],1);
                    colors = bitget(pieces,8);
                    IDs = bitand(pieces,7);
                    if (any(colors ~= 0) || ...
                       (IDs(2) ~= King.ID) || (IDs(1) ~= Rook.ID))
                        % Invalid
                        cStr(Qidx) = [];
                    end
                end
                
                % Black kingside
                kidx = (cStr == 'k');
                if ~isempty(kidx)
                    pieces = state([5 8],8);
                    colors = bitget(pieces,8);
                    IDs = bitand(pieces,7);
                    if (any(colors ~= 1) || ...
                       (IDs(1) ~= King.ID) || (IDs(2) ~= Rook.ID))
                        % Invalid
                        cStr(kidx) = [];
                    end
                end
                
                % Black queenside
                qidx = (cStr == 'q');
                if ~isempty(qidx)
                    pieces = state([1 5],8);
                    colors = bitget(pieces,8);
                    IDs = bitand(pieces,7);
                    if (any(colors ~= 1) || ...
                       (IDs(2) ~= King.ID) || (IDs(1) ~= Rook.ID))
                        % Invalid
                        cStr(qidx) = [];
                    end
                end
            end
            
            % Handle empty rights
            if isempty(cStr)
                cStr = '-';
            end
        end
        
        %
        % Filter en passant string
        %
        function epStr = FilterEnPassantTarget(epStr,state)
            % Check for no en passant
            if strcmp(epStr,'-')
                % No en passant
                return;
            end
            
            % Check for valid target square
            if (length(epStr) ~= 2)
                % Invalid string
                epStr = '-';
                return;
            end
            
            % Check files/ranks
            file = sum(find(Move.FILES == lower(epStr(1))));
            rank = sum(find(Move.RANKS == epStr(2)));
            if (~ismember(file,1:8) || ~ismember(rank,[3 6]))
                % Invalid string
                epStr = '-';
                return;
            end
            
            % If no state info
            if (nargin ~= 2)
                % Done
                return;
            end
            
            % Check destination square
            if (bitand(state(file,rank),7) ~= 0)
                % Occupied
                epStr = '-';
                return;
            end
            
            % Process based on target rank
            switch rank
                case 3
                    % Should be white pawn @(file,4)
                    targetRank = 4;
                    pawnColor = 0;                        
                case 6
                    % Should be black pawn @(file,5)
                    targetRank = 5;
                    pawnColor = 1;
            end
            
            % Check captured pawn position
            piece = state(file,targetRank);
            color = bitget(piece,8);
            ID = bitand(piece,7);
            if ((ID ~= Pawn.ID) || (color ~= pawnColor))
                % Invalid
                epStr = '-';
                return;
            end
        end
        
        %
        % Add castling/en-passant rights to state encoding
        %
        function state = AddRightsToState(state,cStr,epStr)
            % White kingside castling
            if ismember('K',cStr)
                state([5 8],1) = bitset(state([5 8],1),7);
            end
            
            % White queenside castling
            if ismember('Q',cStr)
                state([1 5],1) = bitset(state([1 5],1),7);
            end
            
            % Black kingside castling
            if ismember('k',cStr)
                state([5 8],8) = bitset(state([5 8],8),7);
            end
            
            % Black queenside castling
            if ismember('q',cStr)
                state([1 5],8) = bitset(state([1 5],8),7);
            end
            
            % En passant target
            if ~strcmp(epStr,'-')
                file = find(Move.FILES == epStr(1));
                rank = find(Move.RANKS == epStr(2));
                state(file,rank) = bitset(state(file,rank),6);
            end
        end
    end
end
