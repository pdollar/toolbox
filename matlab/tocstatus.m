% Used to display the progress of a long process.'
%
% USAGE
%                 tocstatus( id, fracdone )
%
% For more information see ticstatus.
%
% INPUTS
%   ticstatusid - unique id of progress indicator
%   fracdone    - value in (0,1] indicating percent of operation that is done
%
% OUTPUTS
%   none
%
% DATESTAMP
%   09-Apr-2007  10:00pm
%
% See also TICSTATUS

% Piotr's Image&Video Toolbox      Version 1.03
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu
% Please email me if you find bugs, or have suggestions or questions!

function tocstatus( id, fracdone )

global TICTOCSTATUS TICTOCFREEIDS

%%% error check
if( length(TICTOCSTATUS)<id || TICTOCFREEIDS(id)==1 )
  error('MATLAB:tocstatus:callTicstatusFirst', ...
    'You must call TICSTATUS before calling TOCSTATUS.');
end
[fracdone,er] = checknumericargs( fracdone, [1 1], -1, 1 ); error(er)
if( fracdone>1 ); error(['fracdone: ' num2str(fracdone) ' > 1'] ); end;

%%% get parameters
updatefreq  = TICTOCSTATUS(id).updatefreq;
updatemint  = TICTOCSTATUS(id).updatemint;
eraseprev   = TICTOCSTATUS(id).eraseprev;
msg         = TICTOCSTATUS(id).msg;
t0          = TICTOCSTATUS(id).t0;
tlast       = TICTOCSTATUS(id).tlast;
lenprev     = TICTOCSTATUS(id).lenprev;


%%% update if enough time has passed
if( etime( clock, tlast )> updatefreq || (fracdone==1 && lenprev>0) )
  tlast = clock;
  elptime = etime(clock,t0);
  fracdone = max( fracdone, .00001 );
  esttime = elptime/fracdone - elptime;
  if( lenprev || (elptime/fracdone)>updatemint )
    if( ~lenprev ); fprintf('\n'); end;

    % create display message
    fracdone_s = num2str(fracdone*100,'%.1f');
    if( elptime/fracdone < 600 )
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
    if( eraseprev ) % undo previous disp
      fprintf( repmat('\b', [1 lenprev] ) ); end;
    fprintf( msg );  % fprintf( [msg '\n'] );
    lenprev = length( msg ) - 1; %note %% (+1 if using \n)
    TICTOCSTATUS(id).tlast = tlast;
    TICTOCSTATUS(id).lenprev = lenprev;
  end;

end;

%%% free id if done
if( fracdone==1 )
  if(lenprev); fprintf('\n'); end;
  TICTOCFREEIDS(id) = 1;
end;
