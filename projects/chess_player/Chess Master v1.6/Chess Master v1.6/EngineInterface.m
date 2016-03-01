classdef EngineInterface < handle
%
% Class that handles asynchronous communication with an external chess
% engine using the UCI protocol
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
        % Constants
        PAUSE_TIME = 0.05;          % Pause time after empty stdin read
        DEF_WAIT_TIME = 0.5;        % Default time to wait for stdin
    end
    
    %
    % Public GetAccess properties
    %
    properties (GetAccess = public, SetAccess = private)
        % Engine info
        name = 'Engine';            % Engine name
        author = '??????';          % Engine author
        options = {};               % Engine options
        
        % Locks
        qlock = false;              % Quiet timer-stop lock
        rlock = false;              % Reading lock
        
        % Engine-associated objects
        obj;                        % ChessEngine/GameAnalyzer parent
        EL;                         % EngineLog object
        EO;                         % EngineOptions object
        
        % Paths
        dir;                        % Base directory path
    end
    
    %
    % Private properties
    %
    properties (Access = private)        
        % Engine search info
        info;                       % Info structure
        
        % Communication variables
        p;                          % Engine process
        in;                         % GUI input (engine output) stream 
        out;                        % GUI output (engine input) stream
        timerobj;                   % Asynchronous communication timer
        
        % Internal variables
        uci;                        % UCI commands structure
        maxCPU = 1;                 % Max CPU usage in [0 1]
        registerNow = true;         % Register now flag
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = EngineInterface(obj,path,book,maxCPU,registerNow)
            % Parse input args
            this.obj = obj; % Save communicating object
            if (nargin < 3)
                % No opening book, by default
                book = '';
            end
            if (nargin >= 4)
                % Save max CPU usage
                this.maxCPU = maxCPU;
            end
            if (nargin >= 5)
                % Save register now flag
                this.registerNow = registerNow;
            end
            
            % Save base directory
            this.dir = this.GetBaseDir();
            
            % Load UCI protocol
            this.uci = EngineInterface.UCIFields();
            
            % Spawn engine log
            this.EL = EngineLog();
            
            % Open communication link
            this.OpenLink(path);
            
            % Initialize asynchronous communication timer
            this.timerobj = timer('Name','EngineInterfaceTimer', ...
                                  'ExecutionMode','FixedRate');
            
            % Initialize engine
            this.InitializeEngine(book);
            
            % Spawn engine options object
            this.EO = EngineOptions(this);
            
            % Pass engine name to children
            this.EL.name = this.name;
            this.EO.name = this.name;
        end
        
        %
        % Descructor
        %
        function delete(this)
            try
                % (Quietly) stop timer, if necessary
                if strcmpi(this.timerobj.Running,'on')
                    % Stop timer
                    this.qlock = true;
                    stop(this.timerobj);
                end
                
                % Delete communication timer
                delete(this.timerobj);
            catch %#ok
                % Graceful exit
            end
            
            try
                % Close communication link
                this.CloseLink();
            catch %#ok
                % Graceful exit
            end
            
            try
                % Delete engine log
                delete(this.EL);
            catch %#ok
                % Graceful exit
            end
            
            try
                % Delete engine options
                delete(this.EO);
            catch %#ok
                % Graceful exit
            end
            
            try
                % Delete underlying handle object
                delete@handle(this);
            catch %#ok
                % Graceful exit
            end
        end
        
        %
        % Get all new commands (from engine)
        %
        function [cmds args] = GetCommands(this)
            % Initialize return cells
            cmds = {};
            args = {};
            
            % Get commands from engine
            isReady = true;
            while isReady
                % Get new command from engine
                [isReady cmd_new args_new] = this.GetCommand();
                
                % Store info
                cmds{end + 1} = cmd_new; %#ok
                args{end + 1} = args_new; %#ok
            end
        end
        
        %
        % Parse UCI command line (from engine)
        %
        function [isReady cmd args] = GetCommand(this)
            % Get line from engine
            [isReady line] = this.GetLine();
            
            % Extract command
            fields = this.uci.engine.cmds;
            pat = sprintf('(\\<%s\\>)|',fields{:});
            [cmd str] = regexp(line,pat,'match','split','once');
            args = struct();
            if isempty(cmd)
                % Quick return
                return;
            end
            
            % Parse arguments
            str = strtrim(str{2});
            switch cmd
                case 'id'
                    % Parse id command
                    fields = this.uci.engine.id;
                    args = EngineInterface.ParseArgs(str,fields);
                    
                    % Store engine name
                    if isfield(args,'name')
                        this.name = args.name;
                    end
                    
                    % Store engine author
                    if isfield(args,'author')
                        this.author = args.author;
                    end
                case 'bestmove'
                    % Parse bestmove command
                    strs = regexp(str,'\s+','split','once');
                    
                    % Parse (optional) ponder argument
                    if (length(strs) > 1)
                        fields = this.uci.engine.bestmove;
                        args = EngineInterface.ParseArgs(strs{2},fields);
                    end
                    
                    % Save best move string
                    args.move = strs{1};
                case 'copyprotection'
                    % Parse copyprotection command
                    fields = this.uci.engine.copyprotection;
                    args = EngineInterface.ParseArgs(str,fields);
                    
                    % Handle copyprotection error
                    if isfield(args,'error')
                        % Throw error
                        msgid = 'EI:COPYPROTECT:FAIL';
                        errmsg = 'Engine copyprotection failed';
                        this.Error(msgid,errmsg);
                    end
                case 'registration'
                    % Parse registration command
                    fields = this.uci.engine.registration;
                    args = EngineInterface.ParseArgs(str,fields);
                    
                    % Handle registration error command
                    if isfield(args,'error')
                        % Try to register the engine
                        this.RegisterEngine();
                    end
                case 'info'
                    % Parse info command
                    fields = this.uci.engine.info;
                    args = EngineInterface.ParseArgs(str,fields);
                    
                    % Parse score argument
                    if isfield(args,'score')
                        str = args.score;
                        fields = this.uci.engine.score;
                        args.score = EngineInterface.ParseArgs(str,fields);
                    end
                    
                    % Parse principal variation argument
                    if isfield(args,'pv')
                        args.pv = regexp(args.pv,'\s+','split');
                    end
                    
                    % Parse refuatation argument
                    if isfield(args,'refutation')
                        str = args.refutation;
                        args.refutation = regexp(str,'\s+','split');
                    end
                    
                    % Parse current line argument
                    if isfield(args,'currline')
                        str = args.currline;
                        args.currline = regexp(str,'\s+','split');
                    end
                    
                    % Save new info
                    this.SaveInfo(args);
                case 'option'
                    % Parse option command
                    fields = this.uci.engine.option;
                    args = EngineInterface.ParseArgs(str,fields);
                    
                    % Save to options list
                    this.options{end + 1} = args;
            end
        end
        
        %
        % Send UCI command to engine
        %
        function SendCommand(this,cmd,args)
            % Parse args
            switch cmd
                case 'debug'
                    % Construct debug command
                    fields = this.uci.gui.debug;
                    str = EngineInterface.ConstructArgs(args,fields);
                case 'setoption'
                    % Construct setoption command
                    fields = this.uci.gui.setoption;
                    str = EngineInterface.ConstructArgs(args,fields);
                case 'register'
                    % Construct register command
                    fields = this.uci.gui.register;
                    str = EngineInterface.ConstructArgs(args,fields);
                case 'position'
                    % Construct position command
                    fields = this.uci.gui.position;
                    str = EngineInterface.ConstructArgs(args,fields);
                case 'go'
                    % Construct go command
                    fields = this.uci.gui.go;
                    str = EngineInterface.ConstructArgs(args,fields);
                otherwise
                    % No additional arguments
                    str = '';
            end
            
            % Construct line string
            line = strtrim(sprintf('%s %s',cmd,str));
            
            % Send line, if non-empty
            if ~isempty(line)
                % Send line to engine
                this.SendLine(line);
            end
        end
        
        %
        % Check the ready state of the engine
        %
        function ReadyHandshake(this)
            % Ask the engine if it's ready to go
            this.SendCommand('isready');
            
            % Wait for engine to respond with 'readyok'
            this.ReadUntilCMD('readyok');
        end
        
        %
        % Read from engine stream until the given command is received
        %
        function args = ReadUntilCMD(this,tcmd,maxTime)
            % Get waiting constants
            if (nargin < 3)
                % Use default read time
                maxTime = EngineInterface.DEF_WAIT_TIME;
            end
            ptime = EngineInterface.PAUSE_TIME;
            nMax = maxTime / ptime;
            
            % Read until target command is received
            cmd = '';
            ntries = 0;
            while (~strcmpi(cmd,tcmd) && (ntries <= nMax))
                % Get command from engine
                [isReady cmd args] = this.GetCommand();
                
                % Update communicating object's stats, if necessary
                if ~isempty(this.obj)
                    this.obj.UpdateStats(this.info);
                end
                
                % Check if the engine sent anything
                if (isReady == false)
                    % Wait for engine to become responsive
                    drawnow; pause(ptime);
                    ntries = ntries + 1;
                else
                    % Reset counter
                    ntries = 0;
                end
            end
            
            % Throw an error if the desired command was never received
            if ~strcmpi(cmd,tcmd)
                msgid = 'EI:COMM:ABORT';
                str = 'Communication aborted before ''%s'' was received';
                this.Error(msgid,sprintf(str,tcmd));
            end
        end
        
        %
        % Read *asynchronously* from the engine stream until the given
        % command is received
        %
        function ReadUntilCMDa(this,tcmd,maxTime,fcn)
            % Get waiting constants
            if (nargin < 3)
                % Use default read time
                maxTime = EngineInterface.DEF_WAIT_TIME;
            end
            ptime = EngineInterface.PAUSE_TIME;
            nMax = maxTime / ptime;
            
            % Release reading lock
            this.rlock = false;
            
            % Construct timer to handle asynchronous stats updates
            userData = struct('cmd','','args',struct(),'success',false);
            set(this.timerobj,'StartDelay',ptime, ...
                            'Period',ptime, ...
                            'TasksToExecute',nMax, ...
                            'TimerFcn',@(s,e)ReadInfo(this,tcmd), ...
                            'StopFcn',@(s,e)StopReading(this,tcmd,fcn), ...
                            'UserData',userData);
            
            % Start timer
            start(this.timerobj);
        end
        
        %
        % Read engine info, and stop timer if target command is received
        %
        function ReadInfo(this,tcmd)
            try
                % If interface is active and not already reading info
                if (this.qlock == false) && (this.rlock == false)
                    % Set reading lock
                    this.rlock = true;
                    
                    % Get *all new* commands from engine
                    [cmds args] = this.GetCommands();
                    
                    % Update communicating object's stats, if necessary
                    if ~isempty(this.obj)
                        this.obj.UpdateStats(this.info);
                    end
                    
                    % Check if we received the target command
                    idx = find(ismember(cmds,tcmd));
                    if ~isempty(idx)
                        % Store desired command in timer's UserData
                        userData = struct('cmd',cmds{idx}, ...
                                          'args',args{idx}, ...
                                          'success',true);
                        set(this.timerobj,'UserData',userData);
                        
                        % Stop the timer
                        stop(this.timerobj);
                    end
                    
                    % Release reading lock
                    this.rlock = false;
                end
            catch ME
                % Only throw exception if interface wasn't closed
                if isvalid(this)
                    % Rethrow exception
                    rethrow(ME);
                end
            end  
        end
        
        %
        % Stop reading from the engine
        %
        function StopReading(this,tcmd,fcn)
            try
                % If interface is ready
                if (this.qlock == false)
                    % Process based on success state
                    userData = get(this.timerobj,'UserData');
                    if (userData.success == true)
                        % Call the success function
                        fcn(userData.args);
                    else
                        % Alert the user that reading failed
                        msgid = 'EI:COMM:ABORT';
                        str = ['Communication aborted before ' ...
                               '''%s'' was received'];
                        this.Error(msgid,sprintf(str,tcmd));
                    end
                end                
            catch ME
                % Only throw exception if interface wasn't closed
                if isvalid(this)
                    % Rethrow exception
                    rethrow(ME);
                end
            end
        end
        
        %
        % Register the engine
        %
        function RegisterEngine(this)
            % Check if we should register later
            if (this.registerNow == false)
                % Tell the engine to register later
                this.RegisterLater();
                return;
            end
            
            % Inform user about registration
            nstr = this.name; % Name of this engine
            qstr = sprintf('%s requires registration. Register now?',nstr);
            answer = questdlg(qstr,'Engine Registration', ...
                                   'Yes','Later','Quit','Yes');
            drawnow; % hack to avoid MATLAB freeze + crash
            
            % Process user response
            switch answer
                case 'Yes'
                    % Get name/code from user
                    response = inputdlg({'Name','Code'}, ...
                                         'Engine Registration', ...
                                         [1 50],{'',''});
                    drawnow; % hack to avoid MATLAB freeze + crash
                    
                    % Process user responses
                    if ~isempty(response)
                        % Send registration information to engine
                        args = struct();
                        if ~isempty(response{1})
                            % Send name
                            args.name = response{1};
                        end
                        if ~isempty(response{2})
                            % Send code
                            args.code = response{2};
                        end
                        this.SendCommand('register',args);
                    else
                        % Tell engine to register later
                        this.RegisterLater();
                    end
                otherwise
                    % Tell engine to register later
                    this.RegisterLater();
            end
        end
        
        %
        % Tell the engine to register later
        %
        function RegisterLater(this)
            % Send register later command to engine 
            this.SendCommand('register',struct('later',true));
            
            % Warn user that some engine features may be inactive
            warnStr = ['Deferred registration: Some engine ' ...
                       'features may be inactive'];
            this.EL.AppendWarningLine(warnStr);
        end
        
        %
        % Get current search information
        %
        function args = GetInfo(this)
            % Return info structure
            args = this.info;
        end
        
        %
        % Clear search info
        %
        function ClearInfo(this)
            % Clear info structure
            this.info = struct();
        end
        
        %
        % Convert to absolute path
        %
        function path = AbsPath(this,path)
            % Convert to forward slashes for platform independence
            path = regexprep(path,'\','/');
            
            % Replace beginning ./ with base directoy
            if ((length(path) >= 2) && strcmp(path(1:2),'./'))
                path = [this.dir path(2:end)];
            end
        end
        
        %
        % Convert to relative path
        %
        function path = RelPath(this,path)
            % Convert to forward slashes for platform independence
            path = regexprep(path,'\','/');
            
            % Replace base directoy with ./
            len = length(this.dir);
            if ((length(path) >= len) && strcmp(path(1:len),this.dir))
                path = ['.' path((len + 1):end)];
            end
        end
    end
    
    %
    % Private methods
    %
    methods (Access = private)
        %
        % Save new search info
        %
        function SaveInfo(this,args)
            % Save new field values
            fields = fieldnames(args);
            for j = 1:numel(fields)
                this.info.(fields{j}) = args.(fields{j});
            end
        end
        
        %
        % Initialize engine
        %
        function InitializeEngine(this,book)
            % Clear info list
            this.ClearInfo();
            
            % Tell the engine to use UCI
            this.SendCommand('uci');
            
            % Read until 'uciok' is received
            this.ReadUntilCMD('uciok');
            
            % Ready handshake
            this.ReadyHandshake();
            
            % Make sure debug mode is off
            %this.SendCommand('debug',struct('off',true));
            
            % Make sure pondering is off (not supported by ChessEngine)
            this.SetOption('Ponder','false');
            
            % Set minimum thinking time to zero
            this.SetOption('Minimum Thinking Time','0');
            
            try
                % Get # CPU cores
                % NOTE: feature() is undocumented
                numCores = feature('numCores');
                
                % Set # threads to give desired max CPU usage
                % NOTE: Only succeeeds if engine supports "Threads" option
                numThreads = sprintf('%.0f',floor(this.maxCPU * numCores));
                this.SetOption('Threads',numThreads);
            catch %#ok
                warnStr = 'Undocumented feature(''numCores'') has failed';
                this.EL.AppendWarningLine(warnStr);
            end
            
            % Set up opening book access
            if ~isempty(book)                
                % Tell the engine to use its own book
                % NOTE: Only succeeds if engine supports "OwnBook" option
                this.SetOption('OwnBook','true');
                
                % Give the engine the specified opening book path
                % NOTE: Only succeeds if engine supports "Book File" option
                this.SetOption('Book File',this.AbsPath(book));
            else
                % Tell the engine *not* to use its own book
                % NOTE: Only succeeds if engine supports "OwnBook" option
                this.SetOption('OwnBook','false');
            end
            
            % Tell the engine to start a new game internally
            this.SendCommand('ucinewgame');
        end
        
        %
        % Try to set option "name" to the given "value"
        %
        function SetOption(this,name,value)
            try
                % Find name in options list
                inds = cellfun(@(s)strcmpi(s.name,name),this.options);
                idx = find(inds);
                assert(~isempty(idx));
                
                % Send command to engine
                args = struct('name',name,'value',value);
                this.SendCommand('setoption',args);
                
                % Update options value
                this.options{idx}.default = value;
            catch %#ok
                % Write warning line to engine log
                warnStr = sprintf('Failed to set %s to %s',name,value);
                this.EL.AppendWarningLine(warnStr);
            end
        end
        
        %
        % Get line from engine
        %
        function [isReady line] = GetLine(this)
            % Read line from input stream
            isReady = this.in.ready();
            if (isReady == true)
                % Get line from input buffer
                line = char(this.in.readLine());
                
                % Write nonempty lines to engine log
                if ~isempty(line)
                    this.EL.AppendEngineLine(line);
                end
            else
                % Engine had nothing to send
                line = '';
            end
        end
        
        %
        % Send line to engine
        %
        function SendLine(this,line)
            % Send line to output stream
            this.out.println(line);
            %this.out.flush();
                        
            % Write line to engine log
            this.EL.AppendGUILine(line);
        end
        
        %
        % Open a communication link with the engine
        %
        function OpenLink(this,path)
            % Make sure we have the absolute path
            path = this.AbsPath(path);
            
            % (Try to?) set execute permissions
            if (ispc == true)
                % Windows
                usr = 'Everyone';
                cmd = sprintf('icacls "%s" /grant %s:RX',path,usr);
                [~,~] = system(cmd);
            else
                % Mac
                usr = 'ugo';
                cmd = sprintf('chmod %s+x "%s"',usr,path);
                [~,~] = system(cmd);
            end
            
            % Spawn engine process
            %this.p = java.lang.Runtime.getRuntime().exec(path);
            this.p = java.lang.ProcessBuilder(path).start();
            
            % Connect to engine's stdout
            iStream = this.p.getInputStream();
            iStreamReader = java.io.InputStreamReader(iStream);
            this.in = java.io.BufferedReader(iStreamReader);
            
            % Connect to engine's stdin
            oStream = this.p.getOutputStream();
            this.out = java.io.PrintWriter(oStream,true);
            %this.out = java.io.PrintWriter(oStream);
        end
        
        %
        % Close communication link with engine
        %
        function CloseLink(this)
            % Tell engine to quit
            this.SendCommand('quit');
            
            % Destroy engine process
            this.p.destroy();
        end
        
        %
        % Throw error with the given message
        %
        function Error(this,msgid,errmsg)
            % Destroy the session
            delete(this);
            
            % Relay error to command window
            error(msgid,errmsg);
        end
    end
    
    %
    % Private static methods
    %
    methods (Access = private, Static = true)
        %
        % Parse args string (from engine)
        %
        function args = ParseArgs(str,fields)
            % Extract key-value pairs from input string
            pat = sprintf('(\\<%s\\>)|',fields{:});
            [keys vals] = regexp(str,pat,'match','split');
            
            % Return key-value pairs as strucutre fields
            args = struct();
            for i = 1:length(keys)
                % Trim value string
                val = strtrim(vals{i + 1});
                
                % Check if key already exists
                if isfield(args,keys{i})
                    % Append value to key's cell
                    if ~iscell(args.(keys{i}))
                        args.(keys{i}) = {args.(keys{i})};
                    end
                    args.(keys{i}){end + 1} = val;
                else
                    % Save value as new key
                    args.(keys{i}) = val;
                end
            end
        end
        
        %
        % Construct args string (from GUI)
        %
        function str = ConstructArgs(args,fields)
            % Loop over input fields
            str = '';
            for i = 1:length(fields)
                % Check if argument is valid
                if isfield(args,fields{i})
                    % Append field args to str
                    switch class(args.(fields{i}))
                        case 'double'
                            str = sprintf('%s %s %.0f ',str,fields{i}, ...
                                                args.(fields{i}));
                        case 'char'
                            str = sprintf('%s %s %s ',str,fields{i}, ...
                                                args.(fields{i}));
                        case 'logical'
                            if (args.(fields{i}) == true)
                                str = sprintf('%s %s ',str,fields{i});
                            end
                        case 'cell'
                            str = sprintf('%s ',str,fields{i}, ...
                                                args.(fields{i}){:});
                    end
                    str = strtrim(str);
                end
            end
        end
        
        %
        % Generate UCI field lists
        %
        function uci = UCIFields()
            % GUI commands
            uci.gui.cmds = {'uci','debug','isready','setoption', ...
                            'register','ucinewgame','position', ...
                            'go','stop','ponderhit','quit'};
            uci.gui.debug = {'on','off'};
            uci.gui.setoption = {'name','value'};
            uci.gui.register = {'later','name','code'};
            uci.gui.position = {'startpos','fen','moves'};
            uci.gui.go = {'ponder','searchmoves','wtime','btime', ...
                          'winc','binc','movestogo','depth','nodes', ...
                          'mate','movetime','infinite'};
            
            % Engine commands
            uci.engine.cmds = {'id','uciok','readyok','bestmove', ...
                      'copyprotection','registration','info','option'};
            uci.engine.id = {'name','author'};
            uci.engine.bestmove = {'ponder'};
            uci.engine.copyprotection = {'checking','ok','error'};
            uci.engine.registration = {'checking','ok','error'};
            uci.engine.info = {'depth','seldepth','time','nodes','pv', ...
                              'multipv','score','currmove', ...
                              'currmovenumber','hashfull','nps', ...
                              'tbhits','sbhits','cpuload','string', ...
                              'refutation','currline'};
            uci.engine.score = {'cp','mate','lowerbound','upperbound'};
            uci.engine.option = {'name','type','default', ...
                                 'min','max','var'};
        end
        
        %
        % Get base directory of this class
        %
        function dir = GetBaseDir()
            % Extract base directory from location of current .m file
            [dir name ext] = fileparts(mfilename('fullpath')); %#ok
            
            % Convert to forward slashes for platform independence
            dir = regexprep(dir,'\','/');
        end
    end
end
