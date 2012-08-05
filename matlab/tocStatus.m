function tocStatus( id, fracDone )
% Used to display the progress of a long process.
%
% For more information see ticStatus.
%
% USAGE
%  tocStatus( id, fracDone )
%
% INPUTS
%  id          - unique id of progress indicator
%  fracDone    - value in (0,1] indicating percent operation completed
%
% OUTPUTS
%
% EXAMPLE
%
% See also TICSTATUS
%
% Piotr's Image&Video Toolbox      Version 2.50
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

global TT_STATUS TT_FREE_IDS

%%% error check
if( length(TT_STATUS)<id || TT_FREE_IDS(id)==1 )
  error('MATLAB:tocStatus:callTicstatusFirst', ...
    'You must call TICSTATUS before calling TOCSTATUS.');
end
[fracDone,er] = checkNumArgs( fracDone, [1 1], -1, 1 );
if(~isempty(er)), error(er); end
if( fracDone>1 ); error(['fracDone: ' num2str(fracDone) ' > 1'] ); end;

%%% get parameters
updateFreq  = TT_STATUS(id).updateFreq;
updateMinT  = TT_STATUS(id).updateMinT;
erasePrev   = TT_STATUS(id).erasePrev;
msg         = TT_STATUS(id).msg;
t0          = TT_STATUS(id).t0;
tLast       = TT_STATUS(id).tLast;
lenPrev     = TT_STATUS(id).lenPrev;

%%% update if enough time has passed
if( etime( clock, tLast )> updateFreq || (fracDone==1 && lenPrev>0) )
  tLast = clock;
  elptime = etime(clock,t0);
  fracDone = max( fracDone, .00001 );
  esttime = elptime/fracDone - elptime;
  if( lenPrev || (elptime/fracDone)>updateMinT )
    if( ~lenPrev ); fprintf('\n'); end

    % create display message
    fracdoneS = num2str(fracDone*100,'%.1f');
    if( elptime/fracDone < 600 )
      elptimeS  = num2str(elptime,'%.1f');
      esttimeS  = num2str(esttime,'%.1f');
      timetypeS = 's';
    else
      elptimeS  = num2str(elptime/60,'%.1f');
      esttimeS  = num2str(esttime/60,'%.1f');
      timetypeS = 'm';
    end
    if( ~isempty(msg) ); msg = [msg '   ']; end
    msg = [msg 'completed=' fracdoneS '%% [elapsed=' elptimeS ];
    msg = [msg timetypeS ' / remaining~=' esttimeS timetypeS ']' ];

    % erase previous display and create new display
    if( erasePrev ) % undo previous disp
      fprintf( repmat('\b', [1 lenPrev] ) ); end
    fprintf( msg );  % fprintf( [msg '\n'] );
    lenPrev = length( msg ) - 1; %note %% (+1 if using \n)
    TT_STATUS(id).tLast = tLast;
    TT_STATUS(id).lenPrev = lenPrev;
  end
end

%%% free id if done
if( fracDone==1 )
  if(lenPrev); fprintf('\n'); end
  TT_FREE_IDS(id) = 1;
end
