function savefig(fname, varargin)
	
% Usage: savefig(filename, fighandle, options)
% 
% Saves a pdf, eps, png, jpeg, and/or tiff of the contents of the fighandle's (or current) figure.
% It saves an eps of the figure and the uses Ghostscript to convert to the other formats.
% The result is a cropped, clean picture. There are options for using rgb or cmyk colours, 
% or grayscale. You can also choose the resolution. 
% 
% The advantage of savefig is that there is very little empty space around the figure in the 
% resulting files, you can export to more than one format at once, and Ghostscript generates 
% trouble-free files. 
% 
% If you find any errors, please let me know! (peder at axensten dot se) 
% 
% filename: File name without suffix.
% 
% fighandle:   (default: gcf) Integer handle to figure.
% 
% options:  (default: '-r300', '-soft', '-rgb') You can define your own defaults in a global
%           variable savefig_defaults, if you want to, i.e. savefig_defaults= {'-r200','-gray'};.
% 'eps':   Output in Encapsulated Post Script (no preview yet).
% 'pdf':   Output in (Adobe) Portable Document Format.
% 'png':   Output in Portable Network Graphics.
% 'jpeg':  Output in Joint Photographic Experts Group format.
% 'tiff':  Output in Tagged Image File Format (no compression: huge files!).
% '-rgb':  Output in rgb colours.
% '-cmyk': Output in cmyk colours (not yet 'eps', 'png', and 'jpeg' -- '-rgb' is used).
% '-gray': Output in grayscale (not yet 'pdf' and 'eps' -- '-rgb' is used).
% '-r<integer>': Set resolution.
% '-soft': Enables anti-aliasing on pixel graphics (on by default).
% '-hard': No anti-aliasing on pixel graphics (saves bytes).
% '-crop': Removes points and line segments outside the viewing area -- permanently.
%          Only use this on figures where many points and/or line segments are outside 
%          the area zoomed in to. This option will result in smaller vector files (has no
%          effect on pixel files).
% '-dbg':  Displays gs command line(s).
% 
% EXAMPLE:
% savefig('nicefig', 'pdf', 'jpeg', '-cmyk', '-r250');
% Saves the current figure to nicefig.pdf and nicefig.png, both in cmyk and at 250 dpi.
% 
% REQUIREMENT: Ghostscript. Version 8.51 works, probably older versions too, but '-dEPSCrop' must 
%           be supported. I think version 7.32 or newer is ok. 
% 
% HISTORY:
% Version 1.0, 2006-04-20.
% Version 1.1, 2006-04-27:
% - No 'epstopdf' stuff anymore! Using '-dEPSCrop' option in gs instead!
% Version 1.2, 2006-05-02:
% - Added a '-dbg' option (see options, above).
% - Now looks for a global variable 'savefig_defaults' (see options, above).
% - More detailed Ghostscript options (user will not really notice).
% - Warns when there is no device for a file-type/color-model combination.
% Version 1.3, 2006-06-06:
% - Added a check to see if there actually is a figure handle. 
% - Now works in Matlab 6.5.1 (R13SP1) (maybe in 6.5 too).
% - Now compatible with Ghostscript 8.54, released 2006-06-01.
% Version 1.4, 2006-07-20:
% - Added an option '-soft' that enables anti-aliasing on pixel graphics (on by default).
% - Added an option '-hard' that don't do anti-aliasing on pixel graphics.
% Version 1.5, 2006-07-27:
% - Fixed a bug when calling with a figure handle argument. 
% Version 1.6, 2006-07-28:
% - Added a crop option, see above. 
% Version 1.7, 2007-03-31:
% - Fixed bug: calling print with invalid renderer value '-none'. 
% - Removed GhostScript argument '-dUseCIEColor' as it sometimes discoloured things.
% 
% TO DO: (Need Ghostscript support for these, so don't expect anything soon...)
% - svg output.
% - '-cmyk' also for 'eps', 'jpeg', and 'png'.
% - '-gray' also for 'pdf' and 'eps'.
% - Preview in 'eps'.
% - Embedded vector fonts, not bitmap, in 'eps'.
% - Process all out files in one call to Ghostscript.
% 
% Copyright (C) Peder Axensten (peder at axensten dot se), 2006.

% KEYWORDS:     eps, pdf, jpg, jpeg, png, tiff, eps2pdf, epstopdf, ghostscript
% 
% INSPIRATION:  eps2pdf (5782), eps2xxx (6858)
% 
% REQUIREMENTS: Works in Matlab 6.5.1 (R13SP1) (maybe in 6.5 too).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	op_dbg=     false;													% Default value.
	
	% Create gs command.
	switch(computer)													% Get gs command.
		case 'MAC',		gs= '/usr/local/bin/gs';
		case 'PCWIN',	gs= 'gswin32c.exe';
		otherwise,		gs= 'gs';
	end
	gs=		[gs		' -q -dNOPAUSE -dBATCH -dEPSCrop'];					% Essential.

	gs=		[gs		' -dDOINTERPOLATE -dUseFlateCompression=true'];		% Useful stuff.
	gs=		[gs		' -dAutoRotatePages=/None'];						% Probably good.
	gs=		[gs		' -dHaveTrueTypes'];								% More probably good.
	cmdEnd=			' -sDEVICE=%s -sOutputFile="%s" ';					% Essential.
	epsCmd=			'';
	epsCmd=	[epsCmd ' -dSubsetFonts=true -dEmbedAllFonts=false -dNOPLATFONTS'];% Future support?
	epsCmd=	[epsCmd ' -dColorConversionStrategy=/UseDeviceIndependentColor' ...
					' -dProcessColorModel=/%s'];						% Supported by gs in future?
	pdfCmd=	[epsCmd cmdEnd ' -c .setpdfwrite'];							% Recommended by gs.
	epsCmd=	[epsCmd cmdEnd];
	
	gsAntiAlias=	' -dGraphicsAlphaBits=4 -dTextAlphaBits=4';			% Anti alias options
	
	% Get file name.
	if((nargin < 1) || isempty(fname) || ~ischar(fname))				% Check file name.
		error('No file name specified.');
	end
	[pathstr, namestr] = fileparts(fname);
	if(isempty(pathstr)), fname= fullfile(cd, namestr);	end
	
	% Get handle.
	fighandle=		get(0, 'CurrentFigure'); % See gcf.					% Get figure handle.
	if((nargin >= 2) && (numel(varargin{1}) == 1) && isnumeric(varargin{1}))
		fighandle=		varargin{1};
		varargin=		{varargin{2:end}};
	end
	if(isempty(fighandle)), error('There is no figure to save!?');		end
	
	% Set up the various devices.
	% Those commented out are not yet supported by gs (nor by savefig).
	% pdf-cmyk works due to the Matlab '-cmyk' export being carried over from eps to pdf.
	device.eps.rgb=		sprintf(epsCmd, 'DeviceRGB',	'epswrite', [fname '.eps']);
%	device.eps.cmyk=	sprintf(epsCmd, 'DeviceCMYK',	'epswrite', [fname '.eps']);
%	device.eps.gray=	sprintf(epsCmd, 'DeviceGray',	'epswrite', [fname '.eps']);
	device.jpeg.rgb=	sprintf(cmdEnd,	'jpeg', 					[fname '.jpeg']);
%	device.jpeg.cmyk=	sprintf(cmdEnd,	'jpegcmyk', 				[fname '.jpeg']);
	device.jpeg.gray=	sprintf(cmdEnd,	'jpeggray',					[fname '.jpeg']);
	device.pdf.rgb=		sprintf(pdfCmd, 'DeviceRGB',	'pdfwrite', [fname '.pdf']);
	device.pdf.cmyk=	sprintf(pdfCmd, 'DeviceCMYK',	'pdfwrite', [fname '.pdf']);
%	device.pdf.gray=	sprintf(pdfCmd, 'DeviceGray',	'pdfwrite', [fname '.pdf']);
	device.png.rgb=		sprintf(cmdEnd,	'png16m', 					[fname '.png']);
%	device.png.cmyk=	sprintf(cmdEnd,	'png???', 					[fname '.png']);
	device.png.gray=	sprintf(cmdEnd,	'pnggray', 					[fname '.png']);
	device.tiff.rgb=	sprintf(cmdEnd,	'tiff24nc',					[fname '.tiff']);
	device.tiff.cmyk=	sprintf(cmdEnd,	'tiff32nc', 				[fname '.tiff']);
	device.tiff.gray=	sprintf(cmdEnd,	'tiffgray', 				[fname '.tiff']);
	
	% Get options.
	global savefig_defaults;											% Add global defaults.
 	if( iscellstr(savefig_defaults)), varargin=	{savefig_defaults{:}, varargin{:}};
	elseif(ischar(savefig_defaults)), varargin=	{savefig_defaults, varargin{:}};
	end
	varargin=	{'-rgb', '-r300', varargin{:}};							% Add defaults.
	res=		'';
	types=		{};
	crop=		false;
	antialias=	gsAntiAlias;
	for n= 1:length(varargin)											% Read options.
		if(ischar(varargin{n}))
			if(ismember(lower(varargin{n}), {'eps','jpeg','pdf','png','tiff'}))
				types{end+1}=	lower(varargin{n});
			elseif(strcmpi(varargin{n}, '-rgb')),	color=	'rgb';	deps= {'-depsc2'};
			elseif(strcmpi(varargin{n}, '-cmyk')),	color=	'cmyk';	deps= {'-depsc2', '-cmyk'};
			elseif(strcmpi(varargin{n}, '-gray')),	color=	'gray';	deps= {'-deps2'};
			elseif(strcmpi(varargin{n}, '-soft')),	antialias= gsAntiAlias;
			elseif(strcmpi(varargin{n}, '-hard')),	antialias= '';
			elseif(strcmpi(varargin{n}, '-crop')),	crop=	true;
			elseif(strcmpi(varargin{n}, '-dbg')),	op_dbg=			true;
			elseif(regexp (varargin{n}, '^\-r[0-9]+$')), res=		varargin{n};
			else	warning('Unknown option in argument: ''%s''.', varargin{n});
			end
		else
			warning('Wrong type of argument: ''%s''.', class(varargin{n}));
		end
	end
	types=		unique(types);
	if(isempty(types)), error('No output format given.');	end
	gs=			[gs ' ' res];											% Add resolution to cmd.
	
	if(crop && ismember(types, {'eps', 'pdf'}))							% Crop the figure. 
		fighandle= do_crop(fighandle);
	end
	
	% Output eps from Matlab.
	renderer=	['-' lower(get(gcf, 'Renderer'))];						% Use same as in figure.
	if(strcmpi(renderer, '-none')), renderer=	'-painters';	end		% We need a valid renderer.
	print(fighandle, deps{:}, '-noui', renderer, res, [fname '-temp']);	% Output the eps.
	
	% Convert to other formats.
	for n= 1:length(types)												% Output them.
		if(isfield(device.(types{n}), color))
			cmd=		device.(types{n}).(color);						% Colour model exists.
		else
			cmd=		device.(types{n}).rgb;							% Use alternative.
			warning('No device for %s with colours %s. Using rgb instead.', types{n}, color);
		end
		if(isempty(findstr(types{n}, '.eps')) && isempty(findstr(types{n}, '.pdf')))
			cmd=		[cmd antialias];	% Anti aliasing only on pixel graphics. 
		end
		cmd=	sprintf('%s %s -f "%s-temp.eps"', gs, cmd, fname);		% Add source file.
		system(cmd);	% [status, result]= system(cmd2);				% Run Ghostscript.
		if(op_dbg), disp(cmd);		end
	end
	delete([fname '-temp.eps']);										% Clean up.
end


function fig= do_crop(fig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%	Remove line segments that are outside the view.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	haxes=	findobj(fig, 'Type', 'axes', '-and', 'Tag', '');
	for n=1:length(haxes)
		xl=		get(haxes(n), 'XLim');
		yl=		get(haxes(n), 'YLim');
		lines=	findobj(haxes(n), 'Type', 'line');
		for m=1:length(lines)
			x=				get(lines(m), 'XData');
			y=				get(lines(m), 'YData');
			
			inx=			(xl(1) <= x) & (x <= xl(2));	% Within the x borders.
			iny=			(yl(1) <= y) & (y <= yl(2));	% Within the y borders. 
			keep=			inx & iny;						% Within the box.
			
			if(~strcmp(get(lines(m), 'LineStyle'), 'none'))
				crossx=		((x(1:end-1) < xl(1)) & (xl(1) < x(2:end))) ...	% Crossing border x1.
						|	((x(1:end-1) < xl(2)) & (xl(2) < x(2:end))) ...	% Crossing border x2.
						|	((x(1:end-1) > xl(1)) & (xl(1) > x(2:end))) ...	% Crossing border x1.
						|	((x(1:end-1) > xl(2)) & (xl(2) > x(2:end)));	% Crossing border x2.
				crossy=		((y(1:end-1) < yl(1)) & (yl(1) < y(2:end))) ...	% Crossing border y1.
						|	((y(1:end-1) < yl(2)) & (yl(2) < y(2:end))) ...	% Crossing border y2.
						|	((y(1:end-1) > yl(1)) & (yl(1) > y(2:end))) ...	% Crossing border y1.
						|	((y(1:end-1) > yl(2)) & (yl(2) > y(2:end)));	% Crossing border y2.
				crossp=	[(	(crossx & iny(1:end-1) & iny(2:end)) ...	% Crossing a x border within y limits.
						|	(crossy & inx(1:end-1) & inx(2:end)) ...	% Crossing a y border within x limits.
						|	crossx & crossy ...							% Crossing a x and a y border (corner). 
						 ),	false ...
						];
				crossp(2:end)=	crossp(2:end) | crossp(1:end-1);		% Add line segment's secont end point. 
			
				keep=			keep | crossp;
			end
			set(lines(m), 'XData', x(keep))
			set(lines(m), 'YData', y(keep))
		end
	end
end
