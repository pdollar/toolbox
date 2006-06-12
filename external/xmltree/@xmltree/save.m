function save(tree, filename)
% XMLTREE/SAVE Save an XML tree in an XML file
% FORMAT save(tree,filename)
%
% tree     - XMLTree
% filename - XML output filename
%_______________________________________________________________________
%
% Convert an XML tree into a well-formed XML string and write it into
% a file or display it (send it to standard output) if no filename is 
% given.
%
%-----------------------------------------------------------------------
% SUBFUNCTIONS:
%
% FORMAT print_subtree(tree,fid,order)
% Send tree entity XML formatted string to fid using 'order' blanks
% tree  - XML tree
% fid   - file identifier
% uid   - uid of the current element
% order - order of recursivity
%
% FORMAT str = entity(str)
% Tool to replace input string in internal entities
% str  - string to modify
%_______________________________________________________________________
% @(#)save.m                 Guillaume Flandin                 01/07/11

error(nargchk(1,2,nargin));

%prolog = '<?xml version="1.0" ?>\n';  %PPD
prolog = '<?xml version="1.0" encoding="UTF-8"?>';


%- Standard output
if nargin==1
	fid = 1;
%- Output specified
elseif nargin==2
	%- Filename provided
	if isstr(filename)
		[fid, msg] = fopen(filename,'w');
		if fid==-1, error(msg);end
		if isempty(tree.filename), tree.filename = filename; end
	%- File identifier provided
	elseif isnumeric(filename) & prod(size(filename)) == 1
		fid = filename;
		prolog = ''; %- In this option, do not write any prolog
	%- Rubbish provided
	else
		error('[XMLTree] Invalid argument.');
	end
end

fprintf(fid,prolog);
print_subtree(tree,fid);
fprintf(fid,'\n');

if nargin==2 & isstr(filename), fclose(fid); end

if nargout==1, varargout{1} = tree; end

%=======================================================================
function anyel = print_subtree(tree,fid,uid,order)
	if nargin <3, uid = root(tree); end
	if nargin < 4, order = 0; end
    
    anyel = 0;
	switch tree.tree{uid}.type
		case 'element'
            anyel = 1;
            fprintf(fid,'\n'); for i=1:order fprintf(fid,'\t'); end
            %fprintf(fid,blanks(6*order)); %BLANKS
			fprintf(fid,'<%s',tree.tree{uid}.name);
			for i=1:length(tree.tree{uid}.attributes)
				fprintf(fid,' %s="%s"',...
				tree.tree{uid}.attributes{i}.key,...
				tree.tree{uid}.attributes{i}.val);
            end
            if( ~isempty(tree.tree{uid}.contents) ...
                    || ~isempty( strfind( tree.tree{uid}.name,'.')) )
                fprintf(fid,'>');
                totalel = 0;
                for i=1:length(tree.tree{uid}.contents)
                    totalel = totalel + ...
                        print_subtree(tree,fid,tree.tree{uid}.contents(i),order+1);
                end
                if( totalel>0 )
                    fprintf(fid,'\n'); for i=1:order fprintf(fid,'\t'); end;
                    %fprintf(fid,blanks(6*order)); %BLANKS
                end
                fprintf(fid,'</%s>',tree.tree{uid}.name);
            else
                fprintf(fid,'/>');
            end
		case 'chardata'
			fprintf(fid,'%s',entity(tree.tree{uid}.value));
		case 'cdata'
				fprintf(fid,'<![CDATA[%s]]>',tree.tree{uid}.value);
		case 'pi'
			fprintf(fid,'<?%s %s?>',tree.tree{uid}.target,tree.tree{uid}.value);
		case 'comment'
			fprintf(fid,'<!-- %s -->',tree.tree{uid}.value);
		otherwise
			warning(sprintf('Type %s unknown : not saved',tree.tree{uid}.type));
	end
   
%=======================================================================
function str = entity(str)
	str = strrep(str,'&','&amp;');
	str = strrep(str,'<','&lt;');
	str = strrep(str,'>','&gt;');
	str = strrep(str,'"','&quot;');
	%str = strrep(str,'\','&apos;');  %PPD (premiere likes \)
