function jhandle = findjobj(container)
%--------------------------------------------------------------------------
% Syntax:       jhandle = findjobj(container);
%               
% Inputs:       container is the handle to a MATLAB object of interest
%               
% Outputs:      jhandle is the handle to the Java object associated with
%               the input container (if this function succeeds)
%               
% Note:         This is a skeleton version of the full findjobj() function
%               by Yair Altman on the MATLAB File Exchange. This version
%               has been stripped down to the minimal amount needed to
%               return the Java handle of a uitable() object. If this
%               function throws an error, try replacing it with the full-
%               version of findjobj.m from Yair Altman on the MATLAB File
%               Exchange. If it too fails, you will, unfortunately, be
%               unable to use the Move List functionality of Chess Master
%               
% Author:       Brian Moore
%               brimoor@umich.edu
%               
%       +---------------------------------------------------------+
%       |                 Original Author/License                 |
%       +---------------------------------------------------------+
%       | Author:    Yair M. Altman                               |
%       |            altmany(at)gmail.com                         |
%       +---------------------------------------------------------+
%       | License to use and modify this code is granted freely   |
%       | to all interested, as long as the original author is    |
%       | referenced and attributed as such. The original author  |
%       | maintains the right to be solely associated with this   |
%       | work.                                                   |
%       +---------------------------------------------------------+
%               
% Date:         June 8, 2014
%--------------------------------------------------------------------------

% Initializations
handles          = handle([]);
levels           = [];
parentIdx        = [];
positions        = [];
nomenu           = false;
menuBarFoundFlag = false;

% Ensure all objects are rendered
drawnow; pause(0.001);

try
    % Get containing figure
    hFig = ancestor(container,'figure');
    
    % Define some traversal arguments
    pos = fix(getpixelposition(container,1));
    args = {'position',pos(1:2) + [0 pos(4)], ...
            'size',pos(3:4), ...
            'not','class','java.awt.Panel','nomenu'};
    nomenu = 1;
    
    % Get root java panel
    [container contentSize] = getRootPanel(hFig);
    
    % Traverse the container hierarchy and record java elements
    handles   = repmat(handles,1,1000);
    positions = zeros(1000,2);
    traverseContainer(container,0,1);
    dataLen                        = length(levels);
    handles((dataLen + 1):end)     = [];
    positions((dataLen + 1):end,:) = [];
    selectedIdx                    = 1:length(handles);
    
    % Process args
    processArgs(args{:});
    
    % Return java handle (hopefully!)
    jhandle = handles(1);
    return;
catch %#ok
    % Explain the problem to the user
    msgid = 'FINDJOBJ:SKELETONFAIL';
    errmsg = {'*--------------------------------------------------------------*';
              '| This skeleton version of findjobj() has failed. It relies on |';
              '| UNDOCUMENTED Java methods that seem to be broken in your     |';
              '| MATLAB distribution. Try replacing findjobj.m file with the  |';
              '| full-version of findjobj() from Yair Altman on the MATLAB    |';
              '| File Exchange. If it too fails, you will, unfortunately, be  |';
              '| unable to use the the Move List feature of Chess Master.     |';
              '*--------------------------------------------------------------*'};
    error(msgid,'\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s',errmsg{:});
end


%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% NESTED METHODS
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------


%
% Get Java reference to top-level (root) panel
%
function [jRootPane,contentSize] = getRootPanel(hFig)
    try
        contentSize = [0 0];
        jRootPane   = hFig;
        figName     = get(hFig,'name');
        mde         = com.mathworks.mde.desk.MLDesktop.getInstance;
        jFigPanel   = mde.getClient(figName);
        jRootPane   = jFigPanel;
        jRootPane   = jFigPanel.getRootPane;
    catch %#ok
        try
            warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame'); % R2008b compatibility
            jFrame    = handle(get(hFig,'JavaFrame'));
            jFigPanel = get(jFrame,'FigurePanelContainer');
            jRootPane = jFigPanel;
            jRootPane = jFigPanel.getComponent(0).getRootPane;
        catch %#ok
            % Nevermind...
        end
    end
    try
        % If invalid RootPane - try another method
        warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame'); % R2008b compatibility
        jFrame         = handle(get(hFig,'JavaFrame'));
        jAxisComponent = get(jFrame,'AxisComponent');
        jRootPane      = jAxisComponent.getParent.getParent.getRootPane;
    catch %#ok
        % Nevermind...
    end
    
    try
        % If invalid RootPane, retry a few times
        tries = 10;
        while (isempty(jRootPane) && (tries > 0))
            drawnow; pause(0.001);
            tries = tries - 1;
            jRootPane = jFigPanel.getComponent(0).getRootPane;
        end
        
        % If still invalid, try to use FigurePanelContainer
        if isempty(jRootPane)
            jRootPane = jFigPanel;
        end
        contentSize = [jRootPane.getWidth jRootPane.getHeight];
        
        % Try to get the ancestor FigureFrame
        jRootPane = jRootPane.getTopLevelAncestor;
    catch %#ok
        % Nevermind...
    end
end

%
% Traverse the container hierarchy and extract the elements within
%
function traverseContainer(jcontainer,level,parent)
    % Persistent traversal variables
    persistent figureComponentFound;
    
    % Record the data for this node
    thisIdx            = length(levels) + 1;
    levels(thisIdx)    = level;
    parentIdx(thisIdx) = parent;
    handles(thisIdx)   = handle(jcontainer,'callbackproperties');
    try
        positions(thisIdx,:) = getXY(jcontainer);
    catch %#ok
        positions(thisIdx,:) = [0 0];
    end
    if (level > 0)
        positions(thisIdx,:) = positions(thisIdx,:) + positions(parent,:);
        if ((figureComponentFound == false) && ...
             strcmp(jcontainer.getName,'fComponentContainer') && ...
             isa(jcontainer,'com.mathworks.hg.peer.FigureComponentContainer'))
            % restart coordinate system, to exclude menu & toolbar areas
            positions(thisIdx,:) = positions(thisIdx,:) - [jcontainer.getRootPane.getX jcontainer.getRootPane.getY];
            figureComponentFound = true;
        end
    elseif (level == 1)
        positions(thisIdx,:) = positions(thisIdx,:) + positions(parent,:);
    else
        % level 0 - initialize flags used later
        figureComponentFound = false;
    end
    parentId = length(parentIdx);
    
    % Now recursively process all this node's children (if any), except menu items if so requested
    try
        if (~nomenu || menuBarFoundFlag || isempty(strfind(class(jcontainer),'FigureMenuBar')))
            lastChildComponent = java.lang.Object;
            child = 0;
            while (child < jcontainer.getComponentCount)
                childComponent = jcontainer.getComponent(child);
                if isequal(childComponent,lastChildComponent)
                    child = child + 1;
                    childComponent = jcontainer.getComponent(child);
                end
                lastChildComponent = childComponent;
                traverseContainer(childComponent,level + 1,parentId);
                child = child + 1;
            end
        else
            menuBarFoundFlag = true;  % use this flag to skip further testing for FigureMenuBar
        end
    catch %#ok
        % Nevermind...
    end
    
    % ...and yet another type of child traversal...
    try
        if (isdeployed == false)
            jc = jcontainer.java;
        else
            jc = jcontainer;
        end
        for child = 1:jc.getChildCount
            traverseContainer(jc.getChildAt(child - 1),level + 1,parentId);
        end
    catch %#ok
        % Nevermind...
    end
end

%
% Get the XY location of a java component
%
function xy = getXY(jcontainer)
    try 
        cls = getClass(jcontainer);
        location = com.mathworks.jmi.AWTUtilities.invokeAndWait(jcontainer,getMethod(cls,'getLocation',[]),[]);
        x = location.getX;
        y = location.getY;
    catch %#ok
        try
            x = com.mathworks.jmi.AWTUtilities.invokeAndWait(jcontainer,getMethod(cls,'getX',[]),[]);
            y = com.mathworks.jmi.AWTUtilities.invokeAndWait(jcontainer,getMethod(cls,'getY',[]),[]);
        catch %#ok
            try
                x = awtinvoke(jcontainer,'getX()');
                y = awtinvoke(jcontainer,'getY()');
            catch %#ok
                x = get(jcontainer,'X');
                y = get(jcontainer,'Y');
            end
        end
    end
    xy = [x y];
end

%
% Process arguments
%
function processArgs(varargin)
    % Loop over args
    invertFlag = false;
    while (~isempty(varargin) && ~isempty(handles))
        % Process current arg and its param(s)
        foundIdx = 1:length(handles);
        if iscell(varargin{1})
            varargin{1} = varargin{1}{1};
        end
        if (~isempty(varargin{1}) && (varargin{1}(1) == '-'))
            varargin{1}(1) = [];
        end
        switch lower(varargin{1})
            case 'not'
                invertFlag = true;
            case 'position'
                [varargin foundIdx] = processPositionArgs(varargin{:});
                if (invertFlag == true)
                    foundIdx = ~foundIdx;
                    invertFlag = false;
                end
            case 'size'
                [varargin foundIdx] = processSizeArgs(varargin{:});
                if (invertFlag == true)
                    foundIdx = ~foundIdx;
                    invertFlag = false;
                end
            case 'class'
                [varargin foundIdx] = processClassArgs(varargin{:});
                if (invertFlag == true)
                    foundIdx = ~foundIdx; 
                    invertFlag = false;
                end
        end
        
        % If only parent-child pairs found
        foundIdx = find(foundIdx);
        if (~isempty(foundIdx) && isequal(parentIdx(foundIdx(2:2:end)),foundIdx(1:2:end)))
            % Return only children (the parent panels are uninteresting)
            foundIdx(1:2:end) = [];
        end
        
        % If several possible handles were found and the first is the container of the second
        if ((length(foundIdx) == 2) && isequal(handles(foundIdx(1)).java,handles(foundIdx(2)).getParent))
            % Discard uninteresting component container
            foundIdx(1) = [];
        end
        
        % Filter the results
        selectedIdx = selectedIdx(foundIdx);
        handles     = handles(foundIdx);
        levels      = levels(foundIdx);
        parentIdx   = parentIdx(foundIdx);
        positions   = positions(foundIdx,:);
        
        % Remove this arg and proceed to the next one
        varargin(1) = [];
    end 
end

%
% Process 'position' option
%
function [varargin foundIdx] = processPositionArgs(varargin) %#ok
    positionFilter = varargin{2};
    filterXY       = [(container.getX + positionFilter(1)) ...
                      (container.getY + contentSize(2) - positionFilter(2))];
    baseDeltas     = [(positions(:,1) - filterXY(1)) ...
                      (positions(:,2) - filterXY(2))];
    foundIdx       = ((abs(baseDeltas(:,1)) < 7) & (abs(baseDeltas(:,2)) < 7));
    varargin(2)    = [];
end

%
% Process 'size' option
%
function [varargin foundIdx] = processSizeArgs(varargin) %#ok
    sizeFilter   = lower(varargin{2});
    filterWidth  = sizeFilter(1);
    filterHeight = sizeFilter(2);
    foundIdx(length(handles)) = false;
    for idx = 1:length(handles)
        % Allow a 2-pixel tollerance to account for non-integer pixel sizes
        foundIdx(idx) = ((abs(handles(idx).getWidth  - filterWidth)  <= 3) && ...
                         (abs(handles(idx).getHeight - filterHeight) <= 3));
    end
    varargin(2) = [];
end

%
% Process 'class' option
%
function [varargin foundIdx] = processClassArgs(varargin) %#ok
    % Convert all java classes to java.lang.Strings and compare to the requested filter string
    classFilter = varargin{2};
    try
        foundIdx(length(handles)) = false;
        jClassFilter = java.lang.String(classFilter).toLowerCase;
        for componentIdx = 1:length(handles)
            % Note: JVM 1.5's String.contains() appears slightly slower and is available only since Matlab 7.2
            foundIdx(componentIdx) = (handles(componentIdx).getClass.toString.toLowerCase.indexOf(jClassFilter) >= 0);
        end
    catch %#ok
        % Simple processing: slower since it does extra processing within opaque.char()
        for componentIdx = 1:length(handles)
            % Note: using @toChar is faster but returns java String, not a Matlab char
            foundIdx(componentIdx) = ~isempty(regexpi(char(handles(componentIdx).getClass),classFilter));
        end
    end
    varargin(2) = [];
end


%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% NESTED METHODS
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------


end
