classdef Move < handle
%
% Class that generates objects describing moves
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
    % NOTE: The elements of SYMBOLS *MUST* coincide with the ID values
    %       defined in the chess piece classes
    %
    properties (GetAccess = public, Constant = true)
        % PGN string formatting
        SYMBOLS = 'PNBRQK';     % Piece symbols
        FILES = 'abcdefgh';     % File symbols
        RANKS = '12345678';     % Rank symbols
    end
    
    %
    % Public GetAccess properties
    %
    properties (GetAccess = public, SetAccess = private)
        % Set via constructor
        editMode;               % Edit mode flag
        ID;                     % Piece ID
        color;                  % Piece color
        fromi;                  % Original file
        fromj;                  % Original rank
        toi;                    % Destination file
        toj;                    % Destination rank
        
        % Set via AddPromotion() and AddCapture() methods after creation
        capture = nan;          % Captured piece handle
        pawn = nan;             % Promoted pawn handle
        promotion = nan;        % Promoted piece handle
        
        % Move strings (non-edit mode)
        SANstr = '';            % SAN move string
        LANstr = '';            % LAN move string
        
        % Board state variables (non-edit mode)
        reversible = true;      % Reversibility of this move
        reversibleMoves = 0;    % Number halfmoves since capture/pawn move
        state = nan;            % Encoded board state
    end
    
    %
    % Private properties
    % 
    properties (Access = private)
        % Board state
        BS;                     % Board state handle
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = Move(piece,i,j,editFlag)
            % Allow empty constructor call
            if (nargin == 0)
                return;
            end
            
            % Save edit mode
            this.editMode = ((nargin == 4) && (editFlag == true));
            
            % Save board state handle
            this.BS = piece.BS;
            
            % Save move data
            this.ID = piece.ID;
            this.color = piece.color;
            this.fromi = piece.i;
            this.fromj = piece.j;
            this.toi = i;
            this.toj = j;
            
            % If in edit mode
            if (this.editMode == true)
                % Quick return;
                return;
            end
            
            % Pawn moves are not reversible
            if (this.ID == Pawn.ID)
                this.reversible = false;
            end

            % Generate base move strings, if necessary
            % NOTE: captures, promotions, checks, etc. added later
            this.GenerateBaseSAN();
            this.LANstr = Move.GenerateLAN(this.fromi,this.fromj,i,j);
        end
        
        %
        % Add a promotion to the move
        %
        function AddPromotion(this,pawn,prom)
            % Store piece handles
            this.pawn = pawn;
            this.promotion = prom;
            
            % Add promotion symbol move strings
            this.SANstr = [this.SANstr '=' Move.SYMBOLS(prom.ID)];
            this.LANstr = [this.LANstr lower(Move.SYMBOLS(prom.ID))];
            
            % Promotions are not reversible
            this.reversible = false;
        end
        
        %
        % Add a capture to the move
        %
        function AddCapture(this,piece)
            % Store captured piece handle
            this.capture = piece;
            
            % If in edit mode
            if (this.editMode == true)
                % Quick return;
                return;
            end
            
            % Splice capture symbol into move string
            len = length(this.SANstr) - 2 * sum(ismember(this.SANstr,'='));
            this.SANstr = [this.SANstr(1:(len - 2)) 'x' ...
                           this.SANstr((len - 1):end)];
            
            % By convertion, captures by pawns must include departure file
            if ((this.ID == Pawn.ID) && (len < 3))
                % Prepend departure file
                df = Move.FILES(this.fromi);
                this.SANstr = [df this.SANstr];
            end
            
            % Captures are not reversible
            this.reversible = false;
        end
        
        %
        % Add check to move
        %
        function AddCheck(this)
            % Append check symbol
            this.SANstr = [this.SANstr '+'];
        end
        
        %
        % Add checkmate to move
        %
        function AddCheckmate(this)
            % Replace '+' with '#'
            this.SANstr(end) = '#';
        end
        
        %
        % Increment the reversible halfmoves count
        %
        function IncRevMoves(this)
            % Increment count
            this.reversibleMoves = this.BS.GetReversibleMoves() + 1;
        end
        
        %
        % Encode board state
        %
        function EncodeBoardState(this)
            % Get base encoding
            bstate = this.BS.BaseEncoding();
            
            % Get local copy of piece info
            pID = this.ID;
            fi = this.fromi;
            fj = this.fromj;
            ti = this.toi;
            tj = this.toj;
            
            % Check for en passant rights
            if (pID == Pawn.ID)
                dj = (tj - fj);
                if (abs(dj) == 2)
                    % Add en passant rights to *target* square 
                    jt = tj - sign(dj);
                    bstate(ti,jt) = bitset(bstate(ti,jt),6);
                end
            end
            
            % Check for king movement/castling
            if ((pID == King.ID) || (pID == Rook.ID))
                % Remove castling rights
                bstate(fi,fj) = bitset(bstate(fi,fj),7,0);
                
                % Check for castling itself
                if ((pID == King.ID) && (abs(fi - ti) == 2))
                    % Castle, so remove castling rights on rook too
                    if (ti == 7)
                        % Kingside castle
                        bstate(8,tj) = bitset(bstate(8,tj),7,0);
                    else
                        % Queenside castle
                        bstate(1,tj) = bitset(bstate(1,tj),7,0);
                    end
                end
            end
            
            % Save encoded board state
            this.state = bstate;
        end
    end
    
    %
    % Private methods
    %
    methods (Access = private)
        %
        % Generate base SAN (standard algebraic notation) move string
        % 
        % NOTE: Captures, promotions, and checks are added later
        %
        function GenerateBaseSAN(this)
            % Local copy some piece info
            pID = this.ID;
            fi = this.fromi;
            fj = this.fromj;
            ti = this.toi;
            tj = this.toj;
            
            % Check for castling
            if ((pID == King.ID) && ((ti - fi) == 2))
                % Kingside castle
                this.SANstr = 'O-O';
            elseif ((pID == King.ID) && ((fi - ti) == 2))
                % Queenside castle
                this.SANstr = 'O-O-O';
            else
                % Get piece ID string
                p = Move.SYMBOLS(pID);
                if (pID == Pawn.ID)
                    p = ''; % By convention, pawn symbol is omitted
                end
                
                % Get target file and rank symbols
                tf = Move.FILES(ti);
                tr = Move.RANKS(tj);
                
                % Find all pieces that could have moved to (toi,toj)
                pieces = this.BS.Attackers(ti,tj,this.color,pID);
                n = length(pieces);
                
                % Format string
                if (n == 1)
                    % Only this piece could have made the move
                    this.SANstr = [p tf tr];
                else 
                    % See if departure file resolves ambiguity
                    count = 0;
                    for k = 1:n
                        if (pieces{k}.i == fi)
                            count = count + 1;
                        end
                    end
                    if (count == 1)
                        % Add departure file to string
                        df = Move.FILES(fi);
                        this.SANstr = [p df tf tr];
                    else
                        % See if departure rank resolves ambiguity
                        count = 0;
                        for k = 1:n
                            if (pieces{k}.j == fj)
                                count = count + 1;
                            end
                        end
                        if (count == 1)
                            % Add departure rank to string
                            dr = Move.RANKS(fj);
                            this.SANstr = [p dr tf tr];
                        else
                            % Must use both file and rank
                            df = Move.FILES(fi);
                            dr = Move.RANKS(fj);
                            this.SANstr = [p df dr tf tr];
                        end
                    end
                end
            end
        end
    end
    
    %
    % Public static methods
    %
    methods (Access = public, Static = true)
        %
        % Generate LAN (long algebraic notation) move string
        %
        function LANstr = GenerateLAN(fromi,fromj,toi,toj,promID)
            try
                % Generate LAN string
                LANstr = [Move.FILES(fromi) Move.RANKS(fromj) ...
                          Move.FILES(toi)   Move.RANKS(toj)];
                
                % Append promotion, if necessary
                if (nargin == 5)
                    LANstr = [LANstr lower(Move.SYMBOLS(promID))];
                end
            catch %#ok
                % Coordinates were invalid, so return empty string
                LANstr = '';
            end
        end
        
        %
        % Parse LAN (long algebraic notation) move string
        %
        function [fromi fromj toi toj promID] = ParseLAN(LANstr)
            % Get origin coordinates
            fromi = find(lower(LANstr(1)) == Move.FILES);
            fromj = find(LANstr(2) == Move.RANKS);
            
            % Get destination coordinates
            toi = find(lower(LANstr(3)) == Move.FILES);
            toj = find(LANstr(4) == Move.RANKS);
            
            % Ensure that coordinates are nonempty
            if (isempty(fromi) || isempty(fromj) || ...
                isempty(toi)   || isempty(toj))
                % Throw an error
                msgid = 'MOVE:INVALID_LAN';
                msg = 'Invalid LAN string';
                error(msgid,msg);
            end
            
            % Handle promotions
            if (length(LANstr) >= 5)
                % Found a promotion
                promID = find(upper(LANstr(5)) == Move.SYMBOLS);
            else
                % No promotion
                promID = [];
            end
        end
        
        %
        % Parse SAN (standard algebraic notation) move string based on the
        % given board state and turn color
        %
        function [fromi fromj toi toj promID] = ParseSAN(SANstr,BS,color)
            % Check for castling
            if strcmp(SANstr,'O-O')
                % Kingside castle
                if (color == ChessPiece.WHITE)
                    rank = 1; % White's home rank
                else
                    rank = 8; % White's home rank
                end
                fromi = 5;
                fromj = rank;
                toi = 7;
                toj = rank;
                promID = [];
                return;
            elseif strcmp(SANstr,'O-O-O')
                % Queenside castle
                if (color == ChessPiece.WHITE)
                    rank = 1; % White's home rank
                else
                    rank = 8; % White's home rank
                end
                fromi = 5;
                fromj = rank;
                toi = 3;
                toj = rank;
                promID = [];
                return;
            end
            
            % Check for promotions
            promstr = SANstr(find(ismember(SANstr,'=')):end);
            if ~isempty(promstr)
                % Found a promotion
                promID = find(upper(SANstr(end)) == Move.SYMBOLS);
                
                % Remove it from the move string
                SANstr = SANstr(1:(end - 2));
            else
                % No promotions
                promID = [];
            end
            
            % Get destination coordinates
            toi = find(lower(SANstr(end - 1)) == Move.FILES);
            toj = find(SANstr(end) == Move.RANKS);
            
            % Get origin coordinates
            if (length(SANstr) == 5)
                % Both coordinates were given
                fromi = find(lower(SANstr(2)) == Move.FILES);
                fromj = find(SANstr(3) == Move.RANKS);
            else
                % Get white pieces with given ID that could have moved
                % to (toi,toj)
                pieceID = find(upper(SANstr(1)) == Move.SYMBOLS);
                pieces = BS.Attackers(toi,toj,color,pieceID); %#ok
                
                % Process based on what information was supplied
                if (length(pieces) == 1)
                    % No coordinates needed to parse move
                    fromi = pieces{1}.i;
                    fromj = pieces{1}.j;
                else
                    % One coordinate needed to resolve identity
                    if isstrprop(SANstr(2),'alpha')
                        % File was specified
                        fromi = find(lower(SANstr(2)) == Move.FILES);
                        
                        % Find the corresponding rank
                        idx = 1;
                        while (pieces{idx}.i ~= fromi)
                            idx = idx + 1;
                        end
                        fromj = pieces{idx}.j;
                    else
                        % Rank was specified
                        fromj = find(SANstr(2) == Move.RANKS);
                        
                        % Find the corresponding file
                        idx = 1;
                        while (pieces{idx}.j ~= fromj)
                            idx = idx + 1;
                        end
                        fromi = pieces{idx}.i;
                    end
                end
            end
        end
    end
end
