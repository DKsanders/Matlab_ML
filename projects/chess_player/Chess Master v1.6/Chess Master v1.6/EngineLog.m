classdef EngineLog < handle
%
% Class that spawns and coordinates an engine communication log with a
% ChessEngine object
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
        % Maximum log length
        MAX_LENGTH = 250;           % Maximum # lines in log
        
        % GUI formatting (font size is decreased by 2 for PCs)
        DIM = [407 468];            % GUI [width height], in pixels
        FONT_SIZE = 10;             % GUI font size
        FBORDER = 7;                % Figure border width, in pixels
    end
    
    %
    % Public properties
    %
    properties (Access = public)
        % Parent info
        name = 'Engine';            % Engine name
    end
    
    %
    % Public GetAccess properties
    %
    properties (GetAccess = public, SetAccess = private)
        % Figure properties
        fig;                        % Figure handle
        visible = false;            % Visibility flag
    end
    
    %
    % Private properties
    %
    properties (Access = private)
        % Internal variables
        lines = {};                 % Log file lines
        
        % GUI variables
        log;                        % Log list handle
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = EngineLog()
            % Empty
        end
        
        %
        % Destructor
        %
        function delete(this)
            try
                % Close GUI
                this.CloseGUI();
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
        % Open GUI
        %
        function figh = OpenGUI(this,xyc)
            % Check if a GUI already exists
            if (this.visible == false)
                % Initialize GUI
                this.InitializeGUI(xyc);
                figh = this.fig;
                
                % Set visible flag to true
                this.visible = true;
            else
                % Give focus to the existing GUI
                figure(this.fig);
                figh = [];
            end
            
            % Update display
            this.UpdateLog();
        end
        
        %
        % Close GUI
        %
        function CloseGUI(this)
            % Check if GUI still exists
            if (this.visible == true)
                try
                    % Close GUI
                    delete(this.fig);
                catch %#ok
                    % Graceful exit
                end
                
                % Set visible flag to false
                this.visible = false;
            end
        end
        
        %
        % Append engine line to log
        %
        function AppendEngineLine(this,line)
            % Append line to list
            color = '#483D8B'; % Dark slate blue
            fmt = '<html><font color=%s>&emsp &emsp %s</font></html>';
            this.lines{end + 1} = sprintf(fmt,color,line);
            
            % Update log
            this.UpdateLog();
        end
        
        %
        % Append GUI line to log
        %
        function AppendGUILine(this,line)
            % Append line to list
            color = '#000000'; % Black
            fmt = '<html><font color=%s>%s</font></html>';
            this.lines{end + 1} = sprintf(fmt,color,line);
            
            % Update log
            this.UpdateLog();
        end
        
        %
        % Append warning line to log
        %
        function AppendWarningLine(this,line)
            % Append line to list
            msg = 'WARNING';
            color = '#FF8C00'; % Dark orange
            fmt = '<html><font color=%s>***** %s: %s *****</font></html>';
            this.lines{end + 1} = sprintf(fmt,color,msg,line);
            
            % Update log
            this.UpdateLog();
        end
        
        %
        % Append error line to log
        %
        function AppendErrorLine(this,line)
            % Append line to list (with blue font)
            msg = 'ERROR';
            color = '#DC143C'; % Crimson
            fmt = '<html><font color=%s>***** %s: %s *****</font></html>';
            this.lines{end + 1} = sprintf(fmt,color,msg,line);
            
            % Update log
            this.UpdateLog();
        end
    end
    
    %
    % Private methods
    %
    methods (Access = private)
        %
        % Update log
        %
        function UpdateLog(this)
            % Remove extra lines, if necessary
            n = length(this.lines);
            N = EngineLog.MAX_LENGTH;
            if (n > N)
                this.lines(1:(n - N)) = [];
            end
            
            % Update GUI, if visible
            if (this.visible == true)
                % Update log list
                set(this.log,'String',this.lines, ...
                             'Value',length(this.lines));
            end
        end
        
        %
        % Initialize GUI
        %
        function InitializeGUI(this,xyc)
            % Constants
            dim = EngineLog.DIM; % GUI dimensions
            fontSize = EngineLog.FONT_SIZE - 2 * ispc;
            
            % Create a nice figure
            this.fig = figure('MenuBar','None', ...
                      'NumberTitle','off', ...
                      'DockControl','off', ...
                      'name',[this.name ' Log'], ...
                      'tag','EngineLog', ...
                      'Position',[(xyc - 0.5 * dim) dim], ...
                      'Interruptible','on', ...
                      'Resize','on', ...
                      'ResizeFcn',@(s,e)ResizeComponents(this), ...
                      'WindowKeyPressFcn',@(s,e)HandleKeyPress(this,e), ...
                      'CloseRequestFcn',@(s,e)CloseGUI(this), ...
                      'Visible','off');
            
            % Add log list
            this.log = uicontrol('Parent',this.fig,...
                                 'Units','pixels',...
                                 'HorizontalAlignment','left', ...
                                 'FontSize',fontSize, ...
                                 'Style','list',...
                                 'Max',1, ...
                                 'Enable','on',...
                                 'Value',[], ...
                                 'String',{});
            
            % Resize GUI components
            this.ResizeComponents();
            
            % Set figure to visible
            set(this.fig,'Visible','on');
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
                this.CloseGUI();
                return;
            end
        end
        
        %
        % Resize GUI components
        %
        function ResizeComponents(this)
            % Get figure position
            pos = get(this.fig,'Position');
            
            % Get desired border width
            ds = EngineLog.FBORDER;
            
            % Update listbox dimensions
            dx = pos(3) - 2 * ds + 2;
            dy = pos(4) - 2 * ds + 2;
            set(this.log,'Position',[ds ds dx dy]);
        end
    end
end
