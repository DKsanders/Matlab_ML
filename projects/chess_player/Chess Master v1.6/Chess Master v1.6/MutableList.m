classdef MutableList < handle
%
% Class that spawns a mutable list GUI
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
        DIM = [225 275];            % Default GUI [width height], in pixels
        FBORDER = 7;                % Figure border width, in pixels
        CONTROL_HEIGHT = 20;        % UI object heights, in pixels
        
        % Font sizes
        FONT_SIZE = 10 - 2 * ispc;  % GUI font size
    end
    
    %
    % Public GetAccess properties
    %
    properties (GetAccess = public, SetAccess = private)
        % List state variables
        elements;                   % List element array
        selection;                  % Selected list element
        
        % Figure properties
        fig;                        % Figure handle
    end
    
    %
    % Private properties
    %
    properties (Access = private)
        % GUI variables
        listh;                      % List handle
        obh;                        % Order button handles
        sbh;                        % Selection button handles
    end
    
    %
    % Public static methods
    %
    methods (Access = public, Static = true)
        %
        % Run mutable list as singleton
        %
        function [elements selection] = Instance(varargin)
            % Spawn mutable list
            ML = MutableList(varargin{:});
            
            % Wait for user to finish
            uiwait(ML.fig);
            
            % Return list elements/selection
            elements = ML.elements;
            selection = ML.selection;
            
            % Destroy list
            delete(ML);
        end
    end
    
    %
    % Private methods
    %
    methods (Access = private)
        %
        % Constructor
        %
        function this = MutableList(elements,initVal,name,xyc)
        
            % Save list elements
            this.elements = elements;
            
            % Initialize GUI
            this.InitializeGUI(initVal,name,xyc);
        end
        
        %
        % Close list
        %
        function Close(this)
            % Resume instance execution
            uiresume(this.fig);
            drawnow; % Hack to avoid MATLAB freeze + crash
        end
        
        %
        % Delete list
        %
        function delete(this)
            try
                % Close GUI
                delete(this.fig);
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
        % Push element up list
        %
        function PushUp(this)
            % Get current element
            idx = this.GetCurrentElement();
            
            % If this isn't the first element
            if (idx > 1)
                % Update elements
                n = length(this.elements);
                newOrder = [1:(idx - 2) idx (idx - 1) (idx + 1):n];
                this.elements = this.elements(newOrder);
                
                % Update list
                this.UpdateList();
                this.SetCurrentElement(idx - 1);
            end
        end
        
        %
        % Push element down list
        %
        function PushDown(this)
            % Get current element
            idx = this.GetCurrentElement();
            
            % If this isn't the first element
            n = length(this.elements);
            if (idx < n)
                % Update elements
                newOrder = [1:(idx - 1) (idx + 1) idx (idx + 2):n];
                this.elements = this.elements(newOrder);
                
                % Update list
                this.UpdateList();
                this.SetCurrentElement(idx + 1);
            end
        end
        
        %
        % Delete current element
        %
        function DeleteElement(this)
            % Get current element
            idx = this.GetCurrentElement();
            
            % If an element is selected
            if (idx > 0)
                % Delete element
                this.elements(idx) = [];
                
                % Handle deleting bottom element
                n = length(this.elements);
                if (idx > n)
                    % Set index to new bottom
                    this.SetCurrentElement(n);
                end
                
                % Update list elements
                this.UpdateList();
            end
        end
        
        %
        % Select given element
        %
        function SelectElement(this)
            % Get current element
            this.selection = this.GetCurrentElement();
            
            % Close GUI
            this.Close();
        end
        
        %
        % Get current element
        %
        function idx = GetCurrentElement(this)
            % Get list value
            idx = get(this.listh,'Value');
        end
        
        %
        % Set current element
        %
        function SetCurrentElement(this,idx)
            % Set list value
            set(this.listh,'Value',idx);
        end
        
        %
        % Update list elements
        %
        function UpdateList(this)
            % Set list elements
            set(this.listh,'String',this.elements);
        end
        
        %
        % Initialize GUI
        %
        function InitializeGUI(this,initVal,name,xyc)
            % Get constants
            dim = MutableList.DIM;
            dy = MutableList.CONTROL_HEIGHT;
            fontSize = MutableList.FONT_SIZE;
            
            % Setup a nice (modal) figure
            this.fig = figure('name',name, ...
                      'MenuBar','none', ...
                      'DockControl','off', ...
                      'NumberTitle','off', ...
                      'Position',[(xyc - 0.5 * dim) dim], ...
                      'WindowKeyPressFcn',@(s,e)HandleKeyPress(this,e), ...
                      'ResizeFcn',@(s,e)ResizeComponents(this), ...
                      'CloseRequestFcn',@(s,e)Close(this), ...
                      'WindowStyle','modal', ...
                      'Visible','off');
            
            % Add list uicontrol
            this.listh = uicontrol('Parent',this.fig,...
                                   'Units','pixels',...
                                   'HorizontalAlignment','left', ...
                                   'FontSize',fontSize, ...
                                   'Style','list',...
                                   'Max',1, ...
                                   'Enable','on',...
                                   'Value',initVal, ...
                                   'String',this.elements);
            
            % Add order buttons
            this.obh(1) = uicontrol('Parent',this.fig,...
                                    'Units','pixels', ...
                                    'FontUnits','points', ...
                                    'FontName','Courier', ...
                                    'FontSize',dy, ...
                                    'Callback',@(s,e)PushUp(this), ...
                                    'Style','pushbutton', ...
                                    'String','+');
            this.obh(2) = uicontrol('Parent',this.fig,...
                                    'Units','pixels', ...
                                    'FontUnits','points', ...
                                    'FontName','Courier', ...
                                    'FontSize',dy, ...
                                  'Callback',@(s,e)DeleteElement(this), ...
                                    'Style','pushbutton', ...
                                    'String','x');
            this.obh(3) = uicontrol('Parent',this.fig,...
                                    'Units','pixels', ...
                                    'FontUnits','points', ...
                                    'FontName','Courier', ...
                                    'FontSize',dy, ...
                                    'Callback',@(s,e)PushDown(this), ...
                                    'Style','pushbutton', ...
                                    'String','-');
            
            % Add selection buttons
            this.sbh(1) = uicontrol('Parent',this.fig,...
                                  'Units','pixels', ...
                                  'FontSize',fontSize, ...
                                  'Callback',@(s,e)SelectElement(this), ...
                                  'Style','pushbutton', ...
                                  'String','Done');
            this.sbh(2) = uicontrol('Parent',this.fig,...
                                  'Units','pixels', ...
                                  'FontSize',fontSize, ...
                                  'Callback',@(s,e)Close(this), ...
                                  'Style','pushbutton', ...
                                  'String','Cancel');
            
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
                % Close list
                this.Close();
                return;
            end
        end
        
        %
        % Resize GUI components
        %
        function ResizeComponents(this)
            % Get constants
            fds = MutableList.FBORDER;
            dy = MutableList.CONTROL_HEIGHT;
            n1 = length(this.obh);
            n2 = length(this.sbh);
            
            % Get figure dimensions
            pos = get(this.fig,'Position');
            xfig = pos(3);
            yfig = pos(4);
            
            % Resize figure, if necessary
            xmin = 3 * fds + dy + 25;
            ymin = (n1 + 2) * fds + (n1 + 1) * dy;
            if ((xfig < xmin) || (yfig < ymin))
                xfig = max([xfig xmin]);
                yfig = max([yfig ymin]);
                set(this.fig,'Position',[pos(1:2) xfig yfig]);
            end
            
            % Resize order buttons
            pos1 = @(i) [(xfig - fds - dy) ...
                         (yfig - i * fds - i * dy) dy dy];
            for i = 1:n1
                set(this.obh(i),'Position',pos1(i));
            end
            
            % Resize selection buttons
            dx = (xfig - (n2 + 1) * fds) / n2;
            pos2 = @(j) [(j * fds + (j - 1) * dx) fds dx dy];
            for j = 1:n2
                set(this.sbh(j),'Position',pos2(j));
            end
            
            % Resize list
            dxl = xfig - 3 * fds - dy;
            dyl = yfig - 3 * fds - dy;
            set(this.listh,'Position',[fds (2 * fds + dy) dxl dyl]);
        end
    end
end
