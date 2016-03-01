classdef BoardGeometry < handle
%
% Class that manages chessboard geometry
%
% NOTE: This class is used internally by the ChessMaster GUI and is not
%       intended for public invocation
%
% Brian Moore
% brimoor@umich.edu
%

    %
    % Private constants
    %
    properties (GetAccess = private, Constant = true)
        % Screen constants
        SCREEN_BUFFER = 60 + 45 * ispc; % Screen size buffer, in pixels
        
        % Board size constants
        BORDER = 0.45;                  % Relative border size
        BOUNDARY = 0.05;                % Relative boundary size
        TURN_MARKER = 0.25;             % Relative turn marker size
        
        % Font sizes
        BOARD_FONT = 0.3;               % Relative board font size
        CHECK_FONT = 0.25;              % Relative check text font size
    end
    
    %
    % Public GetAccess properties
    %
    properties (GetAccess = public, SetAccess = private)
        % Board geometry
        squareSize;                     % Square size
        borderSize;                     % Border size
        boundarySize;                   % Boundary size
        boardPadding;                   % Total board padding
        boardDim;                       % Total board dimension
        turnMarkerSize;                 % Turn marker size
        axLim;                          % Axis limits
        bdLim;                          % Board image limits
        
        % Board coordinates
        file;                           % File corner coordinates
        rank;                           % Rank corner coordinates
        filec;                          % File center coordinates
        rankc;                          % Rank center coordinates
        file_textc;                     % File text coordinates
        rank_textc;                     % Rank text coordinates
        tcpos_white;                    % White coordinates
        tcpos_black;                    % Black coordinates
        
        % Graphics data
        CPD;                            % ChessPieceData object
        CHD;                            % Chess highlight data
        
        % Font sizes
        bfont;                          % Board font size
        cfont;                          % Check text font size
    end
    
    %
    % Private properties
    %
    properties (Access = private)
        % Piece data
        pieces;                         % Available piece sprites
        
        % Screen data
        maxDim;                         % Maximum allowed GUI size
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = BoardGeometry(pieces)
        % Syntax:   BG = BoardGeometry(pieces);
        
            % Save piece sprites
            this.pieces = pieces;
            
            % Create chess piece data object
            this.CPD = ChessPieceData();
        end
        
        %
        % Set board geometry
        %
        function SetBoardGeometry(this,dim)
            % Get constants
            ssz = get(0,'ScreenSize');
            buf = BoardGeometry.SCREEN_BUFFER;
            bdr = BoardGeometry.BORDER;
            bdy = BoardGeometry.BOUNDARY;
            tsz = BoardGeometry.TURN_MARKER;
            bsz = BoardGeometry.BOARD_FONT;
            csz = BoardGeometry.CHECK_FONT;
            
            % Compute optimal piece sizes
            sizes = [this.pieces.size];
            dims = (8 + 2 * (bdr + bdy)) * sizes;
            dims(dims > (min(ssz(3:4)) - buf)) = inf;
            [~,idx] = min(abs(dim - dims));
            ssq = sizes(idx);
            
            % Set board geometry
            tms = round(ssq * tsz);
            sbdr = round(ssq * bdr);
            sbdy = round(ssq * bdy);
            btot = sbdr + sbdy;
            dim = 2 * btot + 8 * ssq;
            this.squareSize = ssq;
            this.borderSize = sbdr;
            this.boundarySize = sbdy;
            this.boardPadding = btot;
            this.boardDim = dim;
            this.turnMarkerSize = tms;
            this.axLim = 0.5 + [0 dim 0 dim];
            this.bdLim = [1 dim];
            
            % Set file/rank coordinates
            db = 0.5 * (sbdr - 1);
            tmPos = tms * [-0.5 -0.5 1 1];
            corners = btot + 1 + ssq * (0:8);
            this.file = corners;
            this.rank = corners;
            this.filec = 0.5 * (corners(1:8) + corners(2:9) - 1);
            this.rankc = 0.5 * (corners(1:8) + corners(2:9) - 1);            
            this.file_textc = [(1 + db) (dim - db)];
            this.rank_textc = [(1 + db) (dim - db)];
            this.tcpos_white = [([(dim - db)  (1 + db)  0 0] + tmPos);
                                ([ (1 + db)   (1 + db)  0 0] + tmPos)];
            this.tcpos_black = [([(dim - db) (dim - db) 0 0] + tmPos);
                                ([ (1 + db)  (dim - db) 0 0] + tmPos)];
            
            % Save chess piece data
            this.CPD.file = this.file;
            this.CPD.rank = this.rank;
            this.CPD.squareSize = this.squareSize;
            this.CPD.White = this.pieces(idx).White;
            this.CPD.Black = this.pieces(idx).Black;
            
            % Save chess highlight data
            this.CHD = struct('file',this.file, ...
                              'rank',this.rank, ...
                              'squareSize',this.squareSize);
            
            % Set font sizes
            this.bfont = round(ssq * bsz);
            this.cfont = round(ssq * csz);
        end
        
        %
        % Generate board image with given color theme
        %
        function I = GenerateBoardImage(this,color)
            % Get board dimensions
            sbdr = this.borderSize;
            ssq = this.squareSize;
            btot = this.boardPadding;
            dim = this.boardDim;
            
            % Install border
            cbdr = permute(color.border,[1 3 2]);
            I = repmat(cbdr,[dim dim]);
            
            % Install boundary
            cbdy = permute(color.boundary,[1 3 2]);
            bdry = repmat(cbdy,[dim dim] - 2 * sbdr);
            I((sbdr + 1):(dim - sbdr),(sbdr + 1):(dim - sbdr),:) = bdry;
            
            % Create (constant) light square
            sql = this.ConstantSquare(ssq,color.light);
            
            % Create (diagonal gradient) dark square
            sqd = this.GradientSquare(ssq,color.dark1,color.dark2);
            
            % Install squares
            light_sq = false;
            idx = btot + 1 + ssq * (0:8);
            for i = 1:8
                % Toggle square color
                light_sq = ~light_sq;
                
                for j = 1:8
                    % Toggle square color
                    light_sq = ~light_sq;
                    
                    % Install squares
                    idxx = idx(i):(idx(i + 1) - 1);
                    idxy = idx(j):(idx(j + 1) - 1);
                    if (light_sq == true)
                        % Light square
                        I(idxx,idxy,:) = sql;
                    else
                        % Dark square
                        I(idxx,idxy,:) = sqd;
                    end
                end
            end
            
            % Convert to uint8
            I = uint8(round(I));
        end
    end
    
    %
    % Private static methods
    %
    methods (Access = private, Static = true)
        %
        % Generate constant square of given size/color
        %
        function square = ConstantSquare(sz,c)
            % Create constant square
            c = permute(c,[1 3 2]);
            square = repmat(c,[sz sz]);
        end
        
        %
        % Generate gradient square of given size/colors
        %
        function square = GradientSquare(sz,c1,c2)            
            % Interpolate colors
            c1 = permute(c1,[1 3 2]);
            c2 = permute(c2,[1 3 2]);
            inds = bsxfun(@plus,(1:sz)',(0:(sz - 1)));
            Nc = 2 * sz - 1;
            colors = repmat(c1,[1 Nc]) + ...
                            bsxfun(@times,0:(Nc - 1),(c2 - c1) / (Nc - 1));
            
            % Create gradient square
            square = zeros(sz,sz,3);
            for ii = 1:sz
                for jj = 1:sz
                    square(ii,jj,:) = colors(1,inds(ii,jj),:);
                end
            end
        end
    end
end
