% XMLTree: XML Toolbox for Matlab.
% Version 1.0  12-Apr-2002
%
% XML file I/O.
%   xmltree     - Constructor (XML parser).
%   save        - Save an XMLTree in a file.
%
% XML Tree manipulation methods.
%   add         - Add a node in a tree.
%   attributes  - Handle attributes of a node.
%   branch      - Extract a subtree from a tree.
%   children    - Return children of a node.
%   convert     - Convert a tree in a Matlab structure.
%   copy        - Copy nodes within a tree.
%   delete      - Delete a node in a tree.
%   find        - Find nodes in a tree.
%   flush       - Clear a subtree.
%   get         - get node properties.
%   getfilename - Get filename.
%   isfield     - Return true if a field is present in a node.
%   length      - Return the length of a tree.
%   move        - Move a node within a tree.
%   parent      - Return parents of a node.
%   root        - Return the root element of a tree.
%   set         - Set node properties.
%   setfilename - Set filename
%
% Graphical user interface methods (work in progress).
%   view        - Graphical display of a tree.
%   view_ui     - Useful function for view method.
%
% Low level class methods.
%   char        - Convert a tree into a string (for display).
%   display     - Display a tree into MATLAB.
%
% Private methods.
%   xml_parser  - XML parser.
%   xml_findstr - Find one string within another (mexfile)
%
% Demos.
%   xmldemo1    - Create an XML tree from scratch and save it.
%   xmldemo2    - Read an XML file and access fields.
%   xmldemo3    - Read an XML file, modify some fields and save it.

% Copyright 2002 Guillaume Flandin - INRIA Sophia Antipolis
% $Revision: 1.0 $
