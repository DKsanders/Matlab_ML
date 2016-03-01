classdef HelpWindow < handle
%
% Class that spawns a help window
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
        BORDER = 25;                        % Border spacing, in pixels
        
        % Font sizes
        FONT_SIZE = 12;                     % Font size, in pixels
        
        % Colors
        BACKGROUND = ([236 236 236] + 4 * ispc) / 255; % Background color
    end
    
    %
    % Public GetAccess properties
    %
    properties (GetAccess = public, SetAccess = private)
        % Figure properties
        fig;                                % Figure handle
    end
    
    %
    % Private properties
    %
    properties (Access = private)
        % Internal variables
        help;                               % Help structure
        mIdx = 0;                           % Current menu index
        
        % Figure handles
        uic;                                % Text uicontrol handle
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = HelpWindow(help,name,tag,xyc)
            % Save help structure
            this.help = help;
            
            % Initialize help window
            this.InitializeGUI(name,tag,xyc);
        end
        
        %
        % Close engine
        %
        function Close(this)
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
        % Load help text with given index
        %
        function OpenHelp(this,idx,xyc)
            % If menu isn't already loaded
            if (this.mIdx ~= idx)
                % Update menu index
                this.mIdx = idx;
                
                % Get constants
                fontSize = HelpWindow.FONT_SIZE;
                ds = HelpWindow.BORDER;
                
                % Load help text
                txt = this.help(idx).text;
                
                % Update figure position
                h = 1.25 * fontSize * length(txt);
                w = 0.60 * fontSize * max(cellfun(@length,txt));
                dim = [w h] + 2 * ds;
                if (nargin < 3)
                    % Keep menu bar in same position
                    pos = get(this.fig,'Position');
                    xcyt = pos(1:2) + [0.5 1] .* pos(3:4);
                    xyc = xcyt - [0 0.5] .* dim;
                end
                set(this.fig,'Position',[(xyc - 0.5 * dim) dim]);
                
                % Update help text
                set(this.uic,'String',txt,'Position',[ds ds w h]);
            end
        end
        
        %
        % Initialize GUI
        %
        function InitializeGUI(this,name,tag,xyc)
            % Get constants
            color = HelpWindow.BACKGROUND;
            fontSize = HelpWindow.FONT_SIZE;
            
            % Setup a nice figure
            wkpfcn = @(s,e)HandleKeyPress(this,e);
            this.fig = figure('name',name, ...
                              'tag',tag, ...
                              'MenuBar','none', ...
                              'DockControl','off', ...
                              'NumberTitle','off', ...
                              'Color',color, ...
                              'WindowKeyPressFcn',wkpfcn, ...
                              'Resize','off', ...
                              'Visible','off');
            
            % If there's more than one help structure
            nHelp = length(this.help);
            if (nHelp > 1)
                % Add navigation menus
                for i = 1:nHelp
                    uimenu(this.fig,'Label',this.help(i).name, ...
                                    'Callback',@(s,e)OpenHelp(this,i));
                end
            end
            
            % Add text
            this.uic = uicontrol('Parent',this.fig, ...
                                 'Style','text', ...
                                 'Units','pixels', ...
                                 'HorizontalAlignment','center', ...
                                 'BackgroundColor',color, ...
                                 'FontUnits','pixels', ...
                                 'FontSize',fontSize, ...
                                 'FontName','Courier', ...
                                 'Max',2, ...
                                 'Min',0);
            
            % Initialize with first help text
            this.OpenHelp(1,xyc);
            
            % Make figure visible
            set(this.fig,'Visible','on');
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
            end
        end
    end
end
