classdef ChessClock < handle
%
% Class that spawns a chess clock GUI
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
        % Timing constants
        CRUNCH_TIME = 15;               % "Crunch time" threshold, in secs
        
        % GUI sizing
        DIM = [315 330];                % Default GUI dims, in pixels
        FBORDER = 7;                    % Figure border width, in pixels
        ABORDER = 7;                    % Axis border width, in pixels
        CONTROL_GAP = 4;                % Inter-object spacing, in pixels
        CONTROL_HEIGHT = 20;            % Object panel heights, in pixels
        CONTROL_WIDTH = 80;             % Object panel widths, in pixels
        
        % Font sizes
        LABEL_SIZE = 12 - 2 * ispc;     % UI panel label size
        FONT_SIZE = 10 - 2 * ispc;      % GUI font size
        
        % Colors
        ACTIVE = [252 252 252] / 255;   % Active color
        INACTIVE = ([236 236 236] + 4 * ispc) / 255; % Inactive color
        ON_BACK1 = [39 110 239] / 255;  % Ticking timer background #1
        ON_BACK2 = [204 51 51] / 255;   % Ticking timer background #2
        ON_FORE = [255 255 255] / 255;  % Ticking timer foreground
        OFF_BACK = 'None';              % Off timer background
        OFF_FORE = [0 0 0];             % Off timer foreground
    end
    
    %
    % Public GetAccess properties
    %
    properties (GetAccess = public, SetAccess = private)
        % Time control state
        isRunning;                      % Running flag
        activeColor;                    % Active color
        clockIdx;                       % Current clock move index
        timeControl;                    % Time control structure
        timeHistory;                    % Time history structure
        wPeriod;                        % White's time control period
        bPeriod;                        % Black's time control period
        wTime;                          % Seconds on white's clock
        bTime;                          % Seconds on black's clock
        wMoves;                         % # white moves this period
        bMoves;                         % # black moves this period
        
        % Figure properties
        fig;                            % Figure handle
    end
    
    %
    % Private properties
    %
    properties (Access = private)   
        % Chess Master GUI
        CM;                             % ChessMaster handle
        
        % Clock timer
        clock;                          % Clock object
        timerobj;                       % Timer object
        noTime = struct('time',-1, ...  % "No time" info structure
                        'period',0, ...
                        'moves',0);
        
        % GUI variables
        ax;                             % Time control axis
        uiph;                           % uipanel handle
        uih;                            % uicontrol handle
        wtimeh;                         % White time handle
        btimeh;                         % Black time handle
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = ChessClock(CM,tcStr,times,tag,varargin)
        % Syntax:   TC = ChessClock(CM,tcStr,times,tag,'xyc',xyc);
        %           TC = ChessClock(CM,tcStr,times,tag,'pos',pos);
        
            % Save ChessMaster handle
            this.CM = CM;
            
            % Initialize move-analysis timer
            this.timerobj = timer('Name','TimeControlTimer', ...
                                 'ExecutionMode','FixedRate', ...
                                 'StartDelay',0.1, ...
                                 'Period',0.1, ...
                                 'TasksToExecute',Inf, ...
                                 'TimerFcn',@(s,e)UpdateTimes(this,false));
            
            % Initialize GUI
            this.InitializeGUI(tcStr,tag,varargin{:});
            
            % Load clock times, if necessary
            if ~isempty(times)
                this.LoadTimes(times);
            end
        end
        
        %
        % Revert clock to state immediately after the given halfmove
        %
        function SetClockState(this,idx)
            % If clock is already set
            if (idx == this.clockIdx)
                % Update display
                this.UpdateDisplay();
                
                % Quick return
                return;
            end
            
            % Stop timer, if necessary
            if (this.isRunning == true)
                this.StopTimer();
            end
            
            % Set clock index
            this.clockIdx = idx;
            
            % Determine active color
            if ((idx + 1) > length(this.timeHistory))
                % No time control info available
                wState = this.noTime;
                bState = this.noTime;
            elseif mod(idx,2)
                % White just moved
                this.activeColor = ChessPiece.BLACK;
                wState = this.timeHistory(idx + 1);
                bState = this.timeHistory(idx);
            else
                % Black just moved
                this.activeColor = ChessPiece.WHITE;
                wState = this.timeHistory(max(idx,1));
                bState = this.timeHistory(idx + 1);
            end
            
            % Load white clock state
            this.wTime = wState.time;
            this.wPeriod = wState.period;
            this.wMoves = wState.moves;
            
            % Load black clock state
            this.bTime = bState.time;
            this.bPeriod = bState.period;
            this.bMoves = bState.moves;
            
            % Update times
            this.UpdateTimes(false);
        end
        
        %
        % Toggle clock
        %
        function ToggleClock(this)
            % If clock is running
            if (this.isRunning == true)
                % Update times (with new move recorded)
                this.UpdateTimes(true);
            else
                % Clear (now invalid) time info
                this.timeHistory((this.clockIdx + 2):end) = [];
            end
        end
        
        %
        % Update clock orientation
        %
        function UpdateClockOrientation(this)            
            % Update axis orientation
            flipped = this.CM.boardFlipped;
            whiteFirst = (this.CM.firstColorToMove == ChessPiece.WHITE);
            if (flipped ~= whiteFirst)
                % First-to-play on bottom
                set(this.ax,'YDir','Normal');
            else
                % First-to-play on top
                set(this.ax,'YDir','Reverse');
            end
        end
        
        %
        % Get clock data
        %
        function [tcStr times] = GetClockData(this)
            % If time controls are still valid
            if ((this.wTime >= 0) && (this.bTime >= 0))
                % Return time control data
                tcStr = this.timeControl.string;
                times = [this.timeHistory(2:end).time];
            else
                % Time control wasn't followed the whole game
                tcStr = '-';
                times = [];
            end
        end
        
        %
        % Start game clock
        %
        function StartTimer(this)
            % Get valid starting status
            isValidStart = (~this.isRunning && ~this.CM.isGameOver && ...
                           (this.wTime > 0) && (this.bTime > 0));
            
            % If start is valid
            if (isValidStart == true)
                % Set running flag
                this.isRunning = true;
                
                % Update settings panel
                this.UpdateSettings();
                
                % Start move clock
                this.clock = tic;
                
                % Start clock timer
                start(this.timerobj);
            end
        end
        
        %
        % Stop timer
        %
        function StopTimer(this)
            % Stop clock timer
            if strcmpi(this.timerobj.Running,'on')
                % Stop timer object
                stop(this.timerobj);
            end
            
            % Release running flag
            this.isRunning = false;
        end
        
        %
        % Reset timer
        %
        function Reset(this)
            % Stop clock timer
            this.StopTimer();
            
            % Reset state
            this.activeColor = ChessPiece.WHITE;
            this.UpdateClockOrientation();
            
            % Set time control
            this.SetTimeControl();
            
            % Update settings panel
            this.UpdateSettings();
        end
        
        %
        % Close GUI
        %
        function Close(this)
            try
                % Stop timer
                this.StopTimer();
                
                % Delete timer
                delete(this.timerobj);
            catch %#ok
                % Graceful exit
            end
            
            try
                % Remove pointer from ChessMaster memory
                this.CM.DeleteChessClock();
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
        % Load times
        %
        function LoadTimes(this,times)
            % Convert clock times to time history format
            this.timeHistory = this.Times2TimeHistory(times);
            
            % Revert clock state to current move
            this.clockIdx = -1; % Force time update
            this.SetClockState(this.CM.currentMove);
        end
        
        %
        % Convert clock times to time history format
        %
        function timeHistory = Times2TimeHistory(this,times)
            % Get current time control
            periods = this.timeControl.periods;
            
            % If no time controls
            if isempty(periods)
                % Return "no time" structure
                timeHistory = this.noTime;
                return;
            end
            
            % Initialize time histroy
            times = [periods(1).time times(:)']; % Prepend starting time
            timeHistory = struct('time',num2cell(times), ...
                                 'period',1, ...
                                 'moves',0);
            
            % Iterate through times
            per = [1 1];
            moves = [0 0];
            for i = 2:length(times)
                % Increment move count
                j = 1 + mod(i,2);
                moves(j) = moves(j) + 1;
                
                % If a time control was reached
                if (moves(j) >= periods(per(j)).moves)
                    % Advance period, if necessary
                    if (periods(per(j)).repeat == false)
                        per(j) = per(j) + 1;
                    end
                    
                    % Reset move counter
                    moves(j) = 0;
                end
                
                % Record period/moves
                timeHistory(i).period = per(j);
                timeHistory(i).moves = moves(j);
            end
        end
        
        %
        % Handle win on time
        %
        function WinOnTime(this)
            % Stop timer
            this.StopTimer();
            
            % Update settings panel
            this.UpdateSettings();
            
            % Tell ChessMaster GUI about time-based win
            if (this.bTime <= 0)
                % White won
                color = ChessPiece.WHITE;
            else
                % Black won
                color = ChessPiece.BLACK;
            end
            this.CM.WinOnTime(color);
        end
        
        %
        % Set time control
        %
        function SetTimeControl(this)
            % Get time control string
            str = regexprep(get(this.uih(2),'String'),'\s+','');
            
            try
                % Parse time control
                tc.string = str;
                tc.periods = ChessClock.ParseTimeControl(str);
                
                % Save time control
                this.timeControl = tc;
            catch ME
                % Warn user that time control was bad
                warning(ME.identifier,ME.message);
                
                % Revert to last valid time control
                tc = this.timeControl;
                set(this.uih(2),'String',tc.string);
            end
            
            % Initialize time history
            if strcmpi(tc.string,'-')
                % No time control
                this.timeHistory = this.noTime;
            else
                % First period time control
                move = struct('time',tc.periods(1).time, ...
                              'period',1, ...
                              'moves',0);
                this.timeHistory = move;
            end
            
            % Revert clock state to current move
            this.clockIdx = -1; % Force time update
            this.SetClockState(this.CM.currentMove);
        end
        
        %
        % Initialize GUI
        %
        function InitializeGUI(this,defTimeCtrl,tag,varargin)
            % Parse figure position
            if strcmpi(varargin{1},'xyc')
                % GUI center specified
                dim = ChessClock.DIM; % Default figure dimension
                pos = [(varargin{2} - 0.5 * dim) dim];
            elseif strcmpi(varargin{1},'pos')
                % Position specified directly
                pos = varargin{2};
            end
            
            % Get font sizes
            labelSize = ChessClock.LABEL_SIZE;
            fontSize = ChessClock.FONT_SIZE;
            
            % Generate a nice figure
            this.fig = figure('MenuBar','none', ...
                            'NumberTitle','off', ...
                            'DockControl','off', ...
                            'name','Chess Clock', ...
                            'tag',tag, ...
                            'Position',pos, ...
                            'Resize','on', ...
                            'ResizeFcn',@(s,e)ResizeComponents(this), ...
                            'KeyPressFcn',@(s,e)HandleKeyPress(this,e), ...
                            'CloseRequestFcn',@(s,e)Close(this), ...
                            'Interruptible','on', ...
                            'Visible','on');
            
            %--------------------------------------------------------------
            % Clock panel
            %--------------------------------------------------------------
            % Clock uipanel
            this.uiph(1) = uipanel('Parent',this.fig, ...
                                'Units','pixels', ...
                                'FontSize',labelSize, ...
                                'TitlePosition','centertop', ...
                                'Title','Clock');
            
            % Timer axis
            this.ax = axes('Parent',this.uiph(1), ...
                           'Units','pixels', ...
                           'XLimMode','manual', ...
                           'YLimMode','manual', ...
                           'XLim',[-1 1], ...
                           'YLim',[-1 1], ...
                           'Visible','off');
            hold(this.ax,'all');
            
            % Time text
            this.wtimeh = text('Parent',this.ax, ...
                               'Position',[0 -0.5], ...
                               'FontUnits','normalized', ...
                               'FontSize',0.35, ...
                               'FontWeight','bold', ...
                               'HorizontalAlignment','center', ...
                               'VerticalAlignment','middle', ...
                               'Visible','on');
            this.btimeh = text('Parent',this.ax, ...
                               'Position',[0 0.5], ...
                               'FontUnits','normalized', ...
                               'FontSize',0.35, ...
                               'FontWeight','bold', ...
                               'HorizontalAlignment','center', ...
                               'VerticalAlignment','middle', ...
                               'Visible','on');
            %--------------------------------------------------------------
            
            %--------------------------------------------------------------
            % Settings panel
            %--------------------------------------------------------------
            % Settings uipanel
            this.uiph(2) = uipanel('Parent',this.fig, ...
                                   'Units','pixels', ...
                                   'FontSize',labelSize, ...
                                   'TitlePosition','centertop', ...
                                   'Title','Settings');
            
            % Time control
            this.uih(1) = uicontrol('Parent',this.uiph(2),...
                                    'Units','pixels', ...
                                    'Style','edit',...
                                    'FontSize',fontSize, ...
                                    'HorizontalAlignment','left', ...
                                    'String',' Time Control');
            this.uih(2) = uicontrol('Parent',this.uiph(2),...
                                    'Units','pixels', ...
                                    'Style','edit',...
                                    'FontSize',fontSize, ...
                                    'HorizontalAlignment','center', ...
                                    'String',defTimeCtrl, ...
                                    'Callback',@(s,e)SetTimeControl(this));
            this.uih(3) = uicontrol('Parent',this.uiph(2),...
                                    'Units','pixels', ...
                                    'Style','pushbutton',...
                                    'FontSize',fontSize, ...
                                    'HorizontalAlignment','center', ...
                                    'String','Start', ...
                                    'Callback',@(s,e)StartTimer(this));
            %--------------------------------------------------------------
            
            % Reset GUI
            this.Reset();
            
            % Resize components
            this.ResizeComponents();
            
            % Set figure to visible
            set(this.fig,'Visible','on');
        end
        
        %
        % Update settings panel
        %
        function UpdateSettings(this)
            % If clock can't be started right now
            if (this.isRunning || this.CM.isGameOver || ...
               (this.CM.gameplayMode == ChessMaster.EDIT) || ...
               (this.wTime < 0) && (this.bTime < 0))
                % Disable all settings elemnents
                set(this.uih,'Enable','off');
            else
                % Enable time control elements
                this.EnableUIcontrol(this.uih(1),'inactive');
                this.EnableUIcontrol(this.uih(2),'on');
                set(this.uih(3),'Enable','on');
            end
        end
        
        %
        % Update time panel
        %
        function UpdateTimes(this,newMove)
            %--------------------------------------------------------------
            % Update clock times
            %--------------------------------------------------------------            
            % If clock is running and the game isn't over
            if ((this.isRunning == true) && (this.CM.isGameOver == false))
                % Get some stuff
                color = this.activeColor; % Active color
                periods = this.timeControl.periods; % Time control periods
                
                % Update move time
                switch color
                    case ChessPiece.WHITE
                        % Update white time
                        this.wTime = this.wTime - toc(this.clock);
                    case ChessPiece.BLACK
                        % Update black time
                        this.bTime = this.bTime - toc(this.clock);
                end
                this.clock = tic;
                
                % If a new move was made
                if (newMove == true)
                    % Apply move increment
                    switch color
                        case ChessPiece.WHITE
                            % Apply white increment
                            inc = periods(this.wPeriod).inc;
                            this.wTime = this.wTime + inc;
                            this.wMoves = this.wMoves + 1;
                        case ChessPiece.BLACK
                            % Apply black increment
                            inc = periods(this.bPeriod).inc;
                            this.bTime = this.bTime + inc;
                            this.bMoves = this.bMoves + 1;
                    end
                end
                
                % Handle white time period progression
                if (this.wMoves >= periods(this.wPeriod).moves)
                    % If period isn't perpetual
                    if (periods(this.wPeriod).repeat == false)
                        % Increment period counter
                        this.wPeriod = this.wPeriod + 1;
                    end
                    
                    % Apply period increment
                    this.wTime = this.wTime + periods(this.wPeriod).time;
                    this.wMoves = 0;
                end
                
                % Handle black time period progression
                if (this.bMoves >= periods(this.bPeriod).moves)
                    % If period isn't perpetual
                    if (periods(this.bPeriod).repeat == false)
                        % Increment period counter
                        this.bPeriod = this.bPeriod + 1;
                    end
                    
                    % Apply period increment
                    this.bTime = this.bTime + periods(this.bPeriod).time;
                    this.bMoves = 0;
                end
                
                % Clip times to zero
                this.wTime = max(this.wTime,0);
                this.bTime = max(this.bTime,0);
                
                % If a new move was made
                if (newMove == true)
                    % Get clock state for the active color
                    switch color
                        case ChessPiece.WHITE
                            % Save white clock state
                            move = struct('time',this.wTime, ...
                                          'period',this.wPeriod, ...
                                          'moves',this.wMoves);
                        case ChessPiece.BLACK
                            % Save black clock state
                            move = struct('time',this.bTime, ...
                                          'period',this.bPeriod, ...
                                          'moves',this.bMoves);
                    end
                    
                    % Update clock index
                    this.clockIdx = this.clockIdx + 1;
                    
                    % Append clock state to time history
                    this.timeHistory(this.clockIdx + 1) = move;
                    
                    % Toggle active color
                    this.activeColor = ChessPiece.Toggle(color);
                end
            end
            %--------------------------------------------------------------
            
            % Update display
            this.UpdateDisplay();
            
            % Check for game over
            if (((this.wTime <= 0) || (this.bTime <= 0)) && ...
                 (this.isRunning == true))
                % Handle win on time
                this.WinOnTime();
            end
        end
        
        %
        % Update clock display
        %
        function UpdateDisplay(this)
            % Handle color
            switch this.activeColor
                case ChessPiece.WHITE
                    % White to move
                    if (this.wTime > ChessClock.CRUNCH_TIME)
                        % Normal-time background
                        wbg = ChessClock.ON_BACK1;
                    else
                        % Hurry-up background
                        wbg = ChessClock.ON_BACK2;
                    end
                    wfg = ChessClock.ON_FORE;
                    bbg = ChessClock.OFF_BACK;
                    bfg = ChessClock.OFF_FORE;
                case ChessPiece.BLACK
                    % Black to move
                    wbg = ChessClock.OFF_BACK;
                    wfg = ChessClock.OFF_FORE;
                    if (this.bTime > ChessClock.CRUNCH_TIME)
                        % Normal-time background
                        bbg = ChessClock.ON_BACK1;
                    else
                        % Hurry-up background
                        bbg = ChessClock.ON_BACK2;
                    end
                    bfg = ChessClock.ON_FORE;
                otherwise
                    % No one to move
                    wbg = ChessClock.OFF_BACK;
                    wfg = ChessClock.OFF_FORE;
                    bbg = ChessClock.OFF_BACK;
                    bfg = ChessClock.OFF_FORE;
            end
            
            % Update white time
            wstr = this.PrettyTime(this.wTime);
            set(this.wtimeh,'String',wstr, ...
                            'BackgroundColor',wbg, ...
                            'Color',wfg);
            
            % Update black time
            bstr = this.PrettyTime(this.bTime);
            set(this.btimeh,'String',bstr, ...
                            'BackgroundColor',bbg, ...
                            'Color',bfg);
            
            % Update settings panel
            this.UpdateSettings();
        end
        
        %
        % Handle key press
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
            end
        end
        
        %
        % Resize GUI components
        %
        function ResizeComponents(this)
            % Get constants
            fds = ChessClock.FBORDER;
            ads = ChessClock.ABORDER;
            dt = ChessClock.CONTROL_GAP;
            dw = ChessClock.CONTROL_WIDTH;
            dy = ChessClock.CONTROL_HEIGHT;
            
            % Get figure dimensions
            pos = get(this.fig,'Position');
            xfig = pos(3);
            yfig = pos(4);
            
            % Resize figure, if necessary
            xmin = 2 * fds + 3.45 * dt + 2 * dw;
            ymin = 3 * fds + 2 * ads + 3 * dt + 3.25 * dy + 20;
            if ((xfig < xmin) || (yfig < ymin))
                xfig = max([xfig xmin]);
                yfig = max([yfig ymin]);
                set(this.fig,'Position',[pos(1:2) xfig yfig]);
            end
            
            % Compute uipanel dimensions
            dx = xfig - 2 * fds + 2;
            dys = 2.75 * dy + 3 * dt;
            dyc = yfig - 3 * fds - dys;
            
            %--------------------------------------------------------------
            % Update clock panel
            %--------------------------------------------------------------
            % Update uipanel position
            set(this.uiph(1),'Position',[fds (2 * fds + dys) dx dyc]);
            
            % Update axis position
            dxa = dx - 2 * ads;
            dya = dyc - 2 * ads - 0.5 * dy;
            set(this.ax,'Position',[ads ads dxa dya]);
            %--------------------------------------------------------------
            
            %--------------------------------------------------------------
            % Update settings panel
            %--------------------------------------------------------------
            % Update uipanel position
            set(this.uiph(2),'Position',[fds fds dx dys]);
            
            % Update uicontrol positions
            pos1 = [dt (2 * dt + dy) dw dy];
            set(this.uih(1),'Position',pos1);
            pos2 = [(2 * dt + dw) (2 * dt + dy) (dx - 3.45 * dt - dw) dy];
            set(this.uih(2),'Position',pos2);
            pos3 = [dt dt (dx - 2.45 * dt) dy];
            set(this.uih(3),'Position',pos3);
            %--------------------------------------------------------------
        end
    end
    
    %
    % Public static methods
    %
    methods (Access = public, Static = true)
        %
        % Parse time control string
        %
        function periods = ParseTimeControl(str)
            % Check for no time control
            if (isempty(str) || strcmpi(str,'-') || strcmpi(str,'?'))
                % No time control
                periods = struct([]);
                return;
            end
            
            try
                % Separate into periods
                strs = regexp(str,':','split');
                n = length(strs); assert(n > 0);
                
                % Initialize periods structure
                period = struct('inc',0, ...
                                'moves',inf, ...
                                'time',0, ...
                                'repeat',false);
                periods = repmat(period,[1 n]);
                
                % Loop over periods
                for i = 1:n
                    % Extract increment info
                    str_inc = regexp(strs{i},'+','split'); 
                    len = length(str_inc); assert(len <= 2);
                    if (len ~= 1)
                        % Move increment specified
                        val = str2double(str_inc{2}); assert(~isnan(val));
                        periods(i).inc = val;
                    end
                    
                    % Extract move info
                    time = regexp(str_inc{1},'/','split');
                    len = length(time); assert(len <= 2);
                    if ((len ~= 1) && ~strcmpi(time{1},'G'))
                        % Move count specified
                        val = str2double(time{1});
                        assert(~isnan(val) && (floor(val) == val));
                        periods(i).moves = val;
                    end
                    
                    % Extract time info
                    val = str2double(time{end}); assert(~isnan(val));
                    periods(i).time = val;
                    
                    % Extract period repeat status
                    if ((i == n) && isfinite(periods(i).moves))
                        % Repeat time control until game is over
                        periods(i).repeat = true;
                    end
                end
            catch %#ok
                % Inform user that time control was bad
                msgid = 'CC:BAD_TIME_CONTROL';
                msg = 'Time control "%s" is invalid/unsupported';
                error(msgid,msg,str);
            end
        end
        
        %
        % Format time (in seconds) as a pretty string
        %
        function timeStr = PrettyTime(time)
            % Quick check for negative time
            if (time < 0)
                % Return empty string
                timeStr = '';
                return;
            end
            
            % Round time ...
            if (time <= ChessClock.CRUNCH_TIME)
                % ... to nearest tenth of a second
                crunchTime = true;
                time = 0.1 * round(10 * time);
            else
                % ... to nearest second
                crunchTime = false;
                time = round(time);
            end
            
            % Extract HH:MM:SS
            hh = floor(time / 3600); % Hours
            rem = mod(time,3600);
            mm = floor(rem / 60); % Minutes
            rem = mod(rem,60);
            ss = floor(rem); % Seconds
            tt = round(10 * (rem - ss)); % Tenths
            
            % Generate pretty time string
            if (hh > 0)
                if (crunchTime == true)
                    % H:MM:SS.T
                    timeStr = sprintf('%d:%02d:%02d.%d',hh,mm,ss,tt);
                else
                    % H:MM:SS
                    timeStr = sprintf('%d:%02d:%02d',hh,mm,ss);                    
                end
            else
                if (crunchTime == true)
                    % MM:SS.T
                    timeStr = sprintf('%02d:%02d.%d',mm,ss,tt);
                else
                    % MM:SS
                    timeStr = sprintf('%02d:%02d',mm,ss);
                end
            end
        end
    end
    
    %
    % Private static methods
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
                    set(uih,'BackgroundColor',ChessClock.ACTIVE);
                case 'inactive'
                    % Change to inactive color
                    set(uih,'BackgroundColor',[0 0 0]);
                    set(uih,'BackgroundColor',ChessClock.INACTIVE);
                %case 'off'
                    % Empty
            end
        end
    end
end
