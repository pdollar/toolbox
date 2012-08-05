function id = ticStatus( msg, updateFreq, updateMinT, erasePrev )
% Used to display the progress of a long process.
%
% Essentially, use 'ticId = ticStatus' to start a new progress
% indicator, and then update the progress indicator with a call to
% 'tocStatus( ticId, fracDone )', where fracDone is the fraction of
% the work completed.  The progress indicator is shown as a text message
% (sent to stdout).  For example in a loop over i where about the same
% amount of work is done each iteration, the indicator would be added as
% follows:
%     ticId = ticStatus('my message');
%     for i=1:n
%         ...
%         tocStatus( ticId, i/n );
%     end
% Before the loop the timer is initialized, and then at the end of each
% iteration a call to tocStatus is made 'tocStatus( ticId, i/n )'.
% The progress indicator is of the form:
%  'my message   completed=4.5% [elapsed=1.0s / remaining~=21.5s]'
%
% The parameters passed to ticStatus control the behavior of the progress
% indicator.  The updateFreq is the minimum time (in seconds) between
% updates to the progress indicator (a typical value is 1 second).  So even
% if 'tocStatus( ticId, i/n )' is called 100/second, an update occurs
% only once per updateFreq seconds.  Next updateMinT is used to control if
% a progress message shows at all.  If a process is projected to take time
% < updateMinT then no progress indicator is shown at all.  The form of the
% progress indicator is a text message.  If erasePrev is set to true, then
% the previously displayed message is erased.  This ONLY WORKS if no other
% output was sent to stdout since the last call to tocStatus.  Otherwise,
% each new update is simply sent to the progress indicator without first
% tyring to erase any previous text.  Finally msg allows customization of
% the actual udpate message displayed.
%
% ticStatus returns an id that uniquely identifies the progress indicator.
% tocStatus takes this id as its first input.  Once tocStatus is called
% with a fracDone==1, then the memory of the progress indicator that
% corresponds to id is set free (make sure to call tocStatus(id,1) if the
% progress indicator is no longer needed).  Nesting of progress indicators
% is possible; however, in this case erasePrev should be set to false
% (otherwise the various progress messages may erase each other).
%
% USAGE
%  id = ticStatus( [msg], [updateFreq], [updateMinT], [erasePrev] )
%
% INPUTS
%  msg         - [] additional msg to display in progress
%  updateFreq  - [1] frequency with which to update progress (in seconds)
%  updateMinT  - [20] no progress is shown if process takes time<updateMinT
%  erasePrev   - [1] whether to attempt to erase prev message
%
% OUTPUTS
%  id          - unique ticStatus for progress indicator
%
% EXAMPLE
%  ticId = ticStatus('example usage',.2,1);
%  for i=1:100; pause(.1); tocStatus( ticId, i/100 ); end
%
% See also TOCSTATUS, TIC, TOC
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2012 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see external/bsd.txt]

global TT_STATUS TT_FREE_IDS

if( nargin<1 || isempty(msg) ); msg = []; end
if( nargin<2 || isempty(updateFreq) ); updateFreq = 1; end
if( nargin<3 || isempty(updateMinT) ); updateMinT = 20; end
if( nargin<4 || isempty(erasePrev) ); erasePrev = 1; end
if( isempty(TT_FREE_IDS) ); TT_FREE_IDS = ones(1,128); end

% get a free id
[v,id] = max( TT_FREE_IDS );
if( v==0 )
  nids = length(TT_FREE_IDS);
  TT_FREE_IDS = [TT_FREE_IDS ones(1,nids)];
  id = nids+1;
  warning('ticStatus: Doubling number of locations needed.'); %#ok<WNTAG>
end
TT_FREE_IDS(id) = 0;

% initialize TT_STATUS
t0 = clock;
TT_STATUS(id).updateFreq = updateFreq;
TT_STATUS(id).updateMinT = updateMinT;
TT_STATUS(id).erasePrev  = erasePrev;
TT_STATUS(id).msg  = msg;
TT_STATUS(id).t0 = t0;
TT_STATUS(id).tLast = t0;
TT_STATUS(id).lenPrev = 0;
