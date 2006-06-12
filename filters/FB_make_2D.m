% Various ways to make filterbanks.  See inside of this file for details.
%
% keep adding different filterbanks, don't alter old ones!
%
% DATESTAMP
%   29-Sep-2005  2:00pm

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function FB = FB_make_2D
    flag = 5;    

    switch flag
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
    case 1  %filter bank from serge belongie:
        r=15; 
        FB = mfb_gabor( r, 6, 3, 3, sqrt(2) );
        FB2 = mfb_DOG( r, .6, 2.8, 4);
        FB = cat(3, FB, FB2);
        %FB = FB(:,:,1:2:36); %include only even symmetric filters
        %FB = FB(:,:,2:2:36); %include only odd symmetric filters
        
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 2 % derivative of offset Gaussian filterbank
        FB = mfb_DOOG( 15, 6, 3, 5, .5) ;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 3
        % wierd filterbank of Gaussian derivatives at various scales
        % this is supposed to kind of immitate Laptev&Lindberg ICPR04
        % should see little difference in using higher order then 2nd
        r = 9;  sigmas = [.5 1 1.5 3]; % sigmas = [1,1.5,2];% 
        
        derivs = [];
        %derivs = [ derivs; 0 0 ]; % 0th order
        %derivs = [ derivs; 0 1; 1 0 ]; % first order
        %derivs = [ derivs; 0 2; 2 0; 1 1 ]; % 2nd order
        %derivs = [ derivs; 0 3; 3 0; 2 1; 1 2 ]; % 3rd order
        %derivs = [ derivs; 0 4; 4 0; 3 1; 1 3; 2 2 ]; % 4th order        
        derivs = [ derivs; 1 0; 2 0; 3 0; 4 0; 5 0 ]; % n0 order
        derivs = [ derivs; fliplr([ 1 0; 2 0; 3 0; 4 0; 5 0 ])]; % 0n order        
        counter=1;
        for s=sigmas
            for i=1:size(derivs,1)
                dG = filter_DOOG_2D( r, s, s, derivs(i,:), 0 );
                FB(:,:,counter) = dG; counter=counter+1;
                %dG = filter_DOOG_2D( r, s*3, s, derivs(i,:), 0 );
                %FB(:,:,counter) = dG; counter=counter+1;
                %dG = filter_DOOG_2D( r, s, s*3, derivs(i,:), 0 );
                %FB(:,:,counter) = dG; counter=counter+1;
            end        
        end

        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 4 % pretty decent SEPERABLE STEERABLE? Filterbank
        r = 9;  
        sigmas = [.5 1.5 3]; 
        derivs = [0 1; 1 0; 0 2; 2 0];
        counter=1;
        for s=sigmas
            for i=1:size(derivs,1)
                dG = filter_DOOG_2D( r, s, s, derivs(i,:), 0 );
                FB(:,:,counter) = dG; counter=counter+1;
            end        
        end
        FB2 = mfb_DOG( r, .6, 2.8, 4);
        FB = cat(3, FB, FB2);        
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 5  % berkeley fb for textons papers
        %FB = mfb_gabor( 6, 6, 1, 2, sqrt(2) ); 
        %FB = mfb_gabor( 4, 6, 1, 1.6, sqrt(2) ); %using for image dist
        FB = mfb_gabor( 7, 6, 1, 2, 2 ); 
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 6   % symmetric DOOG filters
        FB = mfb_DOOG_symmetric( 4, 2, [.5 1] );
        
    otherwise
        error('none created.');
    end
    
    
    
    
    
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
% multi-scale even and odd filters.  These are basically gabor filters
% at a whole bunch of orientations.  Adapted from code by Serge
% Belongie.
function FB = mfb_gabor( r, num_ori, num_scales, lambda, sigma )     
    counter=1;  
    for m=1:num_scales
        for n=1:num_ori
            [F1,F2]=filter_gabor_2D(r,sigma^m,lambda,180*(n-1)/num_ori);
            FB(:,:,counter)=F1;  counter=counter+1;
            FB(:,:,counter)=F2;  counter=counter+1;
        end
    end

% adds a series of symmetric DooG filters.  These are different from 
% gabor filters. 
function FB = mfb_DOOG_symmetric( r, num_ori, sigmas )  
    counter=1;
    for sigma=sigmas
        Fodd  = -filter_DOOG_2D( r, sigma, sigma, [0,1], 0 );    
        Feven = filter_DOOG_2D( r, sigma, sigma, [0,2], 0 );    
        for n=1:num_ori
            theta = 180*(n-1)/num_ori;
            FB(:,:,counter) = imrotate( Feven, theta, 'bil', 'crop' );  counter=counter+1;
            FB(:,:,counter) = imrotate( Fodd,  theta, 'bil', 'crop' );  counter=counter+1;
        end
    end    
    
    
% adds a series of DooG filters.  These are almost identical to the
% gabor filters, so don't include both!   
% Defaults: num_ori=6, num_scales=3, lambda=5, sigma=.5,
function FB = mfb_DOOG( r, num_ori, num_scales, lambda, sigma )  
    counter=1;  
    for m=1:num_scales
        sigma = sigma * m^.7;
        Fodd  = -filter_DOOG_2D( r, lambda*sigma^.6, sigma, [0,1], 0 );    
        Feven = filter_DOOG_2D( r, lambda*sigma^.6, sigma, [0,2], 0 );    
        for n=1:num_ori
            theta = 180*(n-1)/num_ori;
            FB(:,:,counter) = imrotate( Feven, theta, 'bil', 'crop' );  counter=counter+1;
            FB(:,:,counter) = imrotate( Fodd,  theta, 'bil', 'crop' );  counter=counter+1;
        end
    end
    
% adds a serires of difference of Gaussian filters.
function FB = mfb_DOG( r, sigma_st, sigma_end, n )   
    sigmas = sigma_st:(sigma_end-sigma_st)/(n-1):sigma_end;
    FB=[];
    for s=sigmas
        FB = cat(3,FB,filter_DOG_2D(r,s,2));
    end;
