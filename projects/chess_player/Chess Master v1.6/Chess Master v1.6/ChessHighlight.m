classdef ChessHighlight < handle
%
% Class implementing a square highlight for the ChessMaster GUI
%
% NOTE: This class is used internally by the ChessMaster GUI and is not
%       intended for public invocation
%
% Brian Moore
% brimoor@umich.edu
%

    %
    % Public GetAccess properties
    %
    properties (GetAccess = public, SetAccess = private)
        visible = false;            % Visibility flag
        on = true;                  % On flag
        color = [0 0 0];            % Highlight color
        i;                          % File
        j;                          % Rank
    end
    
    %
    % Private properties
    %
    properties (Access = private)
        % Board state
        BS;                         % BoardState handle
        
        % Sprite data
        CHD;                        % Chess highlight data structure
        
        % GUI variables
        ax;                         % Axis handle
        ph;                         % Image handle
    end
    
    %
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = ChessHighlight(ax,BS)
            % Save external handles
            this.BS = BS;
            
            % Create highlight graphics object
            this.ax = ax;
            this.ph = image(0,'Parent',this.ax, ...
                              'Visible','off');
        end
        
        %
        % Set sprite
        %
        function SetSprite(this,CHD,color)
            % Save data
            this.CHD = CHD;
            if (nargin >= 3)
                this.color = color;
            end
            
            % Sprite parameters
            sz = this.CHD.squareSize;
            x0 = 0.5 * (sz + 1);
            y0 = 0.5 * (sz + 1);
            sigma = 1.25 * x0;
            
            % Generate sprite
            c = permute(this.color,[1 3 2]);
            I = uint8(round(repmat(c,[sz sz])));
            [X Y] = meshgrid(1:sz,1:sz);
            Z = abs(X - x0).^2.5 + abs(Y - y0).^2.5;
            alpha = uint8(round(230 * exp((-1 / (2 * sigma^2)) * Z)));
            
            % Update highlight grahpics
            set(this.ph,'CData',I, ...
                        'AlphaData',alpha, ...
                        'XData',get(this.ph,'XData'), ...
                        'YData',get(this.ph,'YData'));
            
            % If highlight is visible
            if (this.visible == true)
                % Draw highlight
                this.DrawHighlight();
            end
        end
        
        %
        % Set highlight location
        %
        function SetLocation(this,i,j)
            % Update coordinates
            this.i = i;
            this.j = j;
            
            % Draw highlight at new location
            this.DrawHighlight();
            
            % Turn on highlight
            this.On();
        end
        
        %
        % Set highlight "on" state
        %
        function SetOnState(this,bool)
            % Set on state
            this.on = bool;
            
            % Update highlights
            if ((this.visible == true) && (this.on == true))
                % Turn on highlight
                set(this.ph,'Visible','on');
            elseif (this.on == false)
                % Turn off highlight
                set(this.ph,'Visible','off');
            end
        end
        
        %
        % Turn highlight on
        %
        function On(this)
            % Set visibility flag
            this.visible = true;
            
            % Turn on highlight, if necessary
            if (this.on == true)
                set(this.ph,'Visible','on');
            end
        end
        
        %
        % Turn highlight off
        %
        function Off(this)
            % Release visibility flag
            this.visible = false;
            
            % Turn off highlight
            set(this.ph,'Visible','off');
        end
    end
    
    %
    % Private methods
    %
    methods (Access = private)
        %
        % Draw highlight
        %
        function DrawHighlight(this)
            % Get highlight limits
            xlim = this.CHD.file(this.i + [0 1]) - [0 1];
            ylim = this.CHD.rank(this.j + [0 1]) - [0 1];
            
            % Handle board orientation
            if (~isempty(this.BS) && (this.BS.flipped == true))
                % Flip coordinates
                xlim = fliplr(xlim);
                ylim = fliplr(ylim);
            end
            
            % Draw highlight at its location
            set(this.ph,'XData',xlim,'YData',ylim);
        end
    end
end
