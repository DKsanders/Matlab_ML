classdef OptionsWindow < handle
%
% Superclass for <class>Options classes that spawn/control options dialogs
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
        LABEL_WIDTH = 150;              % Object label width, in pixels
        CONTROL_WIDTH = 300;            % Object panel widths, in pixels
        CONTROL_HEIGHT = 20;            % Object panel heights, in pixels
        NUM_SLIDER_STEPS = 100;         % # slider steps
        FBORDER = 7;                    % Figure border width, in pixels
        CONTROL_GAP = 4;                % Inter-object spacing, in pixels
        SLIDER_DX = [0.15 0.85];        % Slider relative spacing
        BUTTON_DX = 0.685;              % Button relative spacing
        POPUP_DX = 0.685;               % Popup relative spacing
        
        % Font sizes
        LABEL_SIZE = 12 - 2 * ispc;     % UI panel font size
        FONT_SIZE = 10 - 2 * ispc;      % GUI font size
        
        % Colors
        ACTIVE = [252 252 252] / 255;   % Active color
    end
    
    %
    % Abstract public properties
    %
    properties (Abstract = true, Access = public)
        % Parent info
        name;                           % Name string
        tag;                            % Tag string
    end
    
    %
    % Public GetAccess properties
    %
    properties (GetAccess = public, SetAccess = private)
        % Figure properties
        fig;                            % Figure handle
        visible = false;                % Visibility flag
    end
    
    %
    % Protected properties
    %
    properties (Access = protected)
        % Options variables
        options;                        % Options cell array
        names;                          % Option names cell array
    end
    
    %
    % Private properties
    %
    properties (Access = private)        
        % GUI variables
        uiph;                           % uipanel handle
        uich;                           % uicontrol handles
        vh;                             % slider value handles
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = OptionsWindow(options)
            % Save options and their names
            this.options = options;
            this.names = cellfun(@(o)o.name,options,'UniformOutput',false);
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
    end
    
    %
    % Abstract protected methods
    %
    methods (Abstract = true,Access = protected)
        %
        % Format string content
        %
        str = FormatString(this,name,str);
        
        %
        % Format spin (slider) content
        %
        val = FormatSpin(this,name,val);
        
        %
        % Process option
        %
        ProcessOption(this,name,val);
    end
    
    %
    % Protected methods
    %
    methods (Access = protected)
        %
        % Set option value
        %
        function SetOption(this,name,val,pflag)
            % Find option index
            i = find(ismember(this.names,name));
            
            % If option exists
            if ~isempty(i)
                % Set option value
                switch lower(this.options{i}.type)
                    case 'string'
                        % Set string
                        set(this.uich(i),'String',val);
                        this.StringSet(i,pflag);
                    case 'spin'
                        % Set slider value
                        if ischar(val)
                            val = str2double(val);
                        end
                        set(this.uich(i),'Value',val);
                        this.SpinSliderSet(i,pflag);
                    case 'combo'
                        % Set combo value
                        strs = get(this.uich(i),'String');
                        val = find(ismember(strs,val));
                        set(this.uich(i),'Value',val);
                        this.ComboSet(i,pflag);
                    case 'check'
                        % Set checkbox value
                        if ischar(val)
                            val = strcmpi(val,'true');
                        end
                        set(this.uich(i),'Value',val);
                        this.CheckSet(i,pflag);
                    case 'button'
                        % Press button
                        this.ButtonSet(i,pflag);
                end
            end
        end
    end
    
    %
    % Private methods
    %
    methods (Access = private)
        %
        % Handle string callback
        %
        function StringSet(this,i,pflag)
            % Get processing flag
            pflag = ~((nargin >= 3) && (pflag == false));
            
            % Get editbox string
            str = get(this.uich(i),'String');
            
            % Format string
            str = this.FormatString(this.options{i}.name,str);
            
            % Update editbox string
            set(this.uich(i),'String',str);
            
            % Save updated state in default field
            this.options{i}.default = str;
            
            % Process option, if necessary
            if (pflag == true)
                this.ProcessOption(this.options{i}.name,str);
            end
        end
        
        %
        % Handle spin value callback
        %
        function SpinValueSet(this,i,pflag)
            % Get processing flag
            pflag = ~((nargin >= 3) && (pflag == false));
            
            % Get editbox value
            val = str2double(get(this.vh(i),'String'));
            
            % If input was invalid
            if isnan(val)
                % Revert to last used value
                val = get(this.uich(i),'Value');
                set(this.vh(i),'String',num2str(val));
            else
                % Clip to valid range
                minVal = get(this.uich(i),'Min');
                maxVal = get(this.uich(i),'Max');
                val = min(max(val,minVal),maxVal);
                
                % Update slider
                set(this.uich(i),'Value',val);
                
                % Invoke slider callback to handle further processing
                this.SpinSliderSet(i,pflag);
            end
        end
        
        %
        % Handle spin slider callback
        %
        function SpinSliderSet(this,i,pflag)
            % Get processing flag
            pflag = ~((nargin >= 3) && (pflag == false));
            
            % Get slider value
            val = get(this.uich(i),'Value');
            
            % Format spin value
            val = this.FormatSpin(this.options{i}.name,val);
            
            % Update slider value text
            str = num2str(val);
            set(this.vh(i),'String',str);
            
            % Process based on default class
            if ischar(this.options{i}.default)
                % Save updated state in default field
                this.options{i}.default = str;
                
                % Process option, if necessary
                if (pflag == true)
                    this.ProcessOption(this.options{i}.name,str);
                end
            else
                % Save updated state in default field
                this.options{i}.default = val;
                
                % Process option, if necessary
                if (pflag == true)
                    this.ProcessOption(this.options{i}.name,val);
                end
            end
        end
        
        %
        % Handle combo box callback
        %
        function ComboSet(this,i,pflag)
            % Get processing flag
            pflag = ~((nargin >= 3) && (pflag == false));
            
            % Get combo-box choice
            strs = get(this.uich(i),'String');
            str = strs{get(this.uich(i),'Value')};
            
            % Save updated state in default field
            this.options{i}.default = str;
            
            % Process option, if necessary
            if (pflag == true)
                this.ProcessOption(this.options{i}.name,str);
            end
        end
        
        %
        % Handle checkbox callback
        %
        function CheckSet(this,i,pflag)
            % Get processing flag
            pflag = ~((nargin >= 3) && (pflag == false));
            
            % Get checkbox value
            bool = get(this.uich(i),'Value');
            
            % Save updated state in default field
            if ischar(this.options{i}.default)
                % Save as string
                strs = {'false','true'};
                str = strs{bool + 1};
                this.options{i}.default = str;
                
                % Process option, if necessary
                if (pflag == true)
                    this.ProcessOption(this.options{i}.name,str);
                end
            else
                % Save as logical
                this.options{i}.default = bool;
                
                % Process option, if necessary
                if (pflag == true)
                    this.ProcessOption(this.options{i}.name,bool);
                end
            end
        end
        
        %
        % Handle button callback
        %
        function ButtonSet(this,i,pflag)
            % Get processing flag
            pflag = ~((nargin >= 3) && (pflag == false));
            
            % Process option, if necessary
            if (pflag == true)
                this.ProcessOption(this.options{i}.name);
            end
        end
        
        %
        % Initialize GUI
        %
        function InitializeGUI(this,xyc)
            % Get local copy of options
            opts = this.options;
            
            % Load constants
            n = length(opts);
            dl = OptionsWindow.LABEL_WIDTH;            
            dx = OptionsWindow.CONTROL_WIDTH;
            dy = OptionsWindow.CONTROL_HEIGHT;
            ds = OptionsWindow.FBORDER;
            dt = OptionsWindow.CONTROL_GAP;
            dsv = (dx - dt) * OptionsWindow.SLIDER_DX;
            dpb = dx * OptionsWindow.BUTTON_DX;
            dpu = dx * OptionsWindow.POPUP_DX;
            dim = [(2 * ds + 3.75 * dt + dl + dx) ...
                   ((n + 0.75) * dy + (n + 1) * dt + 2 * ds)];
            labelSize = OptionsWindow.LABEL_SIZE;
            fontSize = OptionsWindow.FONT_SIZE;
            
            % Create a nice figure
            this.fig = figure('MenuBar','None', ...
                      'NumberTitle','off', ...
                      'DockControl','off', ...
                      'name',[this.name ' Options'], ...
                      'tag',this.tag, ...
                      'Position',[(xyc - 0.5 * dim) dim], ...
                      'Resize','off', ...
                      'Interruptible','on', ...
                      'WindowKeyPressFcn',@(s,e)HandleKeyPress(this,e), ...
                      'CloseRequestFcn',@(s,e)CloseGUI(this), ...
                      'Visible','off');
            
            % Create options uipanel
            this.uiph = uipanel('Parent',this.fig, ...
                                'Units','pixels', ...
                                'Position',[ds ds (dim - 2 * ds + 2)], ...
                                'FontSize',labelSize, ...
                                'TitlePosition','centertop', ...
                                'Title','Options');
            
            % Add option uicontrols
            for i = 1:n
                % Add text label
                j = n + 1 - i;
                txtpos = [dt (j * dt + (j - 1) * dy) dl dy];
                uicontrol('Parent',this.uiph,...
                                'Units','pixels', ...
                                'Position',txtpos, ...
                                'FontSize',fontSize, ...
                                'Style','edit',...
                                'Enable','inactive', ...
                                'HorizontalAlignment','left', ...
                                'String',[' ' opts{i}.name]);
                
                % Process based on option type
                pos = [(2 * dt + dl) (j * dt + (j - 1) * dy) dx dy];
                switch lower(opts{i}.type)
                    case 'string'
                        % Edit box
                        spos = pos + 0.25 * dt * [0 0 1 0];
                        str = opts{i}.default;
                        this.uich(i) = uicontrol('Parent',this.uiph,...
                                'Units','pixels', ...
                                'Position',spos, ...
                                'Callback',@(s,e)StringSet(this,i), ...
                                'FontSize',fontSize, ...
                                'BackgroundColor',OptionsWindow.ACTIVE, ...
                                'Style','edit',...
                                'String',str);
                    case 'spin'
                        % Value box
                        vpos = pos + (dx - dsv(1)) * [0 0 -1 0];
                        this.vh(i) = uicontrol('Parent',this.uiph,...
                                'Units','pixels', ...
                                'Position',vpos, ...
                                'FontSize',fontSize, ...
                                'Style','edit',...
                                'Enable','on', ...
                                'Callback',@(s,e)SpinValueSet(this,i), ...
                                'HorizontalAlignment','center', ...
                                'BackgroundColor',OptionsWindow.ACTIVE, ...
                                'String',opts{i}.default);
                        
                        % Slider
                        spos = pos + (dt + dsv(1)) * [1 0 -1 0];
                        minval = opts{i}.min;
                        if ischar(minval)
                            minval = str2double(minval);
                        end
                        maxval = opts{i}.max;
                        if ischar(maxval)
                            maxval = str2double(maxval);
                        end
                        val = opts{i}.default;
                        if ischar(val)
                            val = str2double(val);
                        end
                        step = [1 10] / OptionsWindow.NUM_SLIDER_STEPS;
                        this.uich(i) = uicontrol('Parent',this.uiph,...
                                'Units','pixels', ...
                                'Position',spos, ...
                                'Callback',@(s,e)SpinSliderSet(this,i), ...
                                'FontSize',fontSize, ...
                                'BackgroundColor',OptionsWindow.ACTIVE, ...
                                'Style','slider',...
                                'SliderStep',step, ...
                                'Min',minval, ...
                                'Max',maxval, ...
                                'Value',val);
                    case 'combo'
                        % Popup
                        ppos = pos + (dx - dpu) * [0.5 0 -1 0];
                        strs = opts{i}.var;
                        val = find(ismember(strs,{opts{i}.default}));
                        this.uich(i) = uicontrol('Parent',this.uiph,...
                                'Units','pixels', ...
                                'Position',ppos, ...
                                'Callback',@(s,e)ComboSet(this,i), ...
                                'FontSize',fontSize, ...
                                'BackgroundColor',OptionsWindow.ACTIVE, ...
                                'Style','popup',...
                                'String',opts{i}.var, ...
                                'Value',val);
                    case 'check'
                        % Checkbox (centered)
                        pos(1) = pos(1) + 0.5 * dx - 7;
                        pos(3) = pos(3) - 0.5 * dx + 7;
                        val = opts{i}.default;
                        if ischar(opts{i}.default)
                            val = strcmpi(val,'true');
                        end
                        this.uich(i) = uicontrol('Parent',this.uiph,...
                                'Units','pixels', ...
                                'Position',pos, ...
                                'Callback',@(s,e)CheckSet(this,i), ...
                                'FontSize',fontSize, ...
                                'Style','checkbox',...
                                'Value',val);
                    case 'button'
                        % Pushbutton
                        bpos = pos + (dx - dpb) * [0.5 0 -1 0];
                        this.uich(i) = uicontrol('Parent',this.uiph,...
                                'Units','pixels', ...
                                'Position',bpos, ...
                                'Callback',@(s,e)ButtonSet(this,i), ...
                                'FontSize',fontSize, ...
                                'Style','pushbutton',...
                                'String',opts{i}.name);
                end
            end
                        
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
    end
end
