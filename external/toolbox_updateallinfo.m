function toolbox_updateallinfo

toolbox_insertinfo('Contents.m');
return 

    % must start in /toolbox base directory
    cd('classify/')
    mfiles = dir('*.m'); 
    for i=1:size(mfiles,1) toolbox_removeinfo(mfiles(i).name); end;
    for i=1:size(mfiles,1) toolbox_insertinfo(mfiles(i).name); end;

    cd('private/')
    mfiles = dir('*.m'); 
    for i=1:size(mfiles,1) toolbox_removeinfo(mfiles(i).name); end;
    for i=1:size(mfiles,1) toolbox_insertinfo(mfiles(i).name); end;

    cd('../../filters/')
    mfiles = dir('*.m'); 
    for i=1:size(mfiles,1) toolbox_removeinfo(mfiles(i).name); end;
    for i=1:size(mfiles,1) toolbox_insertinfo(mfiles(i).name); end;

    cd('../images/')
    mfiles = dir('*.m'); 
    for i=1:size(mfiles,1) toolbox_removeinfo(mfiles(i).name); end;
    for i=1:size(mfiles,1) toolbox_insertinfo(mfiles(i).name); end;

    cd('private/')
    mfiles = dir('*.m'); 
    for i=1:size(mfiles,1) toolbox_removeinfo(mfiles(i).name); end;
    for i=1:size(mfiles,1) toolbox_insertinfo(mfiles(i).name); end;

    cd('../../matlab/');
    mfiles = dir('*.m'); 
    for i=1:size(mfiles,1) toolbox_removeinfo(mfiles(i).name); end;
    for i=1:size(mfiles,1) toolbox_insertinfo(mfiles(i).name); end;

    cd('../');


    
% Inserts toolbox data after main comment in an .m file.
% Does not affect files with no body (such as Contents.m)
%
% EXAMPLE
%   mfiles = dir('*.m'); for i=1:size(mfiles,1) toolbox_insertinfo(mfiles(i).name); end;
function toolbox_insertinfo( fname )
    fid_in = fopen( fname, 'rt' );
    fid_out = fopen( [fname '2'] , 'wt' );

    insert_str = ...
        ['%% Piotr''s Image&Video Toolbox      Version 1.03   \n' ...
         '%% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu \n' ...
         '%% Please email me if you find bugs, or have suggestions or questions! \n \n' ];
    
    first_comment = true;
    while 1
        tline = fgetl(fid_in);
        if ~ischar(tline), break, end;
        fprintf( fid_out, '%s\n', tline );
        if( length(strtrim(tline))==0 && first_comment )
            first_comment = false;
            fprintf( fid_out, insert_str );
        end
    end
    
    fclose(fid_in);
    fclose(fid_out);
    movefile( [fname '2'], [fname] );
        

    
% Removes toolbox data after main comment in an .m file.
%
% EXAMPLE
%   mfiles = dir('*.m'); for i=1:size(mfiles,1) toolbox_removeinfo(mfiles(i).name); end;

function toolbox_removeinfo( fname )
    fid_in = fopen( fname, 'rt' );
    fid_out = fopen( [fname '2'] , 'wt' );

    nlines = 4; % number of lines to remove
    removedinfo = -1;
    while 1
        tline = fgetl(fid_in);
        if ~ischar(tline), break, end;
        if( length(strtrim(tline))==0 && removedinfo==-1 )
            fprintf( fid_out, '%s\n', tline );
            removedinfo = 0;
        elseif( removedinfo>=0 && removedinfo<nlines )
            removedinfo = removedinfo+1;
        else
            fprintf( fid_out, '%s\n', tline );
        end;
    end
    
    fclose(fid_in);
    fclose(fid_out);
    movefile( [fname '2'], [fname] );
        
    