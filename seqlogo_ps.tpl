% Settings
/[%FONT%] findfont [%FONTSIZE%] scalefont setfont
/xpos [%XPOS%] def
/ypos [%YPOS%] def
/Gcolour {1.0 0.7 0.0} def
/Ccolour {0.0 0.0 1.0} def
/Tcolour {0.8 0.0 0.3} def
/Acolour {0.0 1.0 0.0} def
/baselinewidth [%BLWIDTH%] def

% Preparatory stuff
ypos /ymax exch def
xpos /xmax exch def
/width { (G) stringwidth pop } def

% This routine shows a character scaled to a specified size at the
% current position
/showchar  % size char  ->   null
{
  exch     % char size
  dup      % char size size
  3 1 roll % size char size
  1        % size char size 1
  exch     % size char 1 size
  scale    % size char
  show     % size
  1 exch   % 1 size
  div      % 1/size
  1 exch   % 1 1/size
  scale
} bind def

% Get the height of a text string on the stack
/textheight                       % text -> height
{
  % save graphic context
  gsave  
  {
     % move to some point
     100 100 moveto               % text
     % get the text path bounding box 
     % taking text from the stack
     true charpath pathbbox       % LLx LLy URx URy
     % keep LLy and URy
     exch pop 3 -1 roll pop       % LLy URy
     % Calculate URy - LLy
     exch sub                     % height           
  }
  stopped % did the last block fail?
  {
     % remove errors from "stopped"
     pop pop
     % gets alternative text height
     currentfont /FontMatrix get 3 get
  }
  if

  % restore graphic context
  grestore
} bind def

% Get the scaled height of a text string 
/getheight % size string  ->  scaledheight  
{
    textheight    % size height
    mul           % scaledsize
} bind def

/doChar  % c s -> null
{
  dup               % c s s
  x y moveto        % c s s
  3 -1 roll         % s s c

  dup               % s s c c
  (A) eq            % s s c
  { Acolour setrgbcolor }
  if
  dup               % s s c c
  (T) eq            % s s c
  { Tcolour setrgbcolor }
  if
  dup               % s s c c
  (C) eq            % s s c
  { Ccolour setrgbcolor }
  if
  dup               % s s c c
  (G) eq            % s s c
  { Gcolour setrgbcolor }
  if

  dup               % s s c c
  4 1 roll          % c s s c
  showchar          % c s
  exch              % s c
  getheight         % H
  y add /y exch def % 
} bind def

% Draw an A/T/C/G column at a specified position
% The 4 character/size pairs are taken from the stack followed
% by x and y positions.
/column            % c1 s1 c2 s2 c3 s3 c4 s4 x y  ->  null
{
  /y exch def       % c1 s1 c2 s2 c3 s3 c4 s4 x
  /x exch def       % c1 s1 c2 s2 c3 s3 c4 s4

  4 {doChar} repeat % null

  0.0 0.0 0.0 setrgbcolor
  y ymax gt
  { y /ymax exch def }
  if

  x xmax ge
  { x width add /xmax exch def }
  if
} bind def

[% COMMANDS %]

0 baselinewidth ne {
   newpath
   xpos ypos baselinewidth 2 div sub moveto
   xmax ypos baselinewidth 2 div sub lineto
   baselinewidth setlinewidth
   stroke
} if

showpage

