function filename = getfilename(tree)
% XMLTREE/GETFILENAME Get filename method
% FORMAT filename = getfilename(tree)
% 
% tree     - XMLTree object
% filename - XML filename
%_______________________________________________________________________
%
% Return the filename of the XML tree if loaded from disk and an empty 
% string otherwise.
%_______________________________________________________________________
% @(#)getfilename.m               Guillaume Flandin            02/03/27

filename = tree.filename;
