function tree = setfilename(tree,filename)
% XMLTREE/SETFILENAME Set filename method
% FORMAT tree = setfilename(tree,filename)
% 
% tree     - XMLTree object
% filename - XML filename
%_______________________________________________________________________
%
% Set the filename linked to the XML tree as filename.
%_______________________________________________________________________
% @(#)setfilename.m               Guillaume Flandin            02/03/27

tree.filename = filename;
