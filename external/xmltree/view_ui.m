function varargout = view_ui(action,figHandle)
% Used by XMLTREE/VIEW
% FORMAT varargout = view_ui(action)
% 
% action - string
%_______________________________________________________________________
%
% Callback manager of xmltree-method view
%_______________________________________________________________________
% @(#)view_ui.m                Guillaume Flandin               02/04/08

if nargin < 2
	figHandle = gcbf;
end

switch action
	%- BATCHLIST -%
	case 'batchlist'
		seltype=get(gcbf,'SelectionType');
		tree = get(gcbf,'UserData');
		BatchListboxH = findobj(gcbf,'Tag','BatchListbox');
		uidList = get(BatchListboxH,'UserData');
		% Single mouse click
		if strcmp(seltype,'normal')
			ModifyButtonH = findobj(gcbf,'Tag', 'Modify');
			AboutListboxH = findobj(gcbf,'Tag', 'AboutListbox');
			uid = uidList(get(BatchListboxH,'value'));
			contents = children(tree,uid);
			if length(contents) > 0 & ...
				strcmp(get(tree,contents(1),'type'),'chardata')
				str = get(tree,contents(1),'value');
				set(findobj(gcbf,'Tag','Add'),'Enable','off');
			elseif length(contents) == 0
			% 18/02/02 : definition : une balise vide contient un chardata vide: pas d'accord !!!
				str = '';
				tree = add(tree,uid,'chardata',str);
				builtin('set',gcf,'UserData',tree);
				set(findobj(gcbf,'Tag','Add'),'Enable','off');
			else
				str = ['Tag ' get(tree,uid,'name')]; 
				set(findobj(gcbf,'Tag','Add'),'Enable','on');
			end
			if get(BatchListboxH,'value') == 1
				set(findobj(gcbf,'Tag','Copy'),'Enable','off');
				set(findobj(gcbf,'Tag','Delete'),'Enable','off');
			else
				set(findobj(gcbf,'Tag','Copy'),'Enable','on');
				set(findobj(gcbf,'Tag','Delete'),'Enable','on');
			end
			%- Trying to keep the slider active
			set(AboutListboxH,'Enable','on');
			set(AboutListboxH,'String',' ');
			set(AboutListboxH,'Enable','Inactive');
			set(AboutListboxH,'String',str);
		% Double mouse click
		else
			tree = sub_flip(tree,uidList(get(BatchListboxH,'value')));
			[batchString uidList] = sub_update(tree);
			set(BatchListboxH,'String',batchString);
			set(BatchListboxH,'UserData',uidList);
			builtin('set',gcbf,'UserData',tree);
		end
		
	%- UPDATE -%
	case 'update'
		% update is not always called from a callback
		BatchListboxH = findobj(gcbf,'Tag','BatchListbox');
		if isempty(BatchListboxH)
			BatchListboxH = findobj(gcf,'Tag','BatchListbox');
		end
		tree = get(figHandle,'UserData');
		if isempty(tree)
			tree = get(gcf,'UserData');
		end
		[batchString uidList] = sub_update(tree);
		set(BatchListboxH,'String',batchString);
		set(BatchListboxH,'UserData',uidList);
		
	%- ADD -%
	case 'add'
		tree = get(gcbf,'UserData');
		BatchListboxH = findobj(gcbf,'Tag','BatchListbox');
		uidList = get(BatchListboxH,'UserData');
		AboutListboxH = findobj(gcbf,'Tag', 'AboutListbox');
		uid = uidList(get(BatchListboxH,'value'));
		answer = questdlg('Which kind of element to add ?','Add an item','Node','Leaf','Node');
		switch answer
			case 'Node'
				tree = add(tree,uid,'element','New');
			case 'Leaf'
				tree = add(tree,uid,'element','New');
				l = length(tree);
				tree = add(tree,l,'chardata','Default');
			otherwise
				warning('Bug !');
		end
		tree = set(tree,uid,'show',1);
		builtin('set',gcf,'UserData',tree);
		set(findobj(gcbf,'Tag', 'Save'),'UserData',1);
		view_ui update;
		view_ui batchlist;
		
	%- MODIFY -%
	case 'modify'
		tree = get(gcbf,'UserData');
		BatchListboxH = findobj(gcbf,'Tag','BatchListbox');
		uidList = get(BatchListboxH,'UserData');
		AboutListboxH = findobj(gcbf,'Tag', 'AboutListbox');
		uid = uidList(get(BatchListboxH,'value'));
		contents = children(tree,uid);
		if length(contents) > 0 & ...
			strcmp(get(tree,contents(1),'type'),'chardata')
			str = get(tree,contents(1),'value');
			prompt = {'Name :','New value:'};
			def = {get(tree,uid,'name'),str};
			title = sprintf('Modify %s',get(tree,uid,'name'));
			lineNo = 1;
			answer = inputdlg(prompt,title,lineNo,def);
			if ~isempty(answer)
				tree = set(tree,uid,'name',answer{1});
				str = answer{2};
				tree = set(tree,contents(1),'value',str);
				set(findobj(gcbf,'Tag', 'Save'),'UserData',1);
				builtin('set',gcf,'UserData',tree);
			end
		else
			str = ['Tag ' get(tree,uid,'name')];
			prompt = {'Name :'};
			def = {get(tree,uid,'name'),str};
			title = sprintf('Modify %s tag',get(tree,uid,'name'));
			lineNo = 1;
			answer = inputdlg(prompt,title,lineNo,def);
			if ~isempty(answer)
				tree = set(tree,uid,'name',answer{1});
				str = ['Tag ' get(tree,uid,'name')];
				set(findobj(gcbf,'Tag', 'Save'),'UserData',1);
				builtin('set',gcf,'UserData',tree);
			end
		end
		%- Trying to keep the slider active
		set(AboutListboxH,'Enable','on');
		set(AboutListboxH,'String',' ');
		set(AboutListboxH,'Enable','Inactive');
		set(AboutListboxH,'String',str);
		view_ui update;
		view_ui batchlist;
	
	%- COPY -%
	case 'copy'
		tree = get(gcbf,'UserData');
		BatchListboxH = findobj(gcbf,'Tag','BatchListbox');
		uidList = get(BatchListboxH,'UserData');
		AboutListboxH = findobj(gcbf,'Tag', 'AboutListbox');
		pos = get(BatchListboxH,'value');
		if pos ~= 1
			uid = uidList(pos);
			tree = copy(tree,uid);
			builtin('set',gcf,'UserData',tree);
			set(findobj(gcbf,'Tag', 'Save'),'UserData',1);
			view_ui update;
			view_ui batchlist;
		end
		
	%- DELETE -%
	case 'delete'
		tree = get(gcbf,'UserData');
		BatchListboxH = findobj(gcbf,'Tag','BatchListbox');
		uidList = get(BatchListboxH,'UserData');
		AboutListboxH = findobj(gcbf,'Tag', 'AboutListbox');
		uid = uidList(get(BatchListboxH,'value'));
		pos = get(BatchListboxH,'value');
		if pos > 1
			tree = delete(tree,uid);
			set(BatchListboxH,'value',pos-1);
			set(findobj(gcbf,'Tag', 'Save'),'UserData',1);
		end
		builtin('set',gcf,'UserData',tree);
		view_ui update;
		view_ui batchlist;

	%- SAVE -%
	case 'save'
		tree = get(gcbf,'UserData');
		[filename pathname] = uiputfile('*.xml','Save Batch as');
		if ~(isequal(filename,0)|isequal(pathname,0))
			save(tree,fullfile(pathname,filename));
			set(findobj(gcbf,'Tag','Save'),'UserData',0);
		end
		
	%- RUN -%
	case 'run'
		warndlg('Not implemented','XMLtree :: Run');
		
	%- CLOSE -%
	case 'close'
		SaveButtonH = findobj(gcbf,'Tag','Save');
		if get(SaveButtonH,'UserData')
			answer = questdlg('Save changes ?', ...
				'Quit XML Tree');
			switch(answer)
				case 'Yes'
					view_ui save;
					delete(gcbf);
				case 'No'
					delete(gcbf);
				case 'Cancel'
				otherwise,
         	end
		else
			delete(gcbf);
		end
		
	%- OTHERWISE -%
	otherwise
		error('[XMLTree] Unknown action.');
end

%=======================================================================
function [batchString, uidList] = sub_update(tree,uid,o)
	if nargin < 2
		uid = root(tree);
	end
	if nargin < 3 | o == 0
		o = 0;
		sep=' ';
	else
		sep = blanks(4*o);
	end
	batchString = {[sep get(tree,uid,'name')]};
	uidList = [get(tree,uid,'uid')];
	haselementchild = 0;
	contents = get(tree,uid,'contents');
	if isfield(tree,uid,'show') & get(tree,uid,'show')==1
		for i=1:length(contents)
			if strcmp(get(tree,contents(i),'type'),'element')
				[subbatchString subuidList] = sub_update(tree,contents(i),o+1);
				batchString = {batchString{:} subbatchString{:}};
				uidList = [uidList subuidList];
				haselementchild = 1;
			end
		end
		if haselementchild==1, batchString{1}(length(sep)) = '-'; end
	else
		for i=1:length(contents)
			if strcmp(get(tree,contents(i),'type'),'element')
				haselementchild = 1;
			end
		end
		if haselementchild==1, batchString{1}(length(sep)) = '+'; end
	end
   
%=======================================================================
function tree = sub_flip(tree,uid)
	if isfield(tree,uid,'show')
		show = get(tree,uid,'show');
	else
		show = 0;
	end
	tree = set(tree,uid,'show',~show);
