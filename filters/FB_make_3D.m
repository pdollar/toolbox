% Various ways to make filterbanks.  See inside of this file for details.
%
% keep adding different filterbanks, don't alter old ones!
%
% To veiw use: 
%  montages( FB );
%
% DATESTAMP
%   29-Sep-2005  2:00pm

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function FB = FB_make_3D
    flag = 1;    
    switch flag
    case 1 % pretty decent SEPERABLE STEERABLE? Filterbank
        r = 9;  
        sigmas = [.5 1.5 3]; 
        derivs = [0 0 1; 0 1 0; 1 0 0; 0 0 2; 0 2 0; 2 0 0];
        counter=1;
        for s=sigmas
            for i=1:size(derivs,1)
                dG = filter_DOOG_3D( r, [s, s, s], derivs(i,:), 0 );
                FB(:,:,:,counter) = dG; counter=counter+1;
            end        
        end
        %FB2 = mfb_DOG( r, .6, 2.8, 4);
        %FB = cat(3, FB, FB2);        
        
    otherwise
        error('none created.');
    end
    
    
    
