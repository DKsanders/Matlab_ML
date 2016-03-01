classdef GameAnalyzer < handle
%
% Class that spawns a game analyzer GUI
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
        % CPU usage
        MAX_CPU = 1;                    % Max CPU in [0 1] given to engine
        
        % Analysis constants
        PAUSE_TIME = 0.1;               % Time between move analysis events
        
        % Engine search mode "enum"
        NODES_SEARCH = 1;               % Nodes-based search
        DEPTH_SEARCH = 2;               % Depth-based search
        TIME_SEARCH = 3;                % Time-based search
        
        % Move analysis "enum"
        INACCURACY = 0.3;               % Inaccuracy threshold
        MISTAKE = 0.9;                  % Mistake threshold
        BLUNDER = 2.0;                  % Blunder threshold
        
        % GUI constants
        ADIM = [450 275];               % Analysis panel dims, in pixels
        CONTROL_WIDTH = 200;            % Object panel widths, in pixels
        CONTROL_HEIGHT = 20;            % Object panel heights, in pixels
        STATS_HEIGHT = 12;              % Stats uicontrol height, in pixels
        FBORDER = 7;                    % Figure border width, in pixels
        EBORDER = 4;                    % Engine panel spacing, in pixels
        ABORDER = 6;                    % Analysis panel spacing, in pixels
        SBORDER = 4;                    % Stats panel spacing, in pixels
        EDX = [0.1 0.25 0.4 0.25];      % Engine group relative widths
        SDX = [0.6 0.15 0.25];          % Stats group relative widths
        POPUP_DX = 0.95;                % Popup relative width
        BUTTON_DX = 0.7;                % Button relative width
        
        % Axis parameters
        EFONT_SIZE = 10 - 2 * ispc;     % Engine font size, in points
        SFONT_SIZE = 10 - 2 * ispc;     % Stats font size, in points
        MFONT_SIZE = 12 - 2 * ispc;     % Move font size, in points
        LFONT_SIZE = 12 - 2 * ispc;     % Label size, in points
        MARKER_SIZE = 25;               % Current move marker size
        MAX_SCORE = 10;                 % Max absolute score
        
        % Analysis colors
        LIGHT_YELLOW = [255 242 200] / 255; % Light yellow
        LIGHT_GREEN = [103 195 78] / 255;   % Light green
        LIGHT_BLUE = [128 155 190] / 255;   % Light blue
        DARK_GREEN = [68 184 36] / 255;     % Dark green
        DARK_BLUE = [99 132 179] / 255 ;    % Dark blue
        
        % Background colors
        ACTIVE = [252 252 252] / 255;   % Active color
        INACTIVE = ([236 236 236] + 4 * ispc) / 255; % Inactive color
        RUNNING = [51 51 204] / 255;    % Running color
        STOP = [204 51 51] / 255;       % Stop color
    end
    
    %
    % Public GetAccess properties
    %
    properties (GetAccess = public, SetAccess = private)
        % Engine variables
        engineList;                     % List of available engines
        engineIdx;                      % Active engine index
        
        % Locks
        alock = false;                  % Auto-analysis lock
        block = false;                  % Best position analysis lock
        clock = false;                  % Current position analysis lock
        tlock = false;                  % Engine thinking lock
        
        % Figure properties
        fig;                            % Figure handle
    end
    
    %
    % Private properties
    %
    properties (Access = private)
        % ChessMaster handle
        CM;                             % ChessMaster handle
        
        % Engine interface
        EI = EngineInterface.empty(1,0);% EngineInterface object
        
        % Analysis timer
        timerobj;                       % Asynchronous move-analysis timer
        
        % Engine variables (with defaults set)
        searchMode = GameAnalyzer.TIME_SEARCH; % Search mode state
        searchVals = [1e5 15 0.5];             % Search values
        
        % Internal variables
        newGame;                        % New game flag
        bestOpening;                    % Best opening move
        moves;                          % Moves info structure array
        LANstrs = {};                   % LAN string list
        SANstrs = {};                   % SAN string list
        Nmoves = 0;                     % Total number of moves
        maIdx = 0;                      % Last analyzed index
        labelPos = 0;                   % Move label position
        axDim;                          % Current axis dimensions
        epDim;                          % Engine panel dimensions
        spDim;                          % Stats panel dimensions
        
        % GUI handles
        uiap;                           % Analysis uipanel handle
        uiep;                           % Engine uipanel handle
        uisp;                           % Stats uipanel handle
        eh;                             % Engine uicontrol handles
        sh;                             % Stats uicontrol handles
        ax;                             % Axis handle
        ph = nan(4,0);                  % Patch handles
        cp;                             % Current point handle
        tb;                             % Current point textbox
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = GameAnalyzer(CM,engines,tag,varargin)
        % Syntax:   GA = GameAnalyzer(CM,engines,tag,'xyc',xyc);
        %           GA = GameAnalyzer(CM,engines,tag,'pos',pos);
        
            % Save ChessMaster handle
            this.CM = CM;
            
            % Save engine info
            this.engineList = engines.list;
            this.engineIdx = engines.idx;
            
            % Initialize move-analysis timer
            this.timerobj = timer('Name','GameAnalyzerTimer', ...
                                  'ExecutionMode','FixedRate', ...
                                  'StartDelay',0, ...
                                  'Period',GameAnalyzer.PAUSE_TIME, ...
                                  'TasksToExecute',Inf, ...
                                  'TimerFcn',@(s,e)EngineAnalysis(this));
            
            % Initialize GUI
            this.InitializeGUI(tag,varargin{:});
            
            % Initialize engine
            this.ChangeEngine();
        end
        
        %
        % Append moves to list *after* the given index
        %
        function AppendMoves(this,LANstrs,SANstrs,idx)
            % Decrement analysis index, if necessary
            this.maIdx = min(this.maIdx,idx);
            
            % Clear previous moves, if necessary
            if (idx < this.Nmoves)
                this.LANstrs((idx + 1):end) = [];
                this.SANstrs((idx + 1):end) = [];
                this.ClearAnalysisPanel(idx + 1);
            end
            
            % Save new moves
            n = length(LANstrs);
            this.LANstrs((idx + 1):(idx + n)) = LANstrs;
            this.SANstrs((idx + 1):(idx + n)) = SANstrs;
            this.Nmoves = length(this.LANstrs);
            
            % Update analysis graphics
            this.ph(1:4,(idx + 1):(idx + n)) = nan;
            set(this.ax(1),'XLim',[0 (this.Nmoves + 1)]);
            set(this.ax(2),'XLim',[0 (this.Nmoves + 1)]);
            
            % If auto-analysis mode is engaged
            if (this.alock == true)
                % Kick-off engine analysis
                this.AnalyzeMoves();
            end
        end
        
        %
        % Set move label position
        %
        function SetMoveLabelPosition(this,idx)
            % Draw the move label at the specified x-coordinate
            this.DrawMoveLabel(idx,0);
        end
        
        %
        % Handle game over state
        %
        function HandleGameState(this)
            % If game is over and analysis is finished
            if ((this.CM.isGameOver == true) && ...
                (this.maIdx == this.Nmoves))
                % Release auto lock
                this.ReleaseAutoLock();
                
                % Update engine panel
                this.UpdateEnginePanel();
            end
        end
        
        %
        % Reset game analyzer
        %
        function Reset(this)
            % Block current analyses from posting
            this.newGame = true;
            
            % Loop over valid engines
            for i = 1:length(this.EI)
                % Tell the engines to stop searching immediately
                this.EI(i).SendCommand('stop');
                
                % Tell engine to start new game internally
                this.EI(i).SendCommand('ucinewgame');
            end
            
            % Clear moves data
            this.AppendMoves({},{},0);
            
            % Reset GUI
            this.ResetGUI();
        end
        
        %
        % Close engine interfaces
        %
        function CloseEngineInterfaces(this)
            % Loop over engine interfaces
            for i = 1:length(this.EI)
                % If handle is valid
                if isvalid(this.EI(i))
                    % Delete the interface
                    delete(this.EI(i));
                end
            end
        end
        
        %
        % Close GUI
        %
        function Close(this)
            try
                % Remove pointer from ChessMaster memory
                this.CM.DeleteGameAnalyzer();
            catch %#ok
                % Graceful exit
            end
            
            try
                % Close engine interfaces
                this.CloseEngineInterfaces();
            catch %#ok
                % Graceful exit
            end
            
            try
                % Release auto-lock (stops timer, if necessary)
                this.ReleaseAutoLock();
                
                % Delete analysis timer
                delete(this.timerobj);
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
        % Locate mouse on analysis axis
        %
        function [x y] = LocateMouse(this)
            % Get current mouse coordinates
            xy = get(this.ax(2),'CurrentPoint');
            x = round(xy(1,1));
            y = xy(1,2);
        end
        
        %
        % Handle mouse movement
        %
        function MouseMove(this)
            % Locate mouse
            [x y] = this.LocateMouse();
            
            % Draw move label
            this.DrawMoveLabel(x,y);
        end
        
        %
        % Handle mouse relesae
        %
        function MouseUp(this)
            % Locate mouse
            [x y] = this.LocateMouse();
            
            % If the user clicked an analyzed move
            ms = GameAnalyzer.MAX_SCORE;
            if ((x >= 1) && (x <= this.maIdx) && (y >= -ms) && (y <= ms))
                % Go to the selected move
                this.CM.GoToHalfmove(x);
            end
        end
        
        %
        % Handle key press
        %
        function HandleKeyPress(this,event)
            % Check for ctrl + w
            key = double(event.Character);
            modifiers = event.Modifier;
            if (any(ismember(modifiers,{'command','control'})) && ...
                any(ismember(key,[23 87 119])))
                % Close GUI
                this.Close();
                return;
            elseif isempty(key)
                % Quick return
                return;
            end
            
            % Process based on key press
            switch key
                case ChessMaster.LEFT
                    % Left arrow button pressed
                    this.CM.GoToHalfmove(this.labelPos - 1);
                case ChessMaster.RIGHT
                    % Right arrow button pressed
                    this.CM.GoToHalfmove(this.labelPos + 1);
            end
        end
        
        %
        % Set auto-lock
        %
        function SetAutoLock(this)
            % Set auto-lock
            this.alock = true;
        end
        
        %
        % Release auto-lock
        %
        function ReleaseAutoLock(this)
            % Release auto-lock
            this.alock = false;
            
            % Stop analysis timer, if necessary
            if strcmpi(this.timerobj.Running,'on')
                % Stop timer
                stop(this.timerobj);
            end
        end
        
        %
        % Change the active engine
        %
        function ChangeEngine(this)
            % Get new engine index
            idx = get(this.eh(4,1),'Value') - 1;
            
            try
                % Initialize engine
                this.InitializeEngine(idx);
            catch ME
                % Show the orginal error as a warning
                warning(ME.identifier,ME.message);
                
                % Warn the user that the desired engine failed
                msgid = 'GA:ENGINE_INIT:FAIL';
                msg = '\n\n***** Failed to initialize "%s" *****\n';
                warning(msgid,msg,this.engineList(idx).name);
                
                % Reset engine popup to top
                this.engineIdx = 0;
                set(this.eh(4,1),'Value',1);
            end
            
            % Update engine panel
            this.UpdateEnginePanel();
        end
        
        %
        % Initialize the given engine
        %
        function InitializeEngine(this,idx)
            % Close existing engine interfaces
            this.CloseEngineInterfaces();
            
            % Process based on engine index
            if (idx > 0)
                % Spawn engine interfaces for the desired engine
                path = this.engineList(idx).path;
                maxCPU = 0.5 * GameAnalyzer.MAX_CPU;
                this.EI(1) = EngineInterface([],path,'',maxCPU);
                this.EI(2) = EngineInterface([],path,'',maxCPU);
            else
                % No engine selected
                this.EI = EngineInterface.empty(1,0);
            end
            
            % Save current engine index
            this.engineIdx = idx;
        end
        
        %
        % Handle search mode change
        %
        function ChangeSearchMode(this,i)
            % Save new search mode
            this.searchMode = i;
            
            % Update search mode uicontrols
            this.UpdateSearchMode();
        end
        
        %
        % Update the search mode uicontrols
        %
        function UpdateSearchMode(this)
            % Update (mutually exclusive) uicontrols
            idx = this.searchMode;
            set(this.eh(idx,1),'Value',1);
            set(this.eh(setdiff(1:3,idx),1),'Value',0);
        end
        
        %
        % Handle search value change
        %
        function ChangeSearchVal(this,idx)
            % Get new search value
            val = str2double(get(this.eh(idx,3),'String'));
            if isnan(val)
                % Revert to last used value
                val = this.searchVals(idx);
            end
            
            % Apply formatting
            switch idx
                case GameAnalyzer.NODES_SEARCH
                    % Round and clip from below
                    val = max(0,round(val));
                case GameAnalyzer.DEPTH_SEARCH
                    % Round and clip from below
                    val = max(0,round(val));
                case GameAnalyzer.TIME_SEARCH
                    % Clip from below
                    val = max(0,val);
            end
            
            % Save new value
            this.searchVals(idx) = val;
            
            % Update GUI search values
            this.UpdateSearchVals(idx);
        end
        
        %
        % Update search values on GUI
        %
        function UpdateSearchVals(this,inds)
            % Parse input args
            if (nargin < 2)
                inds = 1:3;
            end
            
            % Loop over value fields
            for idx = inds
                % Update value box
                val = this.searchVals(idx);
                set(this.eh(idx,3),'String',num2str(val));
            end
        end
        
        %
        % Handle analysis button press
        %
        function AnalysisButtonPress(this)
            % Release new game flag
            this.newGame = false;
            
            % Process based on thinking state
            if (this.tlock == true)
                % Tell the engines to stop searching immediately
                this.EI(1).SendCommand('stop');
                this.EI(2).SendCommand('stop');
                
                % Release auto-analysis lock
                this.ReleaseAutoLock();
            elseif (this.alock == true)
                % Release auto-analysis lock
                this.ReleaseAutoLock();
            else
                % Set auto-analysis lock
                this.SetAutoLock();
                
                % Start analyzing moves
                this.AnalyzeMoves();
            end
            
            % Update engine panel
            this.UpdateEnginePanel();
        end
        
        %
        % Analyze moves
        %
        function AnalyzeMoves(this)
            % If best opening isn't computed
            if (isempty(this.bestOpening) && (this.tlock == false))
                % Set thinking lock
                this.tlock = true;
                
                % Compute best opening asynchronously
                ofcn = @(args) RecordBestOpening(this,args.move);
                this.StartEngine(1,{},ofcn);
            end
            
            % Start timer, if necessary
            if strcmpi(this.timerobj.Running,'off')
                % Start analysis timer
                start(this.timerobj);
            else
                % Force immediate analysis
                this.EngineAnalysis();
            end
        end
        
        %
        % Have engine analyze given position
        %
        function EngineAnalysis(this)
            try
                % If not already thinking and there's a move to analyze
                if ((this.tlock == false) && (this.Nmoves > this.maIdx))
                    % Set locks
                    this.tlock = true; % Thinking lock
                    this.clock = true; % Current position lock
                    this.block = true; % Best position lock
                    
                    % Index of move to analyze
                    idx = this.maIdx + 1;
                    
                    % Clear move stats
                    this.ClearStats(idx);
                    
                    % Run "best move" engine asynchronously
                    bm = this.GetBestMove(idx);
                    bmoves = {this.LANstrs{1:(idx - 1)} bm};
                    bfcn = @(args) RecordBestAnalysis(this);
                    this.StartEngine(1,bmoves,bfcn);
                    
                    % Run "current move" engine asynchronously
                    cmoves = this.LANstrs(1:idx);
                    cfcn = @(args) RecordCurrentAnalysis(this,args.move);
                    this.StartEngine(2,cmoves,cfcn);
                end
            catch ME
                % Only throw exception if interfaces weren't deleted
                if all(isvalid(this.EI))
                    % Rethrow exception
                    rethrow(ME);
                end
            end
        end
        
        %
        % Start asynchronous engine thinking
        %
        function StartEngine(this,idx,moves,fcn)
            % Clear leftover info in engines' memory
            this.EI(idx).ClearInfo();
            
            % Ready handshake
            this.EI(idx).ReadyHandshake();
            
            % Initialize engine
            if ~isempty(moves)
                args_pos = struct('moves',{moves});
            end
            if (this.CM.isStdStartPos == true)
                % Standard starting position
                args_pos.startpos = true;
            else
                % Custom starting position
                args_pos.fen = this.CM.startingFENstr;
            end
            this.EI(idx).SendCommand('position',args_pos);
            
            % Kick-off the search
            switch this.searchMode
                case GameAnalyzer.NODES_SEARCH
                    % Nodes-based search
                    args_go.nodes = get(this.eh(1,3),'String');
                case GameAnalyzer.DEPTH_SEARCH
                    % Depth-based search
                    args_go.depth = get(this.eh(2,3),'String');
                case GameAnalyzer.TIME_SEARCH
                    % Time-based search
                    str = get(this.eh(3,3),'String');
                    msec = 1000 * str2double(str);
                    args_go.movetime = num2str(round(msec));
            end
            this.EI(idx).SendCommand('go',args_go);
            
            % Read asynchronously until 'bestmove' is received
            this.EI(idx).ReadUntilCMDa('bestmove',inf,fcn);
        end
        
        %
        % Return best move for given move index
        %
        function bm = GetBestMove(this,idx)
            if (idx > 1)
                % Best move from last position
                bm = this.moves(idx - 1).bm;
            else
                % Best opening
                bm = this.bestOpening;
            end
        end
        
        %
        % Record best opening move
        %
        function RecordBestOpening(this,LANstr)
            % Record best opening
            this.bestOpening = LANstr;
            
            % Release thinking lock
            this.tlock = false;
        end
        
        %
        % Record best position analysis
        %
        function RecordBestAnalysis(this)
            % Record best score
            info = this.EI(1).GetInfo();
            if isfield(info,'score')
                % Update stats
                this.UpdateStats(struct('bestscore',info.score));                
            end
            
            % Release best position lock
            this.block = false;
            
            % If both analyses have finished
            if ((this.clock == false) && (this.newGame == false))
                % Append analysis to display
                this.AppendAnalysis();
            end
        end
        
        %
        % Record current position analysis
        %
        function RecordCurrentAnalysis(this,LANstr)
            % Save best move string
            this.moves(this.maIdx + 1).bm = LANstr;
            
            % Update stats
            this.UpdateStats(this.EI(2).GetInfo());
            
            % Release current position lock
            this.clock = false;
            
            % If both analyses have finished
            if ((this.block == false) && (this.newGame == false))
                % Append analysis to display
                this.AppendAnalysis();
            end
        end
        
        %
        % Append analysis to display
        %
        function AppendAnalysis(this)
            % Get current move
            idx = this.maIdx + 1;
            move = this.moves(idx);
            
            % Make sure the analysis was successful
            if (isempty(move.num) || isempty(move.bnum))
                % Engine never sent 'score' command, so restart analysis
                msg = 'Restarting analysis (no position score received)';
                warning('GA:SCORE:ERROR',msg);
                this.tlock = false;
                return;
            end
            
            % If this isn't the first move
            if (idx > 1)
                % Add patch to graph
                x = idx - [1 0];
                y = [this.moves(x).num];
                this.DrawPatch(x,y);
            end
            
            % If best move wasn't played
            if ~strcmpi(this.LANstrs{idx},this.GetBestMove(idx))
                % Compute loss
                wFirst = (this.CM.firstColorToMove == ChessPiece.WHITE);
                sgn = (2 * mod(idx,2) - 1) * (2 * wFirst - 1);
                loss = max(0,sgn * (move.bnum - move.num));
                this.moves(idx).loss = loss;
                
                % Increment error counters
                if (loss > GameAnalyzer.BLUNDER)
                    % Move was a blunder
                    this.moves(idx).blunder = 1;
                elseif (loss > GameAnalyzer.MISTAKE)
                    % Move was a mistake
                    this.moves(idx).mistake = 1;
                elseif (loss > GameAnalyzer.INACCURACY)
                    % Move was inaccurate
                    this.moves(idx).inaccuracy = 1;
                end
            end
            
            % Update analysis index
            this.maIdx = idx;
            
            % Update stats panel
            this.UpdateStatsPanel();
            
            % Handle game state
            this.HandleGameState();
            
            % Release thinking lock
            this.tlock = false;
            
            % Flush graphics
            this.FlushGraphics();
        end
        
        %
        % Update stats with given engine info
        %
        function UpdateStats(this,info)
            % Parse move number
            idx = this.maIdx + 1;
            wFirst = (this.CM.firstColorToMove == ChessPiece.WHITE);
            sgn = (1 - 2 * mod(idx,2)) * (2 * wFirst - 1);            
            
            % Loop over info fields
            fields = fieldnames(info);
            for j = 1:numel(fields)
                % Process based on field name
                switch fields{j}
                    case 'score'
                        % Save score
                        ms = GameAnalyzer.MAX_SCORE;
                        sobj = info.score;
                        if isfield(sobj,'mate')
                            % Save (signed) Mate-in-x info
                            val = sgn * str2double(sobj.mate);
                            if (val == 0)
                                val = 0; % Avoid tricky -0 string
                                this.moves(idx).num = -sgn * ms;
                            else
                                this.moves(idx).num = sign(val) * ms;
                            end
                            this.moves(idx).sc = ...
                                           sprintf('Mate in %.0f',val);
                        elseif isfield(sobj,'cp')
                            % Save centipawn score
                            val = sgn * 0.01 * str2double(sobj.cp);
                            cval = min(max(val,-ms),ms);
                            this.moves(idx).sc = sprintf('%.2f',val);
                            this.moves(idx).num = cval;
                        end
                    case 'bestscore'
                        % Save best score
                        ms = GameAnalyzer.MAX_SCORE;
                        sobj = info.bestscore;
                        if isfield(sobj,'mate')
                            % Save (signed) Mate-in-x info
                            val = sgn * str2double(sobj.mate);
                            this.moves(idx).bsc = ...
                                           sprintf('Mate in %.0f',val);
                            if (val == 0)
                                this.moves(idx).bnum = -sgn * ms;
                            else
                                this.moves(idx).bnum = sign(val) * ms;
                            end
                        elseif isfield(sobj,'cp')
                            % Save centipawn score
                            val = sgn * 0.01 * str2double(sobj.cp);
                            this.moves(idx).bsc = sprintf('%.2f',val);
                            cval = min(max(val,-ms),ms);
                            this.moves(idx).bnum = cval;
                        end
                end
            end
        end
        
        %
        % Update stats panel
        %
        function UpdateStatsPanel(this)            
            % Process based on first color to move
            Nmvs = this.maIdx;
            if (this.CM.firstColorToMove == ChessPiece.WHITE)
                % White moved first
                Nw = ceil(0.5 * Nmvs);
                Nb = floor(0.5 * Nmvs);
                wIdx = 1;
                bIdx = 2;
            else
                % Black moved first
                Nw = floor(0.5 * Nmvs);
                Nb = ceil(0.5 * Nmvs);
                wIdx = 2;
                bIdx = 1;
            end
            
            % Update white statistics
            if (Nw <= 0)
                % No moves yet
                set(this.sh(2,:,2:3),'String','');
            else
                % Display error counts
                Nwi = sum([this.moves(wIdx:2:Nmvs).inaccuracy]);
                Nwm = sum([this.moves(wIdx:2:Nmvs).mistake]);
                Nwb = sum([this.moves(wIdx:2:Nmvs).blunder]);
                set(this.sh(2,3,2),'String',sprintf('%i ',Nwi));
                set(this.sh(2,2,2),'String',sprintf('%i ',Nwm));
                set(this.sh(2,1,2),'String',sprintf('%i ',Nwb));
                
                % Display error percentages 
                Pwi = 100 * Nwi / Nw;
                Pwm = 100 * Nwm / Nw;
                Pwb = 100 * Nwb / Nw;
                set(this.sh(2,3,3),'String',sprintf('%.1f%% ',Pwi));
                set(this.sh(2,2,3),'String',sprintf('%.1f%% ',Pwm));
                set(this.sh(2,1,3),'String',sprintf('%.1f%% ',Pwb));
            end
            
            % Update black statistics
            if (Nb <= 0)
                % No moves yet
                set(this.sh(1,:,2:3),'String','');
            else
                % Display error counts
                Nbi = sum([this.moves(bIdx:2:Nmvs).inaccuracy]);
                Nbm = sum([this.moves(bIdx:2:Nmvs).mistake]);
                Nbb = sum([this.moves(bIdx:2:Nmvs).blunder]);
                set(this.sh(1,3,2),'String',sprintf('%i ',Nbi));
                set(this.sh(1,2,2),'String',sprintf('%i ',Nbm));
                set(this.sh(1,1,2),'String',sprintf('%i ',Nbb));
                
                % Display error percentages 
                Pbi = 100 * Nbi / Nb;
                Pbm = 100 * Nbm / Nb;
                Pbb = 100 * Nbb / Nb;
                set(this.sh(1,3,3),'String',sprintf('%.1f%% ',Pbi));
                set(this.sh(1,2,3),'String',sprintf('%.1f%% ',Pbm));
                set(this.sh(1,1,3),'String',sprintf('%.1f%% ',Pbb));
            end
        end
        
        %
        % Update engine panel
        %
        function UpdateEnginePanel(this)
            % Update search parameter field states
            if ((this.engineIdx == 0) || (this.alock == true))
                % Disable search fields
                set(this.eh(1:3,:),'Enable','off');
            else
                % Enable search fields
                set(this.eh(1:3,1),'Enable','on');
                this.EnableUIcontrol(this.eh(1:3,3),'on');
                this.EnableUIcontrol(this.eh(1:3,[2 4]),'inactive');
            end
            
            % Update search button state
            if (this.engineIdx == 0)
                % Disable search button
                set(this.eh(4,2),'Enable','off');
            else
                % Enable search button
                set(this.eh(4,2),'Enable','on');
            end
            
            % Update search button text/color
            if (this.alock == true)
                % Disable engine popup
                set(this.eh(4,1),'Enable','off');
                
                % "Stop analysis" button
                runningColor = GameAnalyzer.RUNNING;
                set(this.eh(4,2),'String','Stop Analysis', ...
                                 'BackgroundColor',runningColor, ...
                                 'ForegroundColor',[1 1 1]);
            else
                % Enable engine popup
                this.EnableUIcontrol(this.eh(4,1),'on');
                
                % "Start analysis" button
                offColor = GameAnalyzer.INACTIVE;
                set(this.eh(4,2),'String','Start Analysis', ...
                                 'BackgroundColor',offColor, ...
                                 'ForegroundColor',[0 0 0]);
            end
        end
        
        %
        % Draw move label at the given x-coordinate
        %
        function DrawMoveLabel(this,x,y)
            % Process based on mouse x-coordinate
            ms = GameAnalyzer.MAX_SCORE;
            if ((x < 1) || (x > this.maIdx) || (y < -ms) || (y > ms))
                % Disable move markers
                set(this.cp,'Visible','off');
                set(this.tb,'Visible','off');
                
                % Clear move label position
                this.labelPos = 0;
            else
                % Set move label position
                this.labelPos = x;
                
                % Get move data
                move = this.moves(x);
                sc = move.sc;
                num = move.num;
                bm = this.GetBestMove(x);
                
                % Update current point position
                if (num >= 0)
                    % White-ahead color
                    color = GameAnalyzer.DARK_GREEN;
                else
                    % Black-ahead color
                    color = GameAnalyzer.DARK_BLUE;
                end
                set(this.cp,'XData',x, ...
                            'YData',num, ...
                            'Color',color, ...
                            'Visible','on');
                
                % Generate textbox content
                mv = ceil(x / 2);
                if mod(x,2)
                    dots = '';
                else
                    dots = '... ';
                end
                strs = {sprintf('%i. %s%s',mv,dots,this.SANstrs{x});
                        sprintf('Score: %s',sc)};
                if (move.blunder == 1)
                    strs{2} = [strs{2} ' (Blunder)'];
                    strs{3} = sprintf('Best Move: %s (%s)',bm,move.bsc);
                elseif (move.mistake == 1)
                    strs{2} = [strs{2} ' (Mistake)'];
                    strs{3} = sprintf('Best Move: %s (%s)',bm,move.bsc);
                elseif (move.inaccuracy == 1)
                    strs{2} = [strs{2} ' (Inaccuracy)'];
                    strs{3} = sprintf('Best Move: %s (%s)',bm,move.bsc);
                end
                strs = this.PadStrings(strs); % Pad string lengths
                
                % Set textbox position
                if (x >= (0.5 * this.Nmoves))
                    ds = -10;
                    dir = 'right';
                else
                    ds = 10;
                    dir = 'left';
                end
                if (num > 0)
                    valign = 'top';
                else
                    valign = 'bottom';
                end
                
                % Apply changes
                dx = (x / (this.Nmoves + 1)) * this.axDim(1);
                dy = ((num + ms + 1) / (2 * (ms + 1))) * this.axDim(2);
                set(this.tb,'Position',[(dx + ds) dy 0], ...
                            'HorizontalAlignment',dir, ...
                            'VerticalAlignment',valign, ...
                            'String',strs, ...
                            'Visible','on');
            end
        end
        
        %
        % Draw colored score patch for the given coordinates
        %
        function DrawPatch(this,x,y)
            % Delete any existing graphics at this location
            M = (ishandle(this.ph(:,x(1))) & (this.ph(:,x(1)) ~= 0));
            delete(this.ph(M,x(1)));
            
            % Process based on data signs
            if ((sign(y(1)) ~= sign(y(2))) && (sign(y(2)) ~= 0))
                % x-coordinate where y = 0
                xm = (x(1) * y(2) - y(1) * x(2)) / (y(2) - y(1));
                
                % Plot first triangle
                X = [x(1) x(1) xm]';
                Y = [0 y(1) 0]';
                if (y(1) >= 0)
                    C1 = GameAnalyzer.LIGHT_GREEN;
                    C2 = GameAnalyzer.DARK_GREEN;
                else
                    C1 = GameAnalyzer.LIGHT_BLUE;
                    C2 = GameAnalyzer.DARK_BLUE;
                end
                this.ph(1,x(1)) = patch(X,Y,C1,'EdgeColor','none', ...
                                               'Parent',this.ax(1));
                this.ph(2,x(1)) = plot([x(1) xm],[y(1) 0], ...
                                               '-','Color',C2, ...
                                               'Linewidth',1.5, ...
                                               'Parent',this.ax(1));
                
                % Plot second triangle
                X = [xm x(2) x(2)]';
                Y = [0 y(2) 0]';
                if (y(2) >= 0)
                    C1 = GameAnalyzer.LIGHT_GREEN;
                    C2 = GameAnalyzer.DARK_GREEN;
                else
                    C1 = GameAnalyzer.LIGHT_BLUE;
                    C2 = GameAnalyzer.DARK_BLUE;
                end
                this.ph(3,x(1)) = patch(X,Y,C1,'EdgeColor','none', ...
                                               'Parent',this.ax(1));
                this.ph(4,x(1)) = plot([xm x(2)],[0 y(2)], ...
                                               '-','Color',C2, ...
                                               'Linewidth',1.5, ...
                                               'Parent',this.ax(1));
            else
                % Plot trapezoid
                X = [x(1) x(1) x(2) x(2)]';
                Y = [0 y(1) y(2) 0]';
                if ((y(1) < 0) || (y(2) < 0))
                    C1 = GameAnalyzer.LIGHT_BLUE;
                    C2 = GameAnalyzer.DARK_BLUE;
                else
                    C1 = GameAnalyzer.LIGHT_GREEN;
                    C2 = GameAnalyzer.DARK_GREEN;
                end
                this.ph(1,x(1)) = patch(X,Y,C1,'EdgeColor','none', ...
                                               'Parent',this.ax(1));
                this.ph(2,x(1)) = plot(x,y,'-','Color',C2, ...
                                               'Linewidth',1.5, ...
                                               'Parent',this.ax(1));
            end
        end
        
        %
        % Initialize GUI
        %
        function InitializeGUI(this,tag,varargin)
            % Get constants
            ms = GameAnalyzer.MAX_SCORE;
            adim = GameAnalyzer.ADIM;
            dte = GameAnalyzer.EBORDER;
            dts = GameAnalyzer.SBORDER;
            dx = GameAnalyzer.CONTROL_WIDTH;
            dye = GameAnalyzer.CONTROL_HEIGHT;
            dys = GameAnalyzer.STATS_HEIGHT;
            fds = GameAnalyzer.FBORDER;
            edx = GameAnalyzer.EDX;
            pdx = GameAnalyzer.POPUP_DX;
            bdx = GameAnalyzer.BUTTON_DX;
            sdx = GameAnalyzer.SDX;
            
            % Font sizes
            efontSize = GameAnalyzer.EFONT_SIZE;
            sfontSize = GameAnalyzer.SFONT_SIZE;
            mfontSize = GameAnalyzer.MFONT_SIZE;
            lfontSize = GameAnalyzer.LFONT_SIZE;
            
            % Compute (and save) static panel dimensions
            this.epDim = [(dx + 2.45 * dte) (5.85 * dye + 6 * dte)];
            this.spDim = [(dx + 2.45 * dte) (3.85 * dys + 4 * dts)];
            
            % Parse figure position
            if strcmpi(varargin{1},'xyc')
                % GUI center specified
                dim = [(3 * fds + adim(1) + this.epDim(1)) ...
                       (2 * fds + adim(2))];
                pos = [(varargin{2} - 0.5 * dim) dim];
            elseif strcmpi(varargin{1},'pos')
                % Position specified directly
                pos = varargin{2};
            end
            
            % Setup a nice figure
            this.fig = figure('name','Game Analyzer', ...
                      'tag',tag, ...
                      'MenuBar','none', ...
                      'DockControl','off', ...
                      'NumberTitle','off', ...
                      'Position',pos, ...
                      'WindowKeyPressFcn',@(s,e)HandleKeyPress(this,e), ...
                      'WindowButtonMotionFcn',@(s,e)MouseMove(this), ...
                      'WindowButtonUpFcn',@(s,e)MouseUp(this), ...
                      'ResizeFcn',@(s,e)ResizeComponents(this), ...
                      'CloseRequestFcn',@(s,e)Close(this), ...
                      'Visible','off');
            
            %--------------------------------------------------------------
            % Analysis panel
            %--------------------------------------------------------------
            % Add uipanel
            this.uiap = uipanel(this.fig, ...
                               'Units','pixels', ...
                               'FontUnits','points', ...
                               'FontSize',lfontSize, ...
                               'TitlePosition','centertop', ...
                               'Title','Analysis');
            
            % Add patch axis
            this.ax(1) = axes('Parent',this.uiap, ...
                              'Units','pixels', ...
                              'XLimMode','manual', ...
                              'YLimMode','manual', ...
                              'XLim',[0 (this.Nmoves + 1)], ...
                              'YLim',[-(ms + 1) (ms + 1)], ...
                              'Visible','off');
            hold(this.ax(1),'all');
            
            % Add move label axis
            this.ax(2) = axes('Parent',this.uiap, ...
                              'Units','pixels', ...
                              'XLimMode','manual', ...
                              'YLimMode','manual', ...
                              'XLim',[0 (this.Nmoves + 1)], ...
                              'YLim',[-(ms + 1) (ms + 1)], ...
                              'Visible','off');
            hold(this.ax(2),'all');
            
            % Order axes
            uistack(this.ax(2),'top'); % Send to top of graphics stack
            
            % Add current point marker
            markerSize = GameAnalyzer.MARKER_SIZE;
            this.cp = plot(1,0,'.','MarkerSize',markerSize, ...
                                   'Parent',this.ax(2), ...
                                   'Visible','off');
            
            % Add current move textbox
            lightYellow = GameAnalyzer.LIGHT_YELLOW;
            this.tb = text(1,0,{'',''},'Parent',this.ax(2), ...
                                       'Units','pixels', ...
                                       'HorizontalAlignment','left', ...
                                       'VerticalAlignment','middle', ...
                                       'BackgroundColor',lightYellow, ...
                                       'FontUnits','points', ...
                                       'FontSize',mfontSize, ...
                                       'FontName','Courier', ...
                                       'Visible','off');
            %--------------------------------------------------------------
            
            %--------------------------------------------------------------
            % Engine panel
            %--------------------------------------------------------------
            % Create search uipanel
            xy0 = [(2 * fds + adim(1)) ...
                   (fds + (adim(2) - this.epDim(2)))];
            this.uiep = uipanel('Parent',this.fig, ...
                           'Units','pixels', ...
                           'Position',[xy0 this.epDim], ...
                           'FontUnits','points', ...
                           'FontSize',lfontSize, ...
                           'TitlePosition','centertop', ...
                           'Title','Engine');
            
            % Search types
            strs = {' Nodes',' nodes';' Depth',' plies';' Time',' sec'};
            dxm = (dx - 3 * dte) * edx;
            pos = @(i,j) [(j * dte + sum(dxm(1:(j - 1)))) ...
                          (i * dye + (i + 1) * dte) dxm(j) dye];
            for i = 1:3
                % Search mode selection
                this.eh(i,1) = uicontrol('Parent',this.uiep,...
                           'Units','pixels', ...
                           'Position',pos(i,1), ...
                           'Style','checkbox',...
                           'Callback',@(s,e)ChangeSearchMode(this,i), ...
                           'FontSize',efontSize);
                
                % Field name
                this.eh(i,2) = uicontrol('Parent',this.uiep,...
                           'Units','pixels', ...
                           'Position',pos(i,2), ...
                           'Style','edit',...
                           'FontSize',efontSize, ...
                           'HorizontalAlignment','left', ...
                           'String',strs{i,1});
                
                % Field edit box
                this.eh(i,3) = uicontrol('Parent',this.uiep,...
                           'Units','pixels', ...
                           'Position',pos(i,3), ...
                           'Style','edit',...
                           'FontSize',efontSize, ...
                           'Callback',@(s,e)ChangeSearchVal(this,i), ...
                           'HorizontalAlignment','center');
                
                % Field units
                this.eh(i,4) = uicontrol('Parent',this.uiep,...
                           'Units','pixels', ...
                           'Position',pos(i,4), ...
                           'Style','edit',...
                           'FontSize',efontSize, ...
                           'HorizontalAlignment','left', ...
                           'String',strs{i,2});
            end
            
            % Engine selection popup
            dxp = dx * pdx;
            pos = [(dte + 0.5 * (dx - dxp)) (4 * dye + 5.5 * dte) dxp dye];
            strs = {'<<Choose Engine>>' this.engineList.name};
            this.eh(4,1) = uicontrol('Parent',this.uiep,...
                          'Units','pixels', ...
                          'Position',pos, ...
                          'Style','popup',...
                          'Callback',@(s,e)ChangeEngine(this), ...
                          'FontSize',efontSize, ...
                          'String',strs, ...
                          'Value',this.engineIdx + 1);
            
            % Analysis pushbutton
            pos = [dte dte dx dye] + dx * (1 - bdx) * [0.5 0 -1 0];
            this.eh(4,2) = uicontrol('Parent',this.uiep,...
                          'Units','pixels', ...
                          'Position',pos, ...
                          'FontSize',efontSize, ...
                          'Callback',@(s,e)AnalysisButtonPress(this), ...
                          'Style','pushbutton');
            %--------------------------------------------------------------
            
            %--------------------------------------------------------------
            % Stats panels
            %--------------------------------------------------------------
            dxs = (dx - 2 * dte) * sdx;
            strs = {'Black','White'};
            xy0 = @(i) [(2 * fds + adim(1)) ...
                        (i * fds + (i - 1) * this.spDim(2))];
            for i = 1:2
                % Create stats uipanel
                this.uisp(i) = uipanel('Parent',this.fig, ...
                               'Units','pixels', ...
                               'Position',[xy0(i) this.spDim], ...
                               'FontUnits','points', ...
                               'FontSize',lfontSize, ...
                               'TitlePosition','centertop', ...
                               'Title',strs{i});
                
                % Add move textboxes
                types = {'Blunders:','Mistakes:','Inaccuracies:'};
                pos = @(j,k) [(k * dte + sum(dxs(1:(k - 1)))) ...
                              (j * dts + (j - 1) * dys) dxs(k) dys];
                for j = 1:3
                    for k = 1:3
                       this.sh(i,j,k) = uicontrol('Parent',this.uisp(i),...
                               'Units','pixels', ...
                               'Position',pos(j,k), ...
                               'Style','text', ...
                               'Enable','inactive', ...
                               'FontSize',sfontSize, ...
                               'HorizontalAlignment','right');
                    end
                    set(this.sh(i,j,1),'String',types{j}, ...
                                       'HorizontalAlignment','left');
                end
            end
            %--------------------------------------------------------------
            
            % Clear analysis panel
            this.ClearAnalysisPanel();
            
            % Reset GUI
            this.ResetGUI();
            
            % Resize GUI components
            this.ResizeComponents();
            
            % Make GUI visible
            set(this.fig,'Visible','on');
        end
        
        %
        % Reset GUI
        %
        function ResetGUI(this)
            % Reset game info
            this.bestOpening = '';
            this.newGame = true;
            
            % Release locks
            this.ReleaseAutoLock();
            this.tlock = false;
            
            % Initialize engine panel
            this.UpdateSearchMode();
            this.UpdateSearchVals();
            this.UpdateEnginePanel();
        end
        
        %
        % Clear analysis panel data from given index to most recent move
        %
        function ClearAnalysisPanel(this,idx)
            % Parse input args
            if (nargin < 2)
                idx = 1;
            end
            inds = idx:this.Nmoves;
            
            % Disable move markers
            set(this.cp,'Visible','off');
            set(this.tb,'Visible','off');
            
            % Clear analysis panel data
            M = repmat((1:this.Nmoves) >= idx,4,1);
            delete(this.ph(M & ishandle(this.ph) & (this.ph ~= 0)));
            this.ph = this.ph(:,1:(idx - 1));
            
            % Decrement analysis index, if necessary
            this.maIdx = min(this.maIdx,idx - 1);
            
            % Clear stats
            this.ClearStats(inds);
            
            % Update stats panel
            this.UpdateStatsPanel();
        end
        
        %
        % Clear stats for the given indices
        %
        function ClearStats(this,inds)
            % Default move structure
            defaultMove = struct('bm','', ...
                                 'sc','', ...
                                 'bsc','', ...
                                 'num',[], ...
                                 'bnum',[], ...
                                 'loss',0, ...
                                 'inaccuracy',0, ...
                                 'mistake',0, ...
                                 'blunder',0);
            
            % Reset stats to default values
            if ~isempty(inds)
                % Reset stats to default values
                this.moves(inds) = defaultMove;
            else
                % Initialize moves structure
                this.moves = defaultMove;
            end
        end
        
        %
        % Resize GUI components
        %
        function ResizeComponents(this)
            % Get constants
            fds = GameAnalyzer.FBORDER;
            ads = GameAnalyzer.ABORDER;
            
            % Get figure dimensions
            pos = get(this.fig,'Position');
            xfig = pos(3);
            yfig = pos(4);
            
            % Resize figure, if necessary
            xmin = 3 * fds + this.epDim(1) + 50;
            ymin = 4 * fds + this.epDim(2) + 2 * this.spDim(2);
            if ((xfig < xmin) || (yfig < ymin))
                xfig = max([xfig xmin]);
                yfig = max([yfig ymin]);
                set(this.fig,'Position',[pos(1:2) xfig yfig]);
            end
            
            %--------------------------------------------------------------
            % Update analysis panel size/position
            %--------------------------------------------------------------
            % Update analysis uipanel dimensions
            dxap = xfig - 3 * fds - this.epDim(1) + 2;
            dyap = yfig - 2 * fds + 2;
            set(this.uiap,'Position',[fds fds dxap dyap]);
            
            % Update axis dimensions
            dxax = dxap - 2 * ads;
            dyax = dyap - 2 * ads;
            this.axDim = [dxax dyax];
            set(this.ax(1),'Position',[ads ads dxax dyax]);
            set(this.ax(2),'Position',[ads ads dxax dyax]);
            %--------------------------------------------------------------
            
            % Update engine panel position
            x0ep = 2 * fds + dxap;
            y0ep = fds + (dyap - this.epDim(2));
            set(this.uiep,'Position',[x0ep y0ep this.epDim]);
            
            % Update stats panel positions
            x0sp = 2 * fds + dxap;
            y0sp = @(i) i * fds + (i - 1) * this.spDim(2);
            for i = 1:2
                set(this.uisp(i),'Position',[x0sp y0sp(i) this.spDim]);
            end
        end
        
        %
        % Flush graphics
        %
        function FlushGraphics(this,varargin) %#ok
            if ((nargin < 2) || (varargin{1} == true))
                % Flush graphics
                drawnow;
            end
        end
    end
    
    %
    % Static methods
    %
    methods (Access = private, Static = true)
        %
        % Change the enable state and color of the given uicontrols
        %
        function EnableUIcontrol(uih,str)
            % Make the enable change
            set(uih,'Enable',str);
            
            % ***** HACK: Force background color application on mac *****
            switch str
                case 'on'
                    % change to active color
                    set(uih,'BackgroundColor',[0 0 0]);
                    set(uih,'BackgroundColor',GameAnalyzer.ACTIVE);
                case 'inactive'
                    % Change to inactive color
                    set(uih,'BackgroundColor',[0 0 0]);
                    set(uih,'BackgroundColor',GameAnalyzer.INACTIVE);
                %case 'off'
                    % Empty
            end
        end
        
        %
        % Pad strings with spaces to equalize lengths
        %
        function strs = PadStrings(strs)
            % Compute string lengths
            lens = cellfun(@length,strs);
            mlen = max(lens);
            
            % Loop over strings
            for i = 1:length(strs)
                % Append spaces to equalize lengths
                strs{i} = [strs{i} repmat(' ',[1 (mlen - lens(i))])];
            end
        end
    end
end
