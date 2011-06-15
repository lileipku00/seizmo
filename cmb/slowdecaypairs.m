function [pf]=slowdecaypairs(results,azrng,gcrng,odir)
%SLOWDECAYPAIRS    Returns 2-station measurements of slowness & decay rate
%
%    Usage:    pf=slowdecaypairs(results,azmax,gcmin)
%              pf=slowdecaypairs(results,azrng,gcrng)
%              pf=slowdecaypairs(results,azrng,gcrng,odir)
%
%    Description:
%     PF=SLOWDECAYPAIRS(RESULTS,AZMAX,GCMIN) takes the relative arrival
%     time and amplitude measurements contained in RESULTS produced by
%     CMB_1ST_PASS, CMB_CLUSTERING, CMB_OUTLIERS, or CMB_2ND_PASS and
%     calculates the slowness and decay rate between every pair of stations
%     with an azimuth difference less than AZMAX and great-circle distance
%     difference greater than GCMIN.  The output PF is a struct with as
%     many elements as there are pairs found.  The format of the PF struct
%     is described in the Notes section below.
%
%     PF=SLOWDECAYPAIRS(RESULTS,AZRNG,GCRNG) sets profile criteria as
%     azimuthal range AZRNG and distance range GCRNG.  Both are in degrees
%     and given as [MIN MAX].  Note that AZRNG & GCRNG are relative ranges,
%     meaning an AZRNG of [0 5] will find all pairs within 5 degrees of
%     azimuth of one another.
%
%     PF=SLOWDECAYPAIRS(RESULTS,AZRNG,GCRNG,ODIR) sets the output directory
%     where the PF struct is saved.  By default ODIR is '.' (the current
%     directory.
%
%    Notes:
%     - The PF struct is also written to disk as:
%           TIMESTAMP_EARTHMODEL_2stn_profiles.mat
%       where TIMESTAMP is the time when the file is written
%       and uses format 30 from the DATESTR function.  EARTHMODEL is
%       derived from the results.earthmodel field (if you give a results
%       struct of 2+ elements with differing models then EARTHMODEL='misc'.
%     - The PF struct has the following fields:
%       .gcdist         - degree distance difference between stations
%       .azwidth        - azimuthal difference between stations
%       .slow           - horizontal slowness (s/deg)
%       .slowerr        - horizontal slowness standard error
%       .decay          - decay rate
%       .decayerr       - decay rate standard error
%       .cslow          - corrected horizontal slowness***
%       .cslowerr       - corrected horizontal slowness standard error
%       .cdecay         - corrected decay rate
%       .cdecayerr      - corrected decay rate standard error
%       .cluster        - cluster id
%       .kname          - {net stn stream cmp}
%       .st             - [lat lon elev(m) depth(m)]
%       .ev             - [lat lon elev(m) depth(m)]
%       .delaz          - [degdist az baz kmdist]
%       .corrections    - traveltime & amplitude correction values
%       .corrcoef       - max correlation coefficient between waveforms
%       .synthetics     - TRUE if synthetic data (only reflect synthetics)
%       .earthmodel     - model used to make synthetics or 'DATA'
%       .freq           - filter corners of bandpass
%       .phase          - core-diffracted wave type
%       .runname        - name of this run, used for naming output
%       .dirname        - directory containing the waveforms
%       .time           - date string of time of this struct's creation
%
%      *** Correction is different between data and synthetics.  For data
%          the .cslow value is found by subtracting out the corrections
%          (and hence attempts to go from 3D to 1D by removing the lateral
%          heterogeniety).  For synthetics the .cslow value is essentially
%          the opposite (it is corrected to 3D).  So basically:
%                     +----------+---------------+
%                     |   DATA   |   SYNTHETICS  |
%            +--------+----------+---------------+
%            |  .slow |    3D    |       1D      |
%            +--------+----------+---------------+
%            | .cslow |    1D    |       3D      |
%            +--------+----------+---------------+
%
%          To compare the data & sythetics you should compare 3D values of
%          data to 3D values of synthetics or 1D values of data to 1D
%          values of synthetics.  Drawing conclusions from comparison of 3D
%          to 1D is not recommended (except to see the affect corrections
%          have on data or synthetics).
%
%    Examples:
%     % Return station pair profiles with an azimuth
%     % of <10deg and a distance of >15deg:
%     pf=slowdecaypairs(results,[0 10],[15 inf])
%
%     % This does the same as the last example:
%     pf=slowdecaypairs(results,10,15)
%
%    See also: SLOWDECAYPROFILES, CMB_1ST_PASS, CMB_CLUSTERING,
%              CMB_OUTLIERS, CMB_2ND_PASS, PREP_CMB_DATA, PLOT_CMB_PDF,
%              MAP_CMB_PROFILES, PLOT_CMB_MEASUREMENTS

%     Version History:
%        Dec. 12, 2010 - initial version
%        Jan. 18, 2011 - update for results struct standardization, added
%                        corrections & correlation coefficients to output,
%                        time is now a string, require common event
%        Jan. 26, 2011 - pass on new .synthetics & .earthmodel fields,
%                        .cslow depends on .synthetics, added Notes
%                        about PF struct format
%        Jan. 29, 2011 - save output, fix corrections bug
%        Jan. 31, 2011 - allow no output, odir input, better checks
%        Feb.  5, 2011 - fix bug when no output specified
%        Feb. 12, 2011 - include snr-based arrival time error
%        Feb. 17, 2011 - fixed decay constant error
%        Mar.  1, 2011 - combined write rather than individually, added
%                        notes about output
%        Mar.  3, 2011 - earthmodel in output name
%        Mar. 18, 2011 - handle raypaths in correction info
%        Mar. 24, 2011 - delay write if filename will be exactly the same
%        Mar. 30, 2011 - doc update
%        Apr. 22, 2011 - update for finalcut field
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Apr. 22, 2011 at 13:35 GMT

% todo:

% check nargin
error(nargchk(3,4,nargin));

% check results struct
error(check_cmb_results(results));

% default odir
if(nargin<4 || isempty(odir)); odir='.'; end

% check azrng & gcrng
if(~isreal(azrng) || ~any(numel(azrng)==[1 2]))
    error('seizmo:slowdecaypairs:badInput',...
        'AZRNG must be [MINAZ MAXAZ] or MAXAZ!');
elseif(~isreal(gcrng) || ~any(numel(gcrng)==[1 2]))
    error('seizmo:slowdecaypairs:badInput',...
        'GCRNG must be [MINGC MAXGC] or MINGC!');
elseif(~isstring(odir))
    error('seizmo:slowdecaypairs:badInput',...
        'ODIR must be a string!');
end

% make sure odir exists (create it if it does not)
[ok,msg,msgid]=mkdir(odir);
if(~ok)
    warning(msgid,msg);
    error('seizmo:slowdecaypairs:pathBad',...
        'Cannot create directory: %s',odir);
end

% expand scalar azrng & gcrng
if(isscalar(azrng)); azrng=[0 azrng]; end
if(isscalar(gcrng)); gcrng=[gcrng inf]; end

% verbosity
verbose=seizmoverbose;

% loop over every result
for a=1:numel(results)
    % skip if results.useralign is empty
    if(isempty(results(a).useralign)); continue; end
    
    % number of records
    nrecs=numel(results(a).useralign.data);
    
    % extract header details
    [st,ev,delaz,kname]=getheader(results(a).useralign.data,...
        'st','ev','delaz','kname');
    
    % check event info matches
    ev=unique(ev,'rows');
    if(size(ev,1)>1)
        error('seizmo:slowdecaypairs:badInput',...
            'EVENT location varies between records!');
    end
    
    % corrected relative arrival times and amplitudes
    rtime=results(a).useralign.solution.arr;
    if(results(a).synthetics)
        % we add corrections here to go from 1D to 3D
        switch results(a).phase
            case 'Pdiff'
                crtime=results(a).useralign.solution.arr...
                    +results(a).corrections.ellcor...
                    +results(a).corrections.crucor.prem...
                    +results(a).corrections.mancor.hmsl06p.upswing;
            case {'SHdiff' 'SVdiff'}
                crtime=results(a).useralign.solution.arr...
                    +results(a).corrections.ellcor...
                    +results(a).corrections.crucor.prem...
                    +results(a).corrections.mancor.hmsl06s.upswing;
        end
    else % data
        % we subtract corrections here to go from 3D to 1D
        switch results(a).phase
            case 'Pdiff'
                crtime=results(a).useralign.solution.arr...
                    -results(a).corrections.ellcor...
                    -results(a).corrections.crucor.prem...
                    -results(a).corrections.mancor.hmsl06p.upswing;
            case {'SHdiff' 'SVdiff'}
                crtime=results(a).useralign.solution.arr...
                    -results(a).corrections.ellcor...
                    -results(a).corrections.crucor.prem...
                    -results(a).corrections.mancor.hmsl06s.upswing;
        end
    end
    snr=results(a).usersnr.snr;
    snr=snr(snr>=results(a).usersnr.snrcut);
    snr(results(a).userwinnow.cut)=[];
    if(isfield(results(a),'finalcut')); snr=snr(results(a).finalcut); end
    rtimeerr=sqrt((results(a).useralign.solution.arrerr).^2 ...
        +(max(1./results(a).filter.corners)...
        ./(2*pi).*snr2phaseerror(snr)).^2);
    rampl=results(a).useralign.solution.amp;
    crampl=results(a).useralign.solution.amp...
        ./results(a).corrections.geomsprcor;
    ramplerr=results(a).useralign.solution.amperr;
    
    % get cluster indexing
    cidx=results(a).usercluster.T;
    good=results(a).usercluster.good;
    
    % get outliers
    outliers=results(a).outliers.bad;
    
    % get pairs within range (need the indices)
    dgc=abs(delaz(:,ones(nrecs,1))-delaz(:,ones(nrecs,1)).')...
        .*(triu(nan(nrecs),1)+tril(ones(nrecs),-1));
    daz=abs(delaz(:,2*ones(nrecs,1))-delaz(:,2*ones(nrecs,1)).')...
        .*(triu(nan(nrecs),1)+tril(ones(nrecs),-1));
    [idx1,idx2]=find(dgc>=gcrng(1) & dgc<=gcrng(2) ...
        & daz>=azrng(1) & daz<=azrng(2));
    
    % reduce to pairs in same cluster and not outliers
    gidx=cidx(idx1)==cidx(idx2) & ~outliers(idx1) & ~outliers(idx2) ...
        & ismember(cidx(idx1),find(good));
    idx1=idx1(gidx);
    idx2=idx2(gidx);
    npairs=numel(idx1);
    
    % skip if none
    if(~npairs); continue; end
    
    % initialize struct
    if(exist('tmp','var')); clear('tmp'); end
    tmp(1:npairs,1)=struct('gcdist',[],'azwidth',[],...
        'slow',[],'slowerr',[],'decay',[],'decayerr',[],...
        'cslow',[],'cslowerr',[],'cdecay',[],'cdecayerr',[],...
        'cluster',[],'kname',[],'st',[],'ev',[],'delaz',[],...
        'corrections',[],'corrcoef',[],...
        'synthetics',results(a).synthetics,...
        'earthmodel',results(a).earthmodel,...
        'freq',results(a).filter.corners,'phase',results(a).phase,...
        'runname',results(a).runname,'dirname',results(a).dirname,...
        'time',datestr(now));
    
    % detail message
    if(verbose); print_time_left(0,npairs); end
    
    % loop over every pair, get values, fill in info
    for b=1:npairs
        % insert known info
        tmp(b).cluster=cidx(idx1(b));
        tmp(b).kname=kname([idx1(b) idx2(b)],:);
        tmp(b).st=st([idx1(b) idx2(b)],:);
        tmp(b).ev=ev;
        tmp(b).delaz=delaz([idx1(b) idx2(b)],:);
        
        % great circle distance and width
        tmp(b).gcdist=dgc(idx1(b),idx2(b));
        tmp(b).azwidth=daz(idx1(b),idx2(b));
        
        % corrections
        tmp(b).corrections=fixcorrstruct(results(a).corrections,...
            [idx1(b) idx2(b)]);
        
        % correlation coefficients
        tmp(b).corrcoef=...
            submat(ndsquareform(results(a).useralign.xc.cg),...
            1,idx1(b),2,idx2(b),3,1);
        
        % find slowness & decay rate
        [m,covm]=wlinem(delaz([idx1(b) idx2(b)],1),...
            rtime([idx1(b) idx2(b)]),1,...
            diag(rtimeerr([idx1(b) idx2(b)]).^2));
        tmp(b).slow=m(2);
        tmp(b).slowerr=sqrt(covm(2,2));
        [m,covm]=wlinem(delaz([idx1(b) idx2(b)],1),...
            crtime([idx1(b) idx2(b)]),1,...
            diag(rtimeerr([idx1(b) idx2(b)]).^2));
        tmp(b).cslow=m(2);
        tmp(b).cslowerr=sqrt(covm(2,2));
        [m,covm]=wlinem(delaz([idx1(b) idx2(b)],1),...
            log(rampl([idx1(b) idx2(b)])),1,...
            diag((log(rampl([idx1(b) idx2(b)])...
            +ramplerr([idx1(b) idx2(b)]))....
            -log(rampl([idx1(b) idx2(b)]))).^2));
        tmp(b).decay=m(2);
        tmp(b).decayerr=sqrt(covm(2,2));
        [m,covm]=wlinem(delaz([idx1(b) idx2(b)],1),...
            log(crampl([idx1(b) idx2(b)])),1,...
            diag((log(crampl([idx1(b) idx2(b)])...
            +ramplerr([idx1(b) idx2(b)]))...
            -log(crampl([idx1(b) idx2(b)]))).^2));
        tmp(b).cdecay=m(2);
        tmp(b).cdecayerr=sqrt(covm(2,2));
        
        % detail message
        if(verbose); print_time_left(b,npairs); end
    end
    
    % output
    if(~exist('pf','var'))
        pf=tmp;
    else
        pf=[pf; tmp];
    end
end

% save profiles
if(exist('pf','var'))
    name=unique({results.earthmodel}');
    if(~isscalar(name)); name='misc'; else name=char(name); end
    % avoid clobber by waiting until unique time
    if(exist(fullfile(odir,...
            [datestr(now,30) '_' name '_2stn_profiles.mat']),'file'))
        pause(1);
    end
    save(fullfile(odir,...
        [datestr(now,30) '_' name '_2stn_profiles.mat']),'pf');
end

% check for output
if(nargout && ~exist('pf','var'))
    error('seizmo:slowdecaypairs:noPairs',...
        'No station pairs meet the specified profile criteria!');
elseif(~nargout && exist('pf','var'))
    clear pf;
end

end


function [s]=fixcorrstruct(s,good)
fields=fieldnames(s);
for i=1:numel(fields)
    if(isstruct(s.(fields{i})) && isscalar(s.(fields{i})))
        s.(fields{i})=fixcorrstruct(s.(fields{i}),good);
    else
        s.(fields{i})=s.(fields{i})(good);
    end
end
end