---------------------------------------------------------------------------
                             Chess Master v1.6                             
---------------------------------------------------------------------------

                                - CLASSES -

Bishop.m            Class representing the Bishop piece
BoardEditor.m       Class that spawns a board editor GUI
BoardGeometry.m     Class that manages chessboard geometry 
BoardState.m        Class storing the current board state
ChessClock.m        Class that spawns and controls a chess clock
ChessEngine.m       Class that spawns and controls engine GUIs
ChessHighlight.m    Class that manages square highlights

*-------------------------------------------------------------------------*
| ChessMaster.m     Main ChessMaster class                                |
|                   Type "ChessMaster" to launch a GUI                    |
|                   For more details/syntaxes, type "help ChessMaster"    | 
*-------------------------------------------------------------------------*

ChessOptions.m      Class that spawns and coordinates a game options dialog
                    with the ChessMaster GUI
ChessPiece.m        Superclass extended by all piece classes
ChessPieceData.m    Class that contains chess piece graphics data
EngineInterface.m   Class that handles asynchronous communication with an
                    external chess engine via the universal chess interface
                    (UCI) communication protocol
EngineLog.m         Class that spawns and coordinates an engine
                    communication log with a ChessEngine object
EngineOptions.m     Class that spawns and coordinates an engine options
                    dialog with a ChessEngine object
FigureManager.m     Class for aggregating and managing children figures
                    spawned by the ChessMaster GUI
GameAnalyzer.m      Class that spawns a game analyzer GUI
HelpWindow.m        Class that spawns a help GUI 
King.m              Class representing the King piece
Knight.m            Class representing the Knight piece
Move.m              Class that generates objects describing moves
MoveList.m          Class that spawns a list of the current moves and
                    allows the user to graphically navigate forward/
                    backward through the current game
MutableList.m       Class that spawns a GUI for managing elements of a 
                    mutable list
OptionsWindow.m     Superclass extended by all <Class>Options classes
Pawn.m              Class representing the Pawn piece
Queen.m             Class representing the Queen piece
Rook.m              Class representing the Rook piece
ThemeEditor.m       Class that spawns a GUI for creating, editing, and
                    deleting board color themes



                               - FUNCTIONS -

findjobj.m       Function that returns the Java handle of a uitable object

NOTE:            This is a skeleton version of the full findjobj() function
                 by Yair Altman on the MATLAB File Exchange. This version
                 has been stripped down to the minimal amount needed to
                 return the Java handle of a uitable() object. If this
                 function throws an error, try replacing it with the full-
                 version of findjobj.m from Yair Altman on the FEX. If it
                 too fails, you will, unfortunately, be unable to use the
                 Move List functionality of Chess Master



                              - DIRECTORIES -

./engines/       Chess engine directory containing the following files:

    * book.bin - Polyglot opening book
    * polyglot.ini - Init. file for using Polyglot opening books 

./games/         Small database of .pgn files for 116 famous chess games

./standards/     Contains .txt files describing the UCI and PGN standards
                 supported by Chess Master



                               - MAT FILES -

data.mat         Contains a variety of data structures used by the GUI to
                 render its graphics

NOTE:            DON'T MODIFY/DELETE THIS .MAT FILE! It is loaded by the
                 ChessMaster constructor and automatically updated by the
                 ChessMaster.Close() method



                              - REQUIREMENTS -

Written using MATLAB R2011b (Mac) and MATLAB R2012a (Windows), but it is
probably forward/backward compatible, as long as your MATLAB distribution
has (1) the new uitable() function, and (2) a newish version of Java

No toolboxes required



---------------------------------------------------------------------------
       Connecting ChessMaster to a UCI-compatible chess engine       
---------------------------------------------------------------------------

The Chess Master suite fully supports the Universal Chess Interface (UCI)
communication protocol, so you should be able to connect any UCI-compatible
engine to a ChessMaster GUI. To connect a new engine, simply click
"Engine --> Add Engine..." on the ChessMaster menu bar, and enter an
(arbitrary) name and the (relative or absolute) path to the new engine's
executable

    ******************************************************************
    *  NOTE: In all engine-related setup, "./" is replaced with the  *
    *        directory in which the ChessMaster.m file resides       *
    ******************************************************************



---------------------------------------------------------------------------
                          Stockfish Installation                          
---------------------------------------------------------------------------

Stockfish is one of the top chess engines in the world, and, since it
supports UCI, you can use it with Chess Master!

                       - Installation Instructions -                       

1. Go to http://stockfishchess.org/download/ and download the "Engine
   Binaries" for your operating system.

2. (Windows) Unzip the download, navigate to the Windows/ subdirectory, and
   copy the .exe of your choice (current options below) to the ./engines/
   subdirectory, where "." is the location of ChessMaster.m

   stockfish_<ver>_32bit               CPUs running 32 bit Windows
   stockfish_<ver>_x64_modern.exe      Modern CPUs running 64 bit Windows
   stockfish_<ver>_x64.exe             Older CPUs running 32 bit Windows

2. (Mac) Unzip the download, navigate to the Mac/ subdirectory, and
   copy the executable of your choice (current options below) to the
   ./engines/ subdirectory, where "." is the location of ChessMaster.m

   stockfish-5-64                      Older 64 bit processors
   stockfish-5-bmi2                    Intel Haswell processors
   stockfish-5-sse42                   Intel Core<i> processors

3. Open a Chess Master GUI and click "Add Engine" in the "Engine" menu, and
   enter the following information

   Name: Stockfish 5         (this is arbitrary)
   Path: ./engines/<name>    (<name> = filename of engine binary from #2)

4. Done! Stockfish is now appended to the engine pop-up list of any
   subsequent Chess Engine or Game Analyzer GUIs 



---------------------------------------------------------------------------
                            Version Information                            
---------------------------------------------------------------------------
Version: 1.6
Author:  Brian Moore
         brimoor@umich.edu   (feel free to send me suggestions/feedback)
Date:    January 5, 2015


