classdef EngineOptions < OptionsWindow
%
% Class that spawns and coordinates an engine options dialog with a
% ChessEngine object
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
        name = 'Engine';                % Engine name (with default set)
        tag = 'EngineOptions';          % Figure tag
    end
    
    %
    % Private properties
    %
    properties (Access = private)
        % Engine interface
        EI;                             % EngineInterface object
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = EngineOptions(EI)
            % Format options
            options = EngineOptions.FormatOptions(EI,EI.options);
            
            % Call OptionsWindow constructor
            this = this@OptionsWindow(options);
            
            % Save engine interface object
            this.EI = EI;
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
            % Convert to relative path
            str = this.EI.RelPath(str);
        end
        
        %
        % Format spin (slider) content
        %
        function val = FormatSpin(this,name,val) %#ok
            % Round to nearest integer
            val = round(val);
        end
        
        %
        % Process option
        %
        function ProcessOption(this,name,val)
            % Construct UCI command
            args.name = name; % Save name
            if (nargin >= 3)
                % Handle persistent options
                switch name
                    case 'Book File'
                        % If parent is a ChessEngine
                        if isa(this.EI.obj,'ChessEngine')
                            % Update book name
                            this.EI.obj.UpdateEngineBook(val);
                        end
                        
                        % Send absolute book path to engine
                        val = this.EI.AbsPath(val);
                end
                
                % Save value
                args.value = val;
            end
            
            % Send command to engine
            this.EI.SendCommand('setoption',args);
        end
    end
    
    %
    % Private static methods
    %
    methods (Access = private, Static = true)
        %
        % Format (and remove unwanted) options from list
        %
        function opts = FormatOptions(EI,opts)
            % Convert string options to relative paths            
            for i = 1:length(opts)
                if strcmpi(opts{i}.type,'string')
                    opts{i}.default = EI.RelPath(opts{i}.default);
                end
            end
            
            % Remove unwanted options
            ignoreOpts = {'Write Debug Log';     % No debug logging
                          'Write Search Log';    % No search logging
                          'Search Log Filename'; % No search logging
                          'UCI_Chess960'};       % No Fischer random chess 
            for i = length(opts):-1:1
                if any(ismember(ignoreOpts,opts{i}.name))
                    % Delete option
                    opts(i) = [];
                end
            end
        end
    end
end
