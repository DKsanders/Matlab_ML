classdef FigureManager < handle
%
% Class for managing ChessMaster figures
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
        % Figure properties
        figs = [];                      % Figure handle list
        alpha = 1;                      % Transparency value
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = FigureManager()
            % Empty
        end
        
        %
        % Add figure to list
        %
        function AddFigure(this,fig)
            % Add figure 
            this.figs(end + 1) = fig;
            
            if (this.alpha ~= 1)
                % Apply transparency
                success = FigureManager.ApplyTransparency(this.alpha,fig);
                
                % If transparency setting failed
                if (success == false)
                    % No transparency was applied
                    this.alpha = 1;
                end
            end
        end
        
        %
        % Get handle(s) to figure(s) with the given tag(s)
        %
        function figh = GetFigHandle(this,tags)
            % Get all figure tags
            figtags = this.GetFigTags();
            
            % Return handles to matching tags
            figh = this.figs(ismember(figtags,tags));
        end
        
        %
        % Prune deleted/duplicate figure handles from list
        %
        function PruneFigHandles(this)
            % Remove deleted figures from list
            this.figs(~ishandle(this.figs)) = [];
            
            % Remove duplicate handles from list
            [temp idx] = unique(this.figs,'last'); %#ok
            this.figs = this.figs(sort(idx));
        end
        
        %
        % Get cell array of tags of all valid figures
        %
        function tags = GetFigTags(this)
            % Remove deleted figures from list
            this.PruneFigHandles();
            
            % Make sure figures exist
            if isempty(this.figs)
                % Quick return
                tags = {};
                return;
            end
            
            % Get all figure tags
            tags = get(this.figs,'tag');
            if ischar(tags)
                tags = {tags};
            end
        end
        
        %
        % Get window information struct for all figures except those with
        % the given tag(s)
        %
        function windows = GetChildWindowInfo(this,tags)
            % Get all figures except those with matching tags 
            figtags = this.GetFigTags();
            mfigs = this.figs(~ismember(figtags,tags));
            
            % Initialize info structure
            n = length(mfigs);
            windows = repmat(struct('tag','','xyc',[],'pos',[]),[n 1]);
            
            % Iterate through existing figures
            for i = 1:n
                % Save figure info
                windows(i).tag = get(mfigs(i),'tag');
                windows(i).xyc = this.GetCenterCoordinates(mfigs(i));
                windows(i).pos = this.GetPosition(mfigs(i));
            end
        end
        
        %
        % Set figure alpha value
        %
        function alpha = SetAlpha(this,alpha)
            if (alpha ~= this.alpha)
                % Remove deleted figures from list
                this.PruneFigHandles();
                
                % Apply new transparency to all figures
                success = FigureManager.ApplyTransparency(alpha,this.figs);
                
                % Check if transparency setting failed
                if (success == false)
                    % No transparency was applied
                    alpha = 1;
                end
                
                % Save new alpha value
                this.alpha = alpha;
            end
        end
        
        %
        % Get center coordinates of figure with given handle/tag
        %
        function xyc = GetCenterCoordinates(this,arg1)
            % Parse input args
            if ischar(arg1)
                % Get figure handle
                figh = this.GetFigHandle(arg1);
            else
                % Figure handle directly specified
                figh = arg1;
            end
            
            % If handle was found
            if ~isempty(figh)
                % Infer center coordinates from GUI position
                pos = get(figh(1),'Position');
                xyc = pos(1:2) + 0.5 * pos(3:4);
            else
                % Use screen-center instead
                scrsz = get(0,'ScreenSize');
                xyc = 0.5 * scrsz(3:4);
            end
        end
        
        %
        % Get position of figure with given handle/tag
        %
        function pos = GetPosition(this,arg1)
            % Parse input args
            if ischar(arg1)
                % Get figure handle
                figh = this.GetFigHandle(arg1);
            else
                % Figure handle directly specified
                figh = arg1;
            end
            
            % If handle was found
            if ~isempty(figh)
                % Get figure position
                pos = get(figh(1),'Position');
            else
                % No figure found
                pos = [];
            end
        end
        
        %
        % Close figure(s) with the given tag(s)
        %
        function CloseFigs(this,tags)
            % Close figure(s( with matching tag(s)
            close(this.GetFigHandle(tags));
        end
        
        %
        % Close all figures
        %
        function CloseAll(this)
            % Remove deleted figures from list
            this.PruneFigHandles();
            
            % Close all figures
            close(this.figs);
        end
        
        %
        % Close all figures except those with the given tag(s)
        %
        function CloseAllExcept(this,tags)
            % Get all figure tags
            figtags = this.GetFigTags();
            
            % Close all figures with *not* matching tags
            close(this.figs(~ismember(figtags,tags)));
        end
        
        %
        % Close figure manager
        %
        function delete(this)
            try
                % Close all remaining figures
                this.CloseAll();
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
    end
    
    %
    % Public static methods
    %
    methods (Access = public, Static = true)
        %
        % Apply transparency to the given figures
        %
        function success = ApplyTransparency(alpha,figs)
            % Flush graphics to ensure all figures are up-to-date
            drawnow;
            
            try
                % Loop over figures
                success = true;
                for i = 1:length(figs)
                    % Get underlying jWindow
                    jFrame = get(handle(figs(i)),'JavaFrame');
                    try
                        % MATLAB >= r2008b
                        jWin = jFrame.fHG1Client.getWindow();
                    catch %#ok
                        % MATLAB <= R2011a
                        jWin = jFrame.fFigureClient.getWindow();
                    end
                    
                    % Set jWindow opactity
                    com.sun.awt.AWTUtilities.setWindowOpacity(jWin,alpha);
                end
            catch %#ok
                % Report failure
                success = false;
                
                % Explain the problem to the user
                msg = {'*----------------------------------------------*';
                       '| Setting the transparency of a figure relies  |';
                       '| on UNDOCUMENTED Java methods that seem to be |';
                       '| broken in your MATLAB distribution. Sadly,   |';
                       '| you will be unable to use this feature.      |';
                       '*----------------------------------------------*'};
                warning('\n%s\n%s\n%s\n%s\n%s\n%s',msg{:}); %#ok
            end
        end
    end
end
