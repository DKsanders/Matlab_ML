classdef ThemeEditor < handle
%
% Class that spawns a GUI for creating, editing, and deleting board themes
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
        DIM_WIDTH = 680;            % Default GUI width, in pixels
        FBORDER = 7;                % Figure border width, in pixels
        CBORDER = 12;               % Color panel spacing, in pixels
        TBORDER = 4;                % Theme panel spacing, in pixels
        BBORDER = 6;                % Button panel spacing, in pixels
        CCSQ = 30;                  % Current color square width, in pixels
        TDX = [0.25 0.75];          % Theme group relative widths
        PDX = [0.5 0.5];            % Panel relative widths
        CONTROL_HEIGHT = 20;        % Object panel heights, in pixels
        MARKER_SIZE = 6;            % Color marker size
        LINE_WIDTH = 1;             % Color marker border line width
        
        % Font sizes
        LABEL_SIZE = 12 - 2 * ispc; % UI panel font size
        FONT_SIZE = 10 - 2 * ispc;  % GUI font size
        
        % GUI colors
        ACTIVE = [252 252 252] / 255;   % Active uicontrol color
        
        % Color resolutions
        NHUE = 256;                 % Number of hues in H-S graph
        NSAT = 256;                 % Number of sats in H-S graph
        NVAL = 256;                 % Number of values in V graph
        
        % Active object "enum"
        HS_GRAPH = 1;               % H-S graph enum
        V_GRAPH = 2;                % V graph enum
        EDIT_BOXES = 3;             % Edit boxes enum
    end
    
    %
    % Public GetAccess properties
    %
    properties (GetAccess = public, SetAccess = private)
        % Figure handle
        fig;                        % Figure handle
    end
    
    %
    % Private properties
    %
    properties (Access = private)
        % ChessMaster handle
        CM;                         % Parent handle
        
        % Theme information
        color;                      % Current color theme
        fields;                     % Theme field names
        
        % GUI handles
        uicp;                       % Color panel handle
        uitp;                       % Theme panel handle
        uibp;                       % Button panel handle
        ax;                         % Axis handles
        cim;                        % Color image handles
        ph;                         % Color marker handles
        edith;                      % Edit box handles
        edit_id = nan;              % Active color index
        activeObj;                  % Active object enum
        
        % GUI size info
        cpDim;                      % Color panel dimensions
        tpDim;                      % Theme panel dimensions
        bpDim;                      % Button panel dimensions
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = ThemeEditor(CM,color,tag,varargin)
        % Syntax:   TE = ThemeEditor(CM,color,tag,'xyc',xyc);
        %           TE = ThemeEditor(CM,color,tag,'pos',pos);
        
            % Save ChessMaster handle
            this.CM = CM;
            
            % Save starting theme
            this.color = color;
            this.fields = fieldnames(color);
            
            % Initialize GUI
            this.InitializeGUI(tag,varargin{:});
        end
        
        %
        % Close GUI
        %
        function Close(this)
            try
                % Ask ChessMaster to load last saved theme
                this.CM.LoadLastTheme();
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
            elseif (~isempty(modifiers) || isempty(key))
                % Quick return
                return;
            end
            
            % Process based on active area and key pressed
            switch this.activeObj
                case ThemeEditor.HS_GRAPH
                    % H-S graph is active
                    x = get(this.ph(1),'XData');
                    y = get(this.ph(1),'YData');
                    switch key
                        case ChessMaster.LEFT
                            % Left arrow
                            if (x > 1)
                                this.UpdateHSGraph(x - 1,y);
                            end
                        case ChessMaster.RIGHT
                            % Right arrow
                            if (x < this.NHUE)
                                this.UpdateHSGraph(x + 1,y);
                            end
                        case ChessMaster.UP
                            % Up arrow
                            if (y > 1)
                                this.UpdateHSGraph(x,y - 1);
                            end
                        case ChessMaster.DOWN
                            % Down arrow
                            if (y < this.NSAT)
                                this.UpdateHSGraph(x,y + 1);
                            end
                    end
                case ThemeEditor.V_GRAPH
                    % V graph is active
                    y = get(this.ph(2),'YData');
                    switch key
                        case ChessMaster.UP
                            % Up arrow button pressed
                            if (y > 1)
                                this.UpdateVGraph(y - 1);
                            end
                        case ChessMaster.DOWN
                            % Down arrow button pressed
                            if (y < this.NVAL)
                                this.UpdateVGraph(y + 1);
                            end
                    end
                case ThemeEditor.EDIT_BOXES
                    % Edit boxes are active
                    switch key
                        case ChessMaster.UP
                            % Up arrow button pressed
                            idx = this.edit_id + 1;
                            n = length(this.fields);
                            while ((idx <= n) && ...
                                   strcmp(this.fields{idx},'name'))
                                idx = idx + 1;
                            end
                            if (idx <= n)
                                this.EnableRow(idx);
                            end
                        case ChessMaster.DOWN
                            % Down arrow button pressed
                            idx = this.edit_id - 1;
                            while ((idx >= 1) && ...
                                   strcmp(this.fields{idx},'name'))
                                idx = idx - 1;
                            end
                            if (idx >= 1)
                                this.EnableRow(idx);
                            end
                    end
            end
        end
        
        %
        % Handle H-S graph click
        %
        function HandleHSClick(this)
            % Set active object ID
            this.activeObj = ThemeEditor.HS_GRAPH;
            
            % Get click coordinates
            idx = get(this.ax(1),'CurrentPoint');
            x = round(min(max(idx(1,1),1),this.NHUE));
            y = round(min(max(idx(1,2),1),this.NSAT));
            
            % Update H-S graph
            this.UpdateHSGraph(x,y);
        end
        
        %
        % Handle V graph click
        %
        function HandleVClick(this)
            % Set active object ID
            this.activeObj = ThemeEditor.V_GRAPH;
            
            % Get click coordinate
            idx = get(this.ax(2),'CurrentPoint');
            y = round(min(max(idx(1,2),1),this.NVAL));
            
            % Update V-graph
            this.UpdateVGraph(y);
        end
        
        %
        % Update H-S graph
        %
        function UpdateHSGraph(this,x,y)
            % Get new RGB value
            RGB = get(this.cim(1),'CData');
            val = permute(double(RGB(y,x,:)),[1 3 2]);
            
            % Set H-S marker coordinates
            set(this.ph(1),'XData',x);
            set(this.ph(1),'YData',y);
            
            % Set edit box color
            this.SetColor(this.edit_id,val);
            
            % Redraw V graph
            this.RedrawVGraph(val);
            
            % Redraw current color graph
            this.RedrawCurrentColorGraph(val);
            
            % Apply theme
            this.ApplyTheme();
        end
        
        %
        % Update V graph
        %
        function UpdateVGraph(this,y)
            % Get new RGB value
            RGB = get(this.cim(2),'CData');
            val = permute(double(RGB(y,1,:)),[1 3 2]);
            
            % Set V marker coordinate
            set(this.ph(2),'YData',y);
            
            % Set edit box color
            this.SetColor(this.edit_id,val);
            
            % Redraw H-S graph
            this.RedrawHSGraph(val);
            
            % Redraw current color graph
            this.RedrawCurrentColorGraph(val);
            
            % Apply theme
            this.ApplyTheme();
        end
        
        %
        % Redraw H-S graph - val = [r g b]
        %
        function RedrawHSGraph(this,val)
            % Redraw H-S graph with given V (inferred from RGB of val)
            hsv = rgb2hsv(val / 255);
            [H S] = meshgrid(linspace(0,1,this.NHUE), ...
                             linspace(1,0,this.NSAT));
            V = repmat(hsv(3),[this.NSAT this.NHUE]);
            im = this.NearestColors(hsv2rgb(cat(3,H,S,V)));
            set(this.cim(1),'CData',im);
        end
        
        %
        % Redraw V graph - val = [r g b]
        %
        function RedrawVGraph(this,val)
            % Redraw V graph with given H-S (inferred from RGB of val)
            hsv = rgb2hsv(val / 255);
            H = repmat(hsv(1),this.NVAL,1);
            S = repmat(hsv(2),this.NVAL,1);
            V = linspace(1,0,this.NVAL)';
            im = this.NearestColors(hsv2rgb(cat(3,H,S,V)));
            set(this.cim(2),'CData',im);
        end
        
        %
        % Redraw current color graph - val = [r g b]
        %
        function RedrawCurrentColorGraph(this,val)
            % Redraw current color graph with given RGB val
            rgb = this.NearestColors(permute(val / 255,[1 3 2]));
            set(this.cim(3),'CData',rgb);
        end
        
        %
        % Enable ith row of edit boxes
        %
        function EnableRow(this,i)
            % Set active object ID
            this.activeObj = ThemeEditor.EDIT_BOXES;
            
            % Update edit boxes
            for j = 1:3
                % Deactivate old row
                set(this.edith(this.edit_id,j),'Enable','off');
                
                % Activate new row
                set(this.edith(i,j),'Enable','on');
                set(this.edith(i,j),'BackgroundColor',ThemeEditor.ACTIVE);
            end
            
            % Store new active row index
            this.edit_id = i;
            
            % Apply color
            this.ApplyColor(i);
        end
        
        %
        % Get (safe) color from row i
        %
        function val = GetColor(this,i)
            % Load color from edit boxes
            val = nan(1,3);
            for j = 1:3
                val(j) = str2double(get(this.edith(i,j),'String'));
                if isnan(val(j))
                    % Use last valid value from theme
                    val(j) = this.color.(this.fields{i})(j);
                end
            end
            
            % Round to nearest valid color
            val = this.NearestColors(permute(val / 255,[1 3 2]));
            val = permute(double(val),[1 3 2]); % val = [r g b]
        end
        
        %
        % Set specified color - val = [r g b]
        %
        function SetColor(this,i,val)
            % Save color value
            val = double(val);
            for j = 1:3
                % Store color value
                this.color.(this.fields{i})(j) = val(j);
                
                % Update edit box
                set(this.edith(i,j),'String',num2str(val(j)));
            end
        end
        
        %
        % Apply color change from row i
        %
        function ApplyColor(this,i)
            % Get current (safe) color
            val = this.GetColor(i);
            
            % Set color value
            this.SetColor(i,val);
            
            % Redraw H-S graph
            this.RedrawHSGraph(val);
            
            % Redraw V graph
            this.RedrawVGraph(val);
            
            % Redraw current color graph
            this.RedrawCurrentColorGraph(val);
            
            % Set marker coordinates
            HSim = get(this.cim(1),'CData');
            [x1 y1] = this.FindNearestColor(HSim,val);
            Vim = get(this.cim(2),'CData');
            [temp y2] = this.FindNearestColor(Vim,val); %#ok
            set(this.ph(1),'XData',x1);
            set(this.ph(1),'YData',y1);
            set(this.ph(2),'YData',y2);
            
            % Apply theme
            this.ApplyTheme();
        end
        
        %
        % Apply name change from edit box i
        %
        function ApplyName(this,i)
            % Save name string
            str = get(this.edith(i,1),'String');
            this.color.(this.fields{i}) = str;
        end
        
        %
        % Convert [0 1] image to nearest uint8 image
        %
        function im = NearestColors(this,im)
            % Clip to [0 1]
            im = min(max(im,0),1 - eps);
            
            % Nearest hue
            hues = round(linspace(0,255,this.NHUE));
            im(:,:,1) = hues(floor(this.NHUE * im(:,:,1)) + 1);
            
            % Nearest saturation
            sats = round(linspace(0,255,this.NSAT));
            im(:,:,2) = sats(floor(this.NSAT * im(:,:,2)) + 1);
            
            % Nearest value
            vals = round(linspace(0,255,this.NVAL));
            im(:,:,3) = vals(floor(this.NVAL * im(:,:,3)) + 1);
            
            % Convert to uint8 image
            im = uint8(im);
        end
        
        %
        % Find (x,y) coordinates of closest color
        %
        function [x y] = FindNearestColor(this,im,val) %#ok
            % Compute distances
            sz = size(im);
            val = permute(double(val),[1 3 2]);
            err = sum(abs(repmat(val,sz(1:2)) - double(im)),3);
            
            % Locate minimizing distance
            [temp idx] = min(err(:)); %#ok
            [y x] = ind2sub(sz(1:2),idx);
        end
        
        %
        % Apply current theme to ChessMaster GUI
        %
        function ApplyTheme(this)
            % Tell ChessMaster to paint board with current theme
            this.CM.PaintBoard(this.color);
        end
        
        %
        % Save current theme
        %
        function SaveTheme(this)
            % Tell ChessMaster to save current theme
            success = this.CM.SaveTheme();
            
            % If successful
            if (success == true)
                % Close GUI
                this.Close();
            end
        end
        
        %
        % Initialize GUI
        %
        function InitializeGUI(this,tag,varargin)
            % Constants
            dimw = ThemeEditor.DIM_WIDTH;
            fds = ThemeEditor.FBORDER;
            tds = ThemeEditor.TBORDER;
            bds = ThemeEditor.BBORDER;
            dy = ThemeEditor.CONTROL_HEIGHT;
            n = length(this.fields);
            
            % Font sizes
            labelSize = ThemeEditor.LABEL_SIZE;
            fontSize = ThemeEditor.FONT_SIZE;
            dfl = 0.25 * labelSize; % uipanel label fudge factor
            dff = 0.25 * fontSize; % uicontrol centering fudge factor
            
            % Compute and save panel sizes
            pdx = (dimw - 3 * fds) * ThemeEditor.PDX;
            this.tpDim = [pdx(2) (2 * tds + (n + 1.25) * dy + dfl)];
            this.bpDim = [pdx(2) (dy + 2 * bds)];
            this.cpDim = [pdx(1) (this.tpDim(2) + this.bpDim(2) + fds)];
            
            % Parse figure position
            if strcmpi(varargin{1},'xyc')
                % GUI center specified
                dim = [dimw (2 * fds + this.cpDim(2))];
                pos = [(varargin{2} - 0.5 * dim) dim];
            elseif strcmpi(varargin{1},'pos')
                % Position specified directly
                pos = varargin{2};
            end
            
            % Create a nice figure
            this.fig = figure('MenuBar','None', ...
                      'NumberTitle','off', ...
                      'DockControl','off', ...
                      'name','Theme Editor', ...
                      'tag',tag, ...
                      'Position',pos, ...
                      'Resize','on', ...
                      'WindowKeyPressFcn',@(s,e)HandleKeyPress(this,e), ...
                      'ResizeFcn',@(s,e)ResizeComponents(this), ...
                      'CloseRequestFcn',@(s,e)Close(this), ...
                      'Visible','off');
            
            %--------------------------------------------------------------
            % Create color panel
            %--------------------------------------------------------------
            % UI panel
            this.uicp = uipanel('Parent',this.fig, ...
                                'Units','pixels', ...
                                'FontUnits','points', ...
                                'FontSize',labelSize, ...
                                'TitlePosition','centertop', ...
                                'Title','Color');
            
            % H-S graph
            this.ax(1) = axes('Parent',this.uicp, ...
                              'Units','pixels');
                             %'Visible','off');
            this.cim(1) = image([1 this.NHUE],[1 this.NSAT], ...
                                zeros(this.NSAT,this.NHUE,3,'uint8'), ...
                               'Parent',this.ax(1), ...
                               'ButtonDownFcn',@(s,e)HandleHSClick(this));
            axis(this.ax(1),'off');
            axis(this.ax(1),'tight');
            set(this.ax(1),'XLimMode','manual');
            set(this.ax(1),'YLimMode','manual');
            hold(this.ax(1),'on');
            
            % V graph
            this.ax(2) = axes('Parent',this.uicp, ...
                              'Units','pixels');
                             %'Visible','off');
            this.cim(2) = image([1 1],[1 this.NSAT], ...
                                zeros(this.NVAL,1,3,'uint8'), ...
                               'Parent',this.ax(2), ...
                               'ButtonDownFcn',@(s,e)HandleVClick(this));
            axis(this.ax(2),'off');
            axis(this.ax(2),'tight');
            set(this.ax(2),'XLimMode','manual');
            set(this.ax(2),'YLimMode','manual');
            hold(this.ax(2),'on');
            
            % Current color graph
            this.ax(3) = axes('Parent',this.uicp, ...
                              'Units','pixels');
                             %'Visible','off');
            this.cim(3) = image([0 1],[0 1], ...
                                zeros(1,1,3,'uint8'), ...
                               'Parent',this.ax(3));
            axis(this.ax(3),'off');
            axis(this.ax(3),'tight');
            set(this.ax(3),'XLimMode','manual');
            set(this.ax(3),'YLimMode','manual');
            hold(this.ax(3),'on');
            
            % Current color markers
            this.ph(1) = plot(this.ax(1),0,0,'s', ...
                             'LineWidth',ThemeEditor.LINE_WIDTH,...
                             'MarkerEdgeColor','k',...
                             'MarkerFaceColor','w',...
                             'MarkerSize',ThemeEditor.MARKER_SIZE);
            this.ph(2) = plot(this.ax(2),1,0,'s', ...
                             'LineWidth',ThemeEditor.LINE_WIDTH,...
                             'MarkerEdgeColor','k',...
                             'MarkerFaceColor','w',...
                             'MarkerSize',ThemeEditor.MARKER_SIZE);
            %--------------------------------------------------------------
            
            %--------------------------------------------------------------
            % Create theme panel
            %--------------------------------------------------------------
            % Component positions/dimensions
            tdx = (this.tpDim(1) - 2.75 * tds) * ThemeEditor.TDX;
            tdx = [tdx(1) repmat(tdx(2) / 3,1,3)];
            pos = @(i,j) [(tds + sum(tdx(1:(j - 1)))) ...
                          (tds + (i - 1) * dy) ...
                          tdx(j) dy];
            pos_name = @(i) [(tds + tdx(1)) ...
                             (tds + (i - 1) * dy) ...
                             sum(tdx(2:end)) dy];
            
            % UI panel
            this.uitp = uipanel('Parent',this.fig, ...
                                'Units','pixels', ...
                                'FontUnits','points', ...
                                'FontSize',labelSize, ...
                                'TitlePosition','centertop', ...
                                'Title','Theme');
            
            % RGB labels
            labels = {'R','G','B'};
            for j = 1:3
                uicontrol('Parent',this.uitp, ...
                          'Style','text', ...
                          'Units','pixels', ...
                          'Position',pos(n + 1,j + 1) - 3 * [0 dff 0 0],...
                          'FontUnits','points', ...
                          'FontSize',fontSize, ...
                          'HorizontalAlignment','center', ...
                          'String',labels{j});
            end
            
            % Theme edit boxes
            this.edith = nan(n,3);
            for i = 1:n
                % Label each row
                uicontrol('Parent',this.uitp, ...
                          'Style','text', ...
                          'Units','pixels', ...
                          'Position',pos(i,1) - [0 dff 0 0], ...
                          'FontUnits','points', ...
                          'FontSize',fontSize, ...
                          'HorizontalAlignment','center', ...
                          'String',this.fields{i});
                
                % Process based on field type
                if strcmpi(this.fields{i},'name')
                    % Handle name field (separately)
                    this.edith(i,1) = uicontrol('Parent',this.uitp, ...
                                  'Style','edit', ...
                                  'Units','pixels', ...
                                  'Position',pos_name(i), ...
                                  'Enable','on', ...
                                  'Callback',@(s,e)ApplyName(this,i), ...
                                  'BackgroundColor',ThemeEditor.ACTIVE, ...
                                  'String',this.color.(this.fields{i}));
                else
                    % Handle color field
                    this.edit_id = i; % Save default active index
                    for j = 1:3
                        str = num2str(this.color.(this.fields{i})(j));
                        this.edith(i,j) = uicontrol('Parent',this.uitp, ...
                               'Style','edit', ...
                               'Units','pixels', ...
                               'Position',pos(i,j + 1), ...
                               'Enable','off', ...
                               'Callback',@(s,e)ApplyColor(this,i), ...
                               'ButtonDownFcn',@(s,e)EnableRow(this,i), ...
                               'String',str);
                    end
                end
            end
            %--------------------------------------------------------------
            
            %--------------------------------------------------------------
            % Create button panel
            %--------------------------------------------------------------
            % Button positions
            bw = (this.bpDim(1) - 4.45 * bds) / 2;
            bh = this.bpDim(2) - 2 * bds;
            pos = @(i) [(i * bds + (i - 1) * bw) bds bw bh];
            
            % UI panel
            this.uibp = uipanel('Parent',this.fig, ...
                                'Units','pixels', ...
                                'Title','');
            
            % Save button
            uicontrol('Style','pushbutton', ...
                      'Parent',this.uibp, ...
                      'Units','pixels', ...
                      'Position',pos(1), ...
                      'String','Save', ...
                      'Callback',@(s,e)SaveTheme(this), ...
                      'FontUnits','points', ...
                      'FontSize',fontSize, ...
                      'HorizontalAlignment','center');
            
            % Cancel button
            uicontrol('Style','pushbutton', ...
                      'Parent',this.uibp, ...
                      'Units','pixels', ...
                      'Position',pos(2), ...
                      'String','Cancel', ...
                      'Callback',@(s,e)Close(this), ...
                      'FontUnits','points', ...
                      'FontSize',fontSize, ...
                      'HorizontalAlignment','center');
            %--------------------------------------------------------------
            
            % Enable default color row
            this.EnableRow(this.edit_id);
            
            % Resize GUI components
            this.ResizeComponents();
            
            % Make GUI visible
            set(this.fig,'Visible','on');
        end
        
        %
        % Resize GUI components
        %
        function ResizeComponents(this)
            % Get constants
            fds = ThemeEditor.FBORDER;
            cds = ThemeEditor.CBORDER;
            ccsq = ThemeEditor.CCSQ;
            dcf = cds - 2; % uipanel label fudge factor
            
            % Get figure dimensions
            pos = get(this.fig,'Position');
            xfig = pos(3);
            yfig = pos(4);
            
            % Resize figure, if necessary
            xmin = 3 * fds + 3 * cds + 2 * ccsq + this.tpDim(1) - 2;
            ymin = 3 * fds + this.bpDim(2) + this.tpDim(2) - 2;
            if ((xfig < xmin) || (yfig < ymin))
                xfig = max([xfig xmin]);
                yfig = max([yfig ymin]);
                set(this.fig,'Position',[pos(1:2) xfig yfig]);
            end
            
            % Update theme panel position
            x0tp = xfig - fds - this.tpDim(1) + 2;
            y0tp = yfig - fds - this.tpDim(2) + 2;
            set(this.uitp,'Position',[x0tp y0tp this.tpDim]);
            
            % Update button panel position
            x0bp = xfig - fds - this.bpDim(1) + 2;
            y0bp = y0tp - fds - this.bpDim(2);
            set(this.uibp,'Position',[x0bp y0bp this.bpDim]);
            
            %--------------------------------------------------------------
            % Update color panel size/position
            %--------------------------------------------------------------
            % Update uipanel position
            cpw = xfig - 3 * fds - this.tpDim(1) + 2;
            cph = yfig - 2 * fds + 2;
            set(this.uicp,'Position',[fds fds cpw cph]);
            
            % Update H-S axis position
            wax1 = cpw - 3 * cds - ccsq;
            hax1 = cph - 2 * cds - dcf;
            set(this.ax(1),'Position',[cds cds wax1 hax1]);
            
            % Update V axis position
            x0ax2 = 2 * cds + wax1;
            y0ax2 = 2 * cds + ccsq;
            hax2 = cph - 3 * cds - ccsq - dcf;
            set(this.ax(2),'Position',[x0ax2 y0ax2 ccsq hax2]);
            
            % Update current color axis position
            x0ax3 = 2 * cds + wax1;
            set(this.ax(3),'Position',[x0ax3 cds ccsq ccsq]);
            %--------------------------------------------------------------
        end
    end
end
