% Used to display the progress of a long process.
% 
% Essentially, use 'ticstatusid = ticstatus' to start a new progress indicator, and then
% update the progress indicator with a call to 'tocstatus( ticstatusid, fracdone )', where
% fracdone is the fraction of the work completed.  The progress indicator is shown as a
% text message (sent to stdout).  For example in a loop over i where about the same amount
% of work is done each iteration, the indicator would be added as follows:
%     ticstatusid = ticstatus('my message');
%     for i=1:n
%         ...
%         tocstatus( ticstatusid, i/n );
%     end
% Before the loop the timer is initialized, and then at the end of each iteration a call
% to tocstatus is made 'tocstatus( ticstatusid, i/n )'.  The progress indicator is of the
% form:   'my message   completed=4.5% [elapsed=1.0s / remaining~=21.5s]'
%
% The parameters passed to ticstatus control the behavior of the progress indicator.  The
% updatefreq is the minimum time (in seconds) between updates to the progress indicator
% (a typical value is 1 second).  So even if 'tocstatus( ticstatusid, i/n )' is called
% 100/second, an update occurs only once per updatefreq seconds.  Next updatemint is used
% to control if a progress message shows at all.  If a process is projected to take time <
% updatemint then no progress indicator is shown at all.  The form of the progress
% indicator is a text message.  If eraseprev is set to true, then the previously displayed
% message is erased.  This ONLY WORKS if no other output was sent to stdout since the last
% call to tocstatus.  Otherwise, each new update is simply sent to the progress indicator
% without first tyring to erase any previous text.  Finally msg allows customization of
% the actual udpate message displayed.
%
% ticstatus returns an id that uniquely identifies the progress indicator.  tocstatus
% takes this id as its first input.  Once tocstatus is called with a fracdone==1, then the
% memory of the progress indicator that corresponds to id is set free (make sure to call
% tocstatus(id,1) if the progress indicator is no longer needed).  Nesting of progress
% indicators is possible; however, in this case eraseprev should be set to false (otherwise
% the various progress messages may erase each other).
% 
% INPUTS
%   msg         - [optinoal] additional msg to display in progress
%   updatefreq  - [optional] frequency with which to update progress (in seconds)
%   updatemint  - [optional] no progress is shown if process takes time < updatemint
%   eraseprev   - [optional] whether to attempt to erase prev message
%
% OUTPUTS
%   ticstatusid - unique id of progress indicator
%
% DATESTAMP
%   29-Sep-2005  2:00pm
%
% See also TOCSTATUS

% Piotr's Image&Video Toolbox      Version 1.03   
% Written and maintained by Piotr Dollar    pdollar-at-cs.ucsd.edu 
% Please email me if you find bugs, or have suggestions or questions! 
 
function id = ticstatus( msg, updatefreq, updatemint, eraseprev )
    global TICTOCSTATUS TICTOCFREEIDS
    
    if( nargin<1 || isempty(msg) ) msg = []; end;
    if( nargin<2 || isempty(updatefreq) ) updatefreq = 1; end;
    if( nargin<3 || isempty(updatemint) ) updatemint = 20; end;
    if( nargin<4 || isempty(eraseprev) ) eraseprev = 1; end;
    if( isempty(TICTOCFREEIDS) ) TICTOCFREEIDS = ones(1,128); end;
    
    % get a free id
    [v,id] = max( TICTOCFREEIDS ); 
    if( v==0 ) 
        nids = length(TICTOCFREEIDS); 
        TICTOCFREEIDS = [TICTOCFREEIDS ones(1,nids)]; 
        id = nids+1; 
        warning('ticstatus: Doubling number of locations needed.');
    end;
    TICTOCFREEIDS(id) = 0;
    
    % initialize TICTOCSTATUS
    t0 = clock;
    TICTOCSTATUS(id).updatefreq = updatefreq;
    TICTOCSTATUS(id).updatemint = updatemint;
    TICTOCSTATUS(id).eraseprev  = eraseprev;
    TICTOCSTATUS(id).msg  = msg;
    TICTOCSTATUS(id).t0 = t0;
    TICTOCSTATUS(id).tlast = t0; 
    TICTOCSTATUS(id).lenprev = 0;
