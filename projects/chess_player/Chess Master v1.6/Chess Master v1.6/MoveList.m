classdef MoveList < handle
%
% Internal class that spawns a list of the current moves and allows the
% user to graphically navigate forward/backward through the current game
%
% NOTE: This class is used internally by the ChessMaster GUI and is not
%       intended for public invocation
%
% Brian Moore
% brimoor@umich.edu
%

    %
    % Constants
    %
    properties (GetAccess = private, Constant = true)
        % GUI constants
        DIM = [222 449];            % Default GUI dimensions, in pixels
        FBORDER = 7;                % Figure border width, in pixels
        SCROLLBAR_WIDTH = 20;       % Scroll bar width, in pixels
        DEF_ROW_HEADER_WIDTH = 30;  % Default row header width, in pixels
    end
    
    %
    % Public GetAccess properties
    %
    properties (GetAccess = public, SetAccess = private)
        % Figure handle
        fig;                        % Figure handle
        
        % Execution locks
        glock = false;              % Go-to lock
    end
    
    %
    % Private properties
    %
    properties (Access = private)
        % ChessMaster handle
        CM;                         % ChessMaster handle
        
        % Internal variables
        moves = {};                 % Move string list
        idx = 0;                    % Current index
        goto = [];                  % Go to move list
        
        % GUI handles
        mtable;                     % MATLAB uitable handle
        jtable;                     % Java uitable handle
        rowHeader;                  % Java uitable row header handle
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = MoveList(CM,tag,varargin)
        % Syntax:   ML = MoveList(CM,tag,'xyc',xyc);
        %           ML = MoveList(CM,tag,'pos',pos);
        
            % Save ChessMaster handle
            this.CM = CM;
            
            % Initialize GUI
            this.InitializeGUI(tag,varargin{:});
        end
        
        %
        % Append moves to list *after* the given index, deleting any extra
        % moves
        %
        function AppendMoves(this,moves,idx)
            % Append moves to list
            this.moves((idx + 1):end) = [];
            this.moves((idx + 1):(idx + length(moves))) = moves;
            this.UpdateMoveList();
        end
        
        %
        % Set move list position (no callbacks)
        %
        function SetPosition(this,idx)            
            % Update list position
            this.idx = idx;
            this.UpdatePosition();
        end
        
        %
        % Reset move list
        %
        function Reset(this)
            % Update move list
            this.UpdateColumnNames();
            this.moves = {};
            this.UpdateMoveList();
            
            % Clear go-to list
            this.glock = false;
            this.goto = [];
            
            % Clear position
            this.SetPosition(0);
        end
        
        %
        % Close GUI
        %
        function Close(this)
            try
                % Remove pointer from ChessMaster memory
                this.CM.DeleteMoveList();
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
        % Go to given halfmove
        %
        function GoToHalfmove(this,idx)
            % Push index onto list
            this.goto(end + 1) = idx;
            
            % If not already processing
            if (this.glock == false)
                % Set go-to lock
                this.glock = true;
                
                % While there are moves in the queue
                while ~isempty(this.goto)
                    % Pop most recent index from list
                    n = this.goto(end);
                    this.goto = [];
                    
                    % Go to desired position
                    this.CM.GoToHalfmove(n);
                end
                
                % Release go-to lock
                this.glock = false;
            end 
        end
        
        %
        % Update move list
        %
        function UpdateMoveList(this)
            % Get old number of rows
            nrows_old = size(get(this.mtable,'Data'),1);
            
            % Update data
            data = this.moves;
            if mod(length(data),2)
                data{end + 1} = '';
            end
            nrows = 0.5 * length(data);
            data = reshape(data,[2 nrows])';
            set(this.mtable,'Data',data);
            
            % Resize components, if necessary
            if (floor(log10(nrows)) ~= floor(log10(nrows_old)))
                this.ResizeComponents();
            end
        end
        
        %
        % Update selected position
        %
        function UpdatePosition(this,row,col)
            % If row/column coordinates are not specified
            if (nargin < 3)
                % Compute coordinates from current move index
                row = ceil(0.5 * this.idx);
                col = ~mod(this.idx,2) + 1;
            end
            
            % Update uitable selection   
            if (row == 0)
                % No selection
                this.jtable.changeSelection(-1,-1,false,false);
            else
                % Change selection
                this.jtable.changeSelection(row - 1,col - 1,false,false);
            end
        end
        
        %
        % Handle uitable keypress callbacks
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
            elseif (~isempty(modifiers) || isempty(key))
                % Quick return
                return;
            end
            
            % Process based on key press
            switch key
                case {ChessMaster.UP,ChessMaster.LEFT}
                    % If we haven't reached the starting position
                    if (this.idx > 0)
                        % Go back one halfmove
                        this.idx = this.idx - 1;
                        this.UpdatePosition();
                        this.GoToHalfmove(this.idx);
                    else
                        % Force empty selection
                        this.UpdatePosition();
                    end
                case {ChessMaster.DOWN,ChessMaster.RIGHT}
                    % If we haven't reached the current position
                    Nmoves = length(this.moves);
                    if (this.idx < Nmoves)
                        % Go forward one halfmove
                        this.idx = this.idx + 1;
                        this.UpdatePosition();
                        this.GoToHalfmove(this.idx);
                    else
                        % Force empty selection
                        this.UpdatePosition();
                    end
            end
        end
        
        %
        % Handle mouse release callbacks
        %
        function HandleMouseRelease(this)
            % Get selected move
            row = this.jtable.getSelectedRow();
            col = this.jtable.getSelectedColumn();
            this.idx = 2 * row + col + 1;
            
            % Go to selected halfmove
            this.GoToHalfmove(this.idx);
        end
        
        %
        % Handle cell selection callbacks
        %
        function HandleCellSelection(this,event)
            % Enforce single selection, if necessary
            inds = event.Indices;
            n = size(inds,1);
            if (n > 1)
                % Select *only* first cell
                this.UpdatePosition(inds(1,1),inds(1,2));
            end
        end
        
        %
        % Initialize GUI
        %
        function InitializeGUI(this,tag,varargin)
            % Parse figure position
            if strcmpi(varargin{1},'xyc')
                % GUI center specified
                dim = MoveList.DIM; % Default figure dimension
                pos = [(varargin{2} - 0.5 * dim) dim];
            elseif strcmpi(varargin{1},'pos')
                % Position specified directly
                pos = varargin{2};
            end
            
            % Generate a nice figure
            this.fig = figure('MenuBar','none', ...
                            'NumberTitle','off', ...
                            'DockControl','off', ...
                            'name','Move List', ...
                            'tag',tag, ...
                            'Position',pos, ...
                            'Resize','on', ...
                            'ResizeFcn',@(s,e)ResizeComponents(this), ...
                            'KeyPressFcn',@(s,e)HandleKeyPress(this,e), ...
                            'CloseRequestFcn',@(s,e)Close(this), ...
                            'Interruptible','on', ...
                            'Visible','on');
            
            % Add uitable
            this.mtable = uitable('Parent',this.fig, ...
                'Units','pixels', ...
                'RowName','numbered', ...
                'RowStriping','on', ...
                'Enable','on', ...
                'KeyPressFcn',@(s,e)HandleKeyPress(this,e), ...
                'CellSelectionCallback',@(s,e)HandleCellSelection(this,e));
            this.UpdateColumnNames(); % Set correct column names
            
            % Resize GUI components
            this.ResizeComponents();
            
            % Get underlying JTable and rowHeader Java objects
            jscroll = findjobj(this.mtable);
            JTable = jscroll.getViewport.getComponent(0);
            
            % Get thread-safe + callbacks handle object
            this.jtable = handle(JTable,'CallbackProperties');
            javaObjectEDT(this.jtable); % Dispatch callbacks from Java EDT
            
            % Get row header object
            this.rowHeader = jscroll.getComponent(4).getComponent(0);
            
            % Set mouse click callback
            mrcfcn = @(s,e)HandleMouseRelease(this);
            set(this.jtable,'MouseReleasedCallback',mrcfcn);
        end
        
        %
        % Update column names
        %
        function UpdateColumnNames(this)
            % Process based on first color to move
            if (this.CM.firstColorToMove == ChessPiece.WHITE)
                % White moved first
                names = {'White','Black'};
            else
                % Black moved first
                names = {'Black','White'};
            end
            
            % Update column names
            set(this.mtable,'ColumnName',names);
        end
        
        %
        % Resize table to fit in current figure
        %
        function ResizeComponents(this)
            % Flush graphics before resizing
            this.FlushGraphics();
            
            % Get figure position
            pos = get(this.fig,'Position');
            
            % Update uitable position
            ds = MoveList.FBORDER;
            dx = pos(3) - 2 * ds + 2;
            dy = pos(4) - 2 * ds + 2;
            set(this.mtable,'Position',[ds ds dx dy]);
            
            % Update column widths
            try
                % Get row header width
                dr = this.rowHeader.getWidth();
            catch %#ok
                % Use default width
                dr = MoveList.DEF_ROW_HEADER_WIDTH;
            end
            dw = MoveList.SCROLLBAR_WIDTH;
            dc = 0.5 * (dx - dr - dw);
            set(this.mtable,'ColumnWidth',{dc,dc});
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
end
