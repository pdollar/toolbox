% Writes/reads a large set of images into/from multiple directories.
%
% This is useful since certain OS handle very large directories (of say >20K images)
% rather poorly (I'm talking to you Bill).  Thus, can take 100K images, and write into 5
% separate directories, then read them back in.
%
% INPUTS
%   I           - image or images (if [] reads else writes)
%   nSplits     - number of directories to split data into
%   spliti      - first split number
%   path        - directory where images are
%   writeparams - [varargin] additional parameters to imwrite2
%
% OUTPUTS
%   I           - image or images (read from disk if input I=[])
%
% EXAMPLE
%   load images; clear IDXi IDXv t video videos;
%   imwrite2split( images, 2, 0, 'rats', 'rats', 'png', 5 );
%   images2=imwrite2split( [], 2, 0, 'rats', 'rats', 'png', 5 );
%
% DATESTAMP
%   23-Jan-2005  2:00pm
%
% See also IMWRITE2

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function I = imwrite2split( I, nSplits, spliti, path, varargin )
    n = size(I,3); if( isempty(I) ) n=0; end;
    for s=1:nSplits
        pathSplit = [path int2str2(s-1+spliti,2)];
        if( n>0 ) % write
            nPerDir = ceil( n / nSplits );
            ISplit = I(:,:,1:min(end,nPerDir));
            imwrite2( ISplit, 1, 0, pathSplit, varargin{:} );
            if s~=nSplits I = I(:,:,(nPerDir+1):end); end;
        else % read
            ISplit = imwrite2( [], 1, 0, pathSplit, varargin{:} );
            I = cat(3,I,ISplit);
        end
    end;
        
        

