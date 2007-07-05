% Used to display the progress of a long process.
%
% For more information see ticstatus.
%
% USAGE
%  tocstatus( ticId, fracDone )
%
% INPUTS
%  ticId       - unique id of progress indicator
%  fracDone    - value in (0,1] indicating percent operation completed
%
% OUTPUTS
%
% EXAMPLE
%
% See also TICSTATUS

% Piotr's Image&Video Toolbox      Version 1.03   PPD
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function tocstatus( id, fracDone )

global TICTOCSTATUS TICTOCFREEIDS

%%% error check
if( length(TICTOCSTATUS)<id || TICTOCFREEIDS(id)==1 )
  error('MATLAB:tocstatus:callTicstatusFirst', ...
    'You must call TICSTATUS before calling TOCSTATUS.');
end
[fracDone,er] = checknumericargs( fracDone, [1 1], -1, 1 ); error(er)
if( fracDone>1 ); error(['fracDone: ' num2str(fracDone) ' > 1'] ); end;

%%% get parameters
updateFreq  = TICTOCSTATUS(id).updateFreq;
updateMinT  = TICTOCSTATUS(id).updateMinT;
erasePrev   = TICTOCSTATUS(id).erasePrev;
msg         = TICTOCSTATUS(id).msg;
t0          = TICTOCSTATUS(id).t0;
tLast       = TICTOCSTATUS(id).tLast;
lenPrev     = TICTOCSTATUS(id).lenPrev;

%%% update if enough time has passed
if( etime( clock, tLast )> updateFreq || (fracDone==1 && lenPrev>0) )
  tLast = clock;
  elptime = etime(clock,t0);
  fracDone = max( fracDone, .00001 );
  esttime = elptime/fracDone - elptime;
  if( lenPrev || (elptime/fracDone)>updateMinT )
    if( ~lenPrev ); fprintf('\n'); end;

    % create display message
    fracdone_s = num2str(fracDone*100,'%.1f');
    if( elptime/fracDone < 600 )
      elptime_s  = num2str(elptime,'%.1f');
      esttime_s  = num2str(esttime,'%.1f');
      timetype_s = 's';
    else
      elptime_s  = num2str(elptime/60,'%.1f');
      esttime_s  = num2str(esttime/60,'%.1f');
      timetype_s = 'm';
    end;
    if( ~isempty(msg) ); msg = [msg '   ']; end;
    msg = [msg 'completed=' fracdone_s '%% [elapsed=' elptime_s ];
    msg = [msg timetype_s ' / remaining~=' esttime_s timetype_s ']' ];

    % erase previous display and create new display
    if( erasePrev ) % undo previous disp
      fprintf( repmat('\b', [1 lenPrev] ) ); end;
    fprintf( msg );  % fprintf( [msg '\n'] );
    lenPrev = length( msg ) - 1; %note %% (+1 if using \n)
    TICTOCSTATUS(id).tLast = tLast;
    TICTOCSTATUS(id).lenPrev = lenPrev;
  end;
end;

%%% free id if done
if( fracDone==1 )
  if(lenPrev); fprintf('\n'); end;
  TICTOCFREEIDS(id) = 1;
end;
