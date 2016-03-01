classdef BoardEditor < handle
%
% Class that spawns a GUI for editing the current board position
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
        % GUI constants
        DIM = [400 315];                % Default GUI dimensions, in pixels
        FBORDER = 7;                    % Figure border width, in pixels
        PGAP = 4;                       % Piece panel gap, in pixels
        CONTROL_GAP = 4;                % Inter-object spacing, in pixels
        CONTROL_HEIGHT = 20;            % Object panel heights, in pixels
        
        % Font sizes
        LABEL_SIZE = 12 - 2 * ispc;     % UI panel font size
        FONT_SIZE = 10 - 2 * ispc;      % GUI font size
        
        % Background colors
        ACTIVE = [252 252 252] / 255;   % Active color
        INACTIVE = ([236 236 236] + 4 * ispc) / 255; % Inactive color
    end
    
    %
    % Public GetAccess properties
    %
    properties (GetAccess = public, SetAccess = private)
        % Piece timer
        ptimer;                         % Piece movement timer
        
        % Figure handle
        fig;                            % Figure handle
    end
    
    %
    % Private properties
    %
    properties (Access = private)
        % ChessMaster handle
        CM;                             % Parent handle
        
        % Locks
        glock = false;                  % Graphics lock
        
        % GUI state
        lastFENstr;                     % Last FEN string
        
        % Pieces
        pieces;                         % Piece sprite structure
        file;                           % File coordinates
        rank;                           % Rank coordinates
        CPD;                            % ChessPieceData object
        axOffset;                       % Axis offset, in pixels
        activeSquare = [];              % Active square object
        activePiece = nan;              % Active piece object
        cph = {};                       % ChessPiece handles
        
        % Square highlight
        CHD;                            % Chess highlight data
        CHc;                            % Current piece highlight
        
        % GUI handles
        ax;                             % Axis handle
        uipp;                           % Piece panel handle
        uisp;                           % Setup panel handle
        uibp;                           % Button panel handle
        fh;                             % FEN handles
        mh;                             % Side to move handles
        eh;                             % En passant handles
        ch;                             % Castling handles
        bh;                             % Button handles
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = BoardEditor(CM,pieces,tag,varargin)
        % Syntax:   BE = BoardEditor(CM,pieces,tag,'xyc',xyc);
        %           BE = BoardEditor(CM,pieces,tag,'pos',pos);
            
            % Save inputs
            this.CM = CM;
            this.pieces = pieces;
            
            % Create chess piece data object
            this.CPD = ChessPieceData();
            
            % Initialize piece movement timer
            this.ptimer = timer('Name','PieceMoveTimer', ...
                                'ExecutionMode','FixedRate', ...
                                'TasksToExecute',Inf, ...
                                'Period',this.CM.animationPeriod, ...
                                'TimerFcn',@(s,e)MouseMove(this));
            
            % Initialize GUI
            this.InitializeGUI(tag,varargin{:});
        end
        
        %
        % Get active piece info
        %
        function [ID color] = GetActivePiece(this)
            % Get active piece info from ...
            if ~isnan(this.activePiece)
                % ... active piece
                ID = this.activePiece.ID;
                color = this.activePiece.color;
            elseif ~isempty(this.activeSquare)
                % ... active square
                ID = this.activeSquare.ID;
                color = this.activeSquare.color;
            else
                % ... no active info
                ID = nan;
                color = ChessPiece.NULL;
            end
        end
        
        %
        % Update position
        %
        function UpdatePosition(this)
            % Generate FEN for current setup
            FENstr = this.GetFENforSetup();
            
            % Update ChessMaster
            this.CM.LoadPosition(FENstr);
        end
        
        %
        % Set square highlight sprite
        %
        function SetHighlightSprite(this,color)
            % Set sprite
            this.CHc.SetSprite(this.CHD,color);
        end
        
        %
        % Update setup panel
        %
        function UpdateSetupPanel(this,FENstr)
            % Set FEN string
            this.lastFENstr = FENstr;
            set(this.fh(2),'String',FENstr);
            
            % Set color to move
            chunks = regexp(FENstr,'\s+','split');
            switch chunks{2}
                case 'w'
                    % White to move
                    colorVal = 1;
                case 'b'
                    % Black to move
                    colorVal = 2;
            end
            set(this.mh(2),'Value',colorVal);
            
            % Set castling string
            if (length(chunks) < 3)
                cStr = '-';
            else
                cStr = chunks{3};
            end
            set(this.ch(2),'String',cStr);
            
            % Set en passant string
            if (length(chunks) < 4)
                epStr = '-';
            else
                epStr = chunks{4};
            end
            set(this.eh(2),'String',epStr);
        end
        
        %
        % Close GUI
        %
        function Close(this)
            try
                % Stop piece movement timer, if necessary
                if strcmpi(this.ptimer.Running,'on')
                    % Stop timer
                    stop(this.ptimer);
                end
                
                % Delete piece movement timer
                delete(this.ptimer);
            catch %#ok
                % Graceful exit
            end
            
            try
                % Close GUI
                delete(this.fig);
            catch %#ok
                % Graceful exit
            end
            
            try
                % Tell ChessMaster that BoardEditor is closed
                this.CM.DeleteBoardEditor();
            catch %#ok
                % Graceful exit
            end
            
            try
                % Delete this object
                delete(this);
            catch %#ok
                % Graceful exit
            end
        end
    end
    
    %
    % Private methods
    %
    methods (Access = private)
        %
        % Get mouse location in axis units
        %
        function [x y] = GetMouseLocation(this)
            % Get pointer location on screen
            mpos = get(0,'PointerLocation');
            
            % Convert to axis coordinates
            fpos = get(this.fig,'Position');
            xy = mpos - fpos(1:2) - this.axOffset;
            x = xy(1);
            y = xy(2);
        end
        
        %
        % Get (file,rank) coordinates of (x,y) axis location
        %
        function [i j] = LocateClick(this,x,y)
            % Get file
            i = find(x < this.file,1,'first') - 1;
            if isempty(i)
                i = 0; % off grid
            end
            
            % Get rank
            j = find(y < this.rank,1,'first') - 1;
            if isempty(j)
                j = 0; % off grid
            end
        end
        
        %
        % Get click coordinates
        %
        function [i j] = GetClickCoordinates(this)
            % Get click coordinates
            xy = get(this.ax,'CurrentPoint');
            [i j] = this.LocateClick(xy(1,1),xy(1,2));
            %[x y] = this.GetMouseLocation();
            %[i j] = this.LocateClick(x,y);
        end
        
        %
        % Handle mouse down
        %
        function MouseDown(this)
            % If not processing mouse down events
            if (this.CM.block || this.CM.mlock)
                % Quick return
                return;
            end
            
            % Get click coordinates
            [i j] = this.GetClickCoordinates();
            validClick = ((i >= 1) && (i <= 5) && (j >= 1) && (j <= 2));
            
            % Determine if same square clicked
            if (this.CHc.visible == true)
                isSameSq = ((this.CHc.i == i) && (this.CHc.j == j));
            else
                isSameSq = false;
            end
            
            % Handle click
            if ((validClick == false) || (isSameSq == true))
                % Clear square selection
                this.ClearSquareSelection();
            else
                % Select square
                this.SelectSquare(i,j);
            end
        end
        
        %
        % Handle mouse move
        %
        function MouseMove(this)            
            % If not ready to process mouse movement
            if (~this.CM.mlock || this.glock)
                % Quick return;
                return;
            end
            
            % Update active piece location
            this.glock = true;
            [x y] = this.GetMouseLocation();
            this.activePiece.DrawPieceAt(x,y);
            this.glock = false;
        end
        
        %
        % Handle mouse release
        %
        function MouseUp(this)
            % If mouse lock isn't set
            if (this.CM.mlock == false)
                % Quick return
                return;
            end
            
            % If piece movement timer is running
            if strcmpi(this.ptimer.Running,'on')
                % Stop timer
                stop(this.ptimer);
            end
            
            % Delete ChessMaster floating piece
            [i j] = this.CM.DeleteFloatingPiece();
            
            % If an active piece exists
            if ~isnan(this.activePiece)
                % Extract piece info
                ID = this.activePiece.ID;
                color = this.activePiece.color;
                
                % Delete floating piece
                this.activePiece.Delete();
                this.activePiece = [];
                
                % If move animation is on
                if (this.CM.animateMoves == true)
                    % Clear selection
                    this.ClearSquareSelection();
                end
                
                % If a valid move was suggested
                if (~this.CM.block && (i ~= 0) && (j ~= 0))
                    % Add piece to board
                    this.CM.AddPiece(ID,color,i,j);
                end
            end
        end
        
        %
        % Select square
        %
        function SelectSquare(this,i,j)
            % Set highlight location
            this.CHc.SetLocation(i,j);
            
            % Parse coordinates
            switch j
                case 2
                    % White piece
                    color = ChessPiece.WHITE;
                case 1
                    % Black piece
                    color = ChessPiece.BLACK;
            end
            ID = i; % Assume pieces are in correct order
            
            % If move animation is on
            if (this.CM.animateMoves == true)
                % Create floating piece within ChessMaster
                this.CM.CreateFloatingPiece(ID,color);
                
                % Create floating piece within BoardEditor
                this.activeSquare = [];
                this.activePiece = this.CreatePiece(ID,color);
                this.activePiece.MakeActive();
                start(this.ptimer);
            else
                % Save active square
                this.activeSquare = struct('ID',ID,'color',color);
                this.activePiece = [];
                
                % If there's an active square in ChessMaster
                [i j] = this.CM.GetActiveSquare();
                if ((i ~= 0) && (j ~= 0))
                    % Add piece to board
                    this.CM.AddPiece(ID,color,i,j);
                end
            end
        end
        
        %
        % Clear square selection
        %
        function ClearSquareSelection(this)
            % Clear square selection
            this.CHc.Off();
            this.activeSquare = [];
            this.activePiece = nan;
            this.glock = false;
        end
        
        %
        % Handle keypress
        %
        function HandleKeyPress(this,event)
            % Get keypress
            key = double(event.Character);
            modifiers = event.Modifier;
            
            % Check for ctrl + w
            if (any(ismember(modifiers,{'command','control'})) && ...
                any(ismember(key,[23 87 119])))
                % Close GUI
                this.Close();
                return;
            elseif isempty(key)
                % Quick return
                return;
            end
            
            % If not processing keypress events
            if (this.CM.block || this.CM.animateMoves || this.CM.mlock)
                % Quick return
                return;
            end
            
            % Get current location
            if (this.CHc.visible == false)
                % Quick return
                return;
            end
            i = this.CHc.i;
            j = this.CHc.j;
            
            % Handle keypress
            switch key
                case ChessMaster.LEFT
                    % Move left
                    if (i > 1)
                        % Select left square
                        this.SelectSquare(i - 1,j);
                    end
                case ChessMaster.RIGHT
                    % Move right
                    if (i < 5)
                        % Select right square
                        this.SelectSquare(i + 1,j);
                    end
                case ChessMaster.UP
                    % Move up
                    if (j < 2)
                        % Select above square
                        this.SelectSquare(i,j + 1);
                    end
                case ChessMaster.DOWN
                    % Move down
                    if (j > 1)
                        % Select below square
                        this.SelectSquare(i,j - 1);
                    end
            end
        end
        
        %
        % Reset board
        %
        function ResetBoard(this)
            % Load starting position
            this.CM.ResetBoard();
        end
        
        %
        % Clear board
        %
        function ClearBoard(this)
            % Load empty (only kings) board
            FENstr = '4k3/8/8/8/8/8/8/4K3 w';
            this.CM.LoadPosition(FENstr);
        end
        
        %
        % Load position
        %
        function LoadPosition(this)
            % Get new FEN string
            FENstr = get(this.fh(2),'String');
            
            % Load position
            success = this.CM.LoadPosition(FENstr);
            
            % Handle success
            if (success == true)
                % Save new FEN string
                this.lastFENstr = FENstr;
            else
                % Load last valid FEN string
                set(this.fh(2),'String',this.lastFENstr);
            end
        end
        
        %
        % Get FEN for current setup
        %
        function FENstr = GetFENforSetup(this)
            % Get base encoding
            state = this.CM.GetBaseEncoding();
            
            % Handle color to move
            switch get(this.mh(2),'Value')
                case 1
                    % White to move
                    color = ChessPiece.WHITE;
                case 2
                    % Black to move
                    color = ChessPiece.BLACK;
                otherwise
                    % Something strange happened...
                    color = ChessPiece.WHITE;
                    set(this.mh(2),'Value',1);
            end
            
            % Handle castling string
            cStr = get(this.ch(2),'String');
            cStr = BoardState.FilterCastlingRights(cStr,state);
            set(this.ch(2),'String',cStr);
            
            % Handle en passant string
            epStr = get(this.eh(2),'String');
            epStr = BoardState.FilterEnPassantTarget(epStr,state);
            set(this.eh(2),'String',epStr);
            
            % Save FEN string
            state = BoardState.AddRightsToState(state,cStr,epStr);
            FENstr = BoardState.GenerateFEN(state,color);
            this.lastFENstr = FENstr;
            set(this.fh(2),'String',FENstr);
        end
        
        %
        % Insert piece
        %
        function piece = InsertPiece(this,ID,color,i,j)
            % Create piece
            piece = this.CreatePiece(ID,color);
            
            % Assign board location
            piece.AssignPiece(i,j);
        end
        
        %
        % Create piece
        %
        function piece = CreatePiece(this,ID,color)
            % Process based on piece ID
            switch ID
                case Pawn.ID
                    % Create pawn
                    piece = Pawn(this.ax,[],color,this.CPD);
                case Knight.ID
                    % Create knight
                    piece = Knight(this.ax,[],color,this.CPD);
                case Bishop.ID
                    % Create bishop
                    piece = Bishop(this.ax,[],color,this.CPD);
                case Rook.ID
                    % Create rook
                    piece = Rook(this.ax,[],color,this.CPD);
                case Queen.ID
                    % Create queen
                    piece = Queen(this.ax,[],color,this.CPD);
                case King.ID
                    % Create king
                    piece = King(this.ax,[],color,this.CPD);
                otherwise
                    % Invalid piece ID
                    piece = nan;
            end
        end
        
        %
        % Initialize GUI
        %
        function InitializeGUI(this,tag,varargin)
            % Parse figure position
            if strcmpi(varargin{1},'xyc')
                % GUI center specified
                dim = BoardEditor.DIM; % Default figure dimension
                pos = [(varargin{2} - 0.5 * dim) dim];
            elseif strcmpi(varargin{1},'pos')
                % Position specified directly
                pos = varargin{2};
            end
            
            % Font sizes
            labelSize = BoardEditor.LABEL_SIZE;
            fontSize = BoardEditor.FONT_SIZE;
            
            % Background colors
            active = BoardEditor.ACTIVE;
            inactive = BoardEditor.INACTIVE;
            
            % Create a nice figure
            this.fig = figure('MenuBar','None', ...
                           'NumberTitle','off', ...
                           'DockControl','off', ...
                           'name','Board Editor', ...
                           'tag',tag, ...
                           'Position',pos, ...
                           'Resize','on', ...
                           'ResizeFcn',@(s,e)ResizeComponents(this), ...
                           'WindowButtonDownFcn',@(s,e)MouseDown(this), ...
                           'WindowButtonUpFcn',@(s,e)MouseUp(this), ...
                           'KeyPressFcn',@(s,e)HandleKeyPress(this,e), ...
                           'CloseRequestFcn',@(s,e)Close(this), ...
                           'Visible','off');
            
            %--------------------------------------------------------------
            % Piece panel
            %--------------------------------------------------------------
            % UI panel
            this.uipp = uipanel('Parent',this.fig, ...
                                'Units','pixels', ...
                                'FontUnits','points', ...
                                'FontSize',labelSize, ...
                                'TitlePosition','centertop', ...
                                'Title','Pieces');
            
            % Pieces axis
            this.ax = axes('Units','Pixels', ...
                           'Parent',this.uipp);
            hold(this.ax,'on');
            axis(this.ax,'off');
            
            % Create square highlight
            this.CHc = ChessHighlight(this.ax,[]);
            %--------------------------------------------------------------
            
            %--------------------------------------------------------------
            % Setup panel
            %--------------------------------------------------------------
            % UI panel
            this.uisp = uipanel('Parent',this.fig, ...
                                'Units','pixels', ...
                                'FontUnits','points', ...
                                'FontSize',labelSize, ...
                                'TitlePosition','centertop', ...
                                'Title','Position');
            
            % Current FEN string
            this.fh(1) = uicontrol('Parent',this.uisp, ...
                                   'Style','edit', ...
                                   'Enable','inactive', ...
                                   'Units','pixels', ...
                                   'FontUnits','points', ...
                                   'FontSize',fontSize, ...
                                   'BackgroundColor',inactive, ...
                                   'HorizontalAlignment','center', ...
                                   'String','FEN');
            this.fh(2) = uicontrol('Parent',this.uisp, ...
                                   'Style','edit', ...
                                   'Enable','on', ...
                                   'Units','pixels', ...
                                   'FontUnits','points', ...
                                   'FontSize',fontSize, ...
                                   'BackgroundColor',active, ...
                                   'HorizontalAlignment','left', ...
                                   'Callback',@(s,e)LoadPosition(this));
            
            % Side to move
            this.mh(1) = uicontrol('Parent',this.uisp, ...
                                   'Style','edit', ...
                                   'Enable','inactive', ...
                                   'Units','pixels', ...
                                   'FontUnits','points', ...
                                   'FontSize',fontSize, ...
                                   'BackgroundColor',inactive, ...
                                   'HorizontalAlignment','center', ...
                                   'String',' To move');
            this.mh(2) = uicontrol('Parent',this.uisp, ...
                                   'Style','popup', ...
                                   'Enable','on', ...
                                   'Units','pixels', ...
                                   'FontUnits','points', ...
                                   'BackgroundColor',active, ...
                                   'String','White|Black', ...
                                   'Callback',@(s,e)UpdatePosition(this));
            
            % En passant
            this.eh(1) = uicontrol('Parent',this.uisp, ...
                                   'Style','edit', ...
                                   'Enable','inactive', ...
                                   'Units','pixels', ...
                                   'FontUnits','points', ...
                                   'FontSize',fontSize, ...
                                   'BackgroundColor',inactive, ...
                                   'HorizontalAlignment','center', ...
                                   'String',' En passant');
            this.eh(2) = uicontrol('Parent',this.uisp, ...
                                   'Style','edit', ...
                                   'Enable','on', ...
                                   'Units','pixels', ...
                                   'FontUnits','points', ...
                                   'FontSize',fontSize, ...
                                   'BackgroundColor',active, ...
                                   'HorizontalAlignment','center', ...
                                   'Callback',@(s,e)UpdatePosition(this));
            
            % Castling
            this.ch(1) = uicontrol('Parent',this.uisp, ...
                                   'Style','edit', ...
                                   'Enable','inactive', ...
                                   'Units','pixels', ...
                                   'FontUnits','points', ...
                                   'FontSize',fontSize, ...
                                   'BackgroundColor',inactive, ...
                                   'HorizontalAlignment','center', ...
                                   'String',' Castling');
            this.ch(2) = uicontrol('Parent',this.uisp, ...
                                   'Style','edit', ...
                                   'Enable','on', ...
                                   'Units','pixels', ...
                                   'FontUnits','points', ...
                                   'FontSize',fontSize, ...
                                   'BackgroundColor',active, ...
                                   'HorizontalAlignment','center', ...
                                   'Callback',@(s,e)UpdatePosition(this));
            %--------------------------------------------------------------
            
            %--------------------------------------------------------------
            % Button panel
            %--------------------------------------------------------------
            % UI panel
            this.uibp = uipanel('Parent',this.fig, ...
                                'Units','pixels', ...
                                'Title','');
            
            % Reset button
            this.bh(1) = uicontrol('Style','pushbutton', ...
                      'Parent',this.uibp, ...
                      'Units','pixels', ...
                      'String','Reset', ...
                      'Callback',@(s,e)ResetBoard(this), ...
                      'FontUnits','points', ...
                      'FontSize',fontSize, ...
                      'HorizontalAlignment','center');
            
            % Clear button
            this.bh(2) = uicontrol('Style','pushbutton', ...
                      'Parent',this.uibp, ...
                      'Units','pixels', ...
                      'String','Clear', ...
                      'Callback',@(s,e)ClearBoard(this), ...
                      'FontUnits','points', ...
                      'FontSize',fontSize, ...
                      'HorizontalAlignment','center');
            
            % Done button
            this.bh(3) = uicontrol('Style','pushbutton', ...
                      'Parent',this.uibp, ...
                      'Units','pixels', ...
                      'String','Done', ...
                      'Callback',@(s,e)Close(this), ...
                      'FontUnits','points', ...
                      'FontSize',fontSize, ...
                      'HorizontalAlignment','center');
            %--------------------------------------------------------------
            
            % Resize components
            this.ResizeComponents();
            
            % Create pieces
            this.cph = cell(5,2);
            for i = 1:5
                % White piece
                this.cph{i,1} = this.InsertPiece(i,ChessPiece.WHITE,i,2);
                
                % Black piece
                this.cph{i,2} = this.InsertPiece(i,ChessPiece.BLACK,i,1);
            end
            
            % Make GUI visible
            set(this.fig,'Visible','on');
        end
        
        %
        % Resize components
        %
        function ResizeComponents(this)
            % Get constants
            fds = BoardEditor.FBORDER;
            gap = BoardEditor.PGAP;
            ds = BoardEditor.CONTROL_GAP;
            dy = BoardEditor.CONTROL_HEIGHT;
            ff1 = 1.5; % uipanel fudge factor, in pixels
            ff2 = 5; % piece axis fudge factor, in pixels
            
            % Get figure position
            pos = get(this.fig,'Position');
            xyc = pos(1:2) + 0.5 * pos(3:4);
            dimw = pos(3);
            
            % Compute optimal piece sizes
            sizes = [this.pieces.size];
            dimws = 5 * sizes + 2 * (fds + gap);
            [~,idx] = min(abs(dimw - dimws));
            ssq = sizes(idx);
            
            % Compute GUI sizes
            dimw = 5 * ssq + 2 * fds + 2 * gap;
            dx = (dimw - 2 * fds - 4 * ds) / 3;
            posCalc = @(i,j) [(i * ds + (i - 1) * dx) ...
                              (j * ds + (j - 1) * dy) dx dy];
            pDim = [(5 * ssq + 2 * gap + ff1) ...
                    (2 * ssq + 2 * gap + 0.55 * dy)];
            sDim = [(3 * dx + 4 * ds + ff1) (3.65 * dy + 4 * ds)];
            bDim = [(3 * dx + 4 * ds + ff1) (dy + 2 * ds + ff1)];
            dim = [(dimw + ff1) (4 * fds + pDim(2) + sDim(2) + bDim(2))];
            this.file = ssq * (0:5);
            this.rank = ssq * (0:2);
            this.axOffset = gap + [fds (3 * fds + bDim(2) + sDim(2))];
            
            % Update piece panel
            ppos = [fds (3 * fds + bDim(2) + sDim(2)) pDim];
            set(this.uipp,'Position',ppos);
            
            % Update axes
            axpos = [-ff2 0 (5 * ssq + 2 * gap) (2 * ssq + 2 * gap)];
            axlim = [-gap (5 * ssq + gap) -gap (2 * ssq + gap)];
            set(this.ax,'Position',axpos);
            axis(this.ax,axlim);
            
            % Update search panel
            spos = [fds (2 * fds + bDim(2)) sDim];
            set(this.uisp,'Position',spos);
            
            % Update search uicontrols
            fhh = 3 * ds + 2 * dy;
            pos1 = [ds fhh (0.5 * dx) dy];
            pos2 = [(2 * ds + 0.5 * dx) fhh (2.5 * dx + ds) dy];
            set(this.fh(1),'Position',pos1);
            set(this.fh(2),'Position',pos2);
            set(this.mh(1),'Position',posCalc(1,2));
            set(this.mh(2),'Position',posCalc(1,1));
            set(this.eh(1),'Position',posCalc(2,2));
            set(this.eh(2),'Position',posCalc(2,1));
            set(this.ch(1),'Position',posCalc(3,2));
            set(this.ch(2),'Position',posCalc(3,1));
            
            % Update button panel
            bpos = [fds fds bDim];
            set(this.uibp,'Position',bpos);
            
            % Update buttons
            set(this.bh(1),'Position',posCalc(1,1));
            set(this.bh(2),'Position',posCalc(2,1));
            set(this.bh(3),'Position',posCalc(3,1));
            
            % Update pieces
            this.CPD.file = this.file;
            this.CPD.rank = this.rank;
            this.CPD.squareSize = ssq;
            this.CPD.White = this.pieces(idx).White;
            this.CPD.Black = this.pieces(idx).Black;
            for k = 1:numel(this.cph)
                % Redraw piece
                this.cph{k}.DrawPiece();
            end
            
            % Update square highlight
            this.CHD = struct('file',this.file, ...
                              'rank',this.rank, ...
                              'squareSize',ssq);
            this.CHc.SetSprite(this.CHD);
            
            % Set figure position
            set(this.fig,'Position',[(xyc - 0.5 * dim) dim]);
        end
    end
end
