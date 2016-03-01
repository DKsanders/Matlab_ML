classdef ChessOptions < OptionsWindow
%
% Class that spawns and coordinates a ChessMaster options dialog with a
% ChessMaster GUI
%
% NOTE: This class is used internally by the ChessMaster GUI and is not
%       intended for public invocation
%
% Brian Moore
% brimoor@umich.edu
%

    %
    % Public properties
    %
    properties (Access = public)
        % Parent info
        name = 'Chess Master';              % Parent name string
        tag = 'ChessOptions';               % Figure tag
    end
    
    %
    % Private properties
    %
    properties (Access = private)
        % Chess Master GUI
        CM;                                 % ChessMaster handle
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = ChessOptions(CM,options)
            % Call OptionsWindow constructor
            this = this@OptionsWindow(options);
            
            % Save ChessMaster object
            this.CM = CM;
            
            % Load default option values
            this.LoadDefaultValues();
        end
        
        %
        % Close chess options
        %
        function options = Close(this)
            % Return current options
            options = this.options;
            
            % Delete underlying OptionsWindow object 
            delete(this);
        end
    end
    
    %
    % Protected methods
    %
    methods (Access = protected)
        %
        % Format string content
        %
        function str = FormatString(this,name,str) %#ok
            % Empty
        end
        
        %
        % Format spin (slider) content
        %
        function val = FormatSpin(this,name,val) %#ok
            % Process based on option name
            switch name
                case 'Animation FPS'
                    % Round to nearest integer
                    val = round(val);
                case 'Dialog Move Threshold'
                    % Round to nearest integer
                    val = round(val);
                case 'Figure Opacity'
                    % Round to hundreths place
                    val = round(100 * val) / 100;
            end
        end
        
        %
        % Process option
        %
        function ProcessOption(this,name,val)
            % Process based on options name
            switch name
                case 'White Player'
                    % Update white player name
                    this.CM.whiteName = val;
                case 'Black Player'
                    % Update black player name
                    this.CM.blackName = val;
                case 'Animate Moves'
                    % Update move animation state
                    this.CM.UpdateMoveAnimation(val);
                case 'Animation FPS'
                    % Update animation FPS
                    this.CM.SetAnimationFPS(val);
                case 'Last Move Highlights'
                    % Update last move highlights
                    this.CM.UpdateLastMoveHighlights(val);
                case 'Current Move Highlights'
                    % Update current move highlights
                    this.CM.UpdateCurrentMoveHighlights(val);
                case 'Last Move Menus'
                    % Update last move menu state
                    this.CM.UpdateLastMoveMenuState(val);
                case 'Turn Marker'
                    % Update turn marker state
                    this.CM.UpdateTurnMarkerState(val);
                case 'Check Text'
                    % Update check text state
                    this.CM.UpdateCheckTextState(val);
                case 'Status Menu'
                    % Update status menu state
                    this.CM.UpdateStatusMenuState(val);
                case 'Undo/Redo Dialog'
                    % Update undo/redo dialog state
                    this.CM.UpdateUndoRedoDialogState(val);
                case 'Dialog Move Threshold'
                    % Update dialog move threshold
                    this.CM.UpdateMoveThreshold(val);
                case 'File/Rank Labels'
                    % Update file/rank labels
                    this.CM.UpdateFileRankLabels(val);
                case 'Allow Popups'
                    % Update popup state
                    this.CM.UpdatePopupState(val);
                case 'Allow Move Lists'
                    % Update MoveList enable state
                    this.CM.UpdateMoveListEnableState(val);
                case 'Allow Game Analyzers'
                    % Update GameAnalyzer enable state
                    this.CM.UpdateGameAnalyzerEnableState(val);
                case 'Allow Chess Clocks'
                    % Update ChessClock enable state
                    this.CM.UpdateChessClockEnableState(val);
                case 'Default Time Control'
                    try
                        % Try to parse default time control
                        ChessClock.ParseTimeControl(val);
                        
                        % Update default time control value
                        this.CM.defTimeControl = val;
                    catch ME
                        % Warn user that time control wasn't supported
                        warning(ME.identifier,ME.message);
                        
                        % Revert to existing time control
                        this.SetOption(name,this.CM.defTimeControl,false);
                    end
                case 'Close Child Figures'
                    % Close all child figures
                    this.CM.FM.CloseAllExcept(this.CM.tag);
                case 'Figure Opacity'
                    % Change figure opacity
                    alpha = this.CM.FM.SetAlpha(val);
                    if (alpha ~= val)
                        % Change failed, so revert option to actual value
                        this.SetOption(name,alpha,false);
                    end
            end
        end
    end
    
    %
    % Private methods
    %
    methods (Access = private)
        %
        % Load default option values
        %
        function LoadDefaultValues(this)
            % Loop over options
            for i = 1:length(this.options)
                % Set default option value, if necessary
                if isfield(this.options{i},'default')
                    val = this.options{i}.default;
                    this.ProcessOption(this.options{i}.name,val);
                end
            end
        end
    end
end
