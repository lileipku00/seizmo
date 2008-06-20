function [data]=bseis(varargin)
%BSEIS   Arranges xy data into a SAClab data structure
%
%    Description: BSEIS(X1,Y1,X2,Y2,...) takes vectors of x-values and 
%     y-values and arranges them into a SAClab data structure (one record 
%     per x/y pair) to be compatible with SAClab functions.  The name field
%     is left blank so before writing any data generated using this
%     function, fill in the name field (see example below).
%
%    Notes:
%     - outputs records as equivalent to SAC version 6
%     - the byte-order is set to match the current architecture
%     - the filetype is set as 'General X vs Y file'
%     - automatically figures out if data is evenly sampled
%     - does not support multiple components (x vs [y1 y2 y3 ...])
%
%    Requirements: Matlab 7
%
%    Supported types: ALL
%
%    Usage:    SAClab_struct=bseis(x_vec1,y_vec1,x_vec2,y_vec2...)
%
%    Examples:
%     To create a square root function in Matlab and then convert the array
%     information into a SAClab compatible structure and ultimately write
%     to a formatted binary file (SAC version 6 equivalent):
%
%      xarray=linspace(0,30,1000);
%      yarray=sqrt(xarray);
%      data=bseis(xarray,yarray);
%      data.name='myfile';
%      wseis(data);
%
%    See also:  wseis, rseis

%     Version History:
%        ????????????? - Initial Version
%        June 12, 2008 - Documentation Update
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated June 12, 2008 at 19:20 GMT

% check number of inputs
if (mod(nargin,2)) 
    error('SAClab:bseis:badNargs','Unpaired x/y vectors!')
end

% preferred SAClab header version
pref=6;

% get preferred header layout
h=seisdef(pref);

% undefine numeric header
undef=zeros(h.size,1,h.store);
for i=1:length(h.ntype)
    for j=1:length(h.(h.ntype{i}))
        undef(h.(h.ntype{i})(j).minpos:h.(h.ntype{i})(j).maxpos)=h.undef.ntype;
    end
end

% undefine char header
for i=1:length(h.stype)
    for j=1:length(h.(h.stype{i}))
        sfields=fieldnames(h.(h.stype{i})(j).pos);
        for k=1:length(sfields)
            m=h.(h.stype{i})(j).pos.(sfields{k});
            n=m(2)-m(1)+1; o=length(h.undef.stype);
            undef(m(1):m(2))=[h.undef.stype repmat(32,1,n-o)];
        end
    end
end

% get this platform's native byte-order
[platform,maxint,endian]=computer;
clear platform maxint
if(strcmpi(endian,'L')); endian='ieee-le';
else endian='ieee-be'; end

% create structure
data(1:nargin/2,1)=struct('version',pref,'endian',endian,'name',[],...
    'head',undef,'x',[]);

% loop for each pair
for i=1:2:nargin
    % output index
    j=round((i+1)/2);
    
    % check vector lengths
    if(~isnumeric(varargin{i}) || ~isvector(varargin{i}))
        error('SAClab:bseis:badInput',...
            'xarray must be a numeric vector: pair %d',j)
    end
    if(~isnumeric(varargin{i}) || ~isvector(varargin{i+1}))
        error('SAClab:bseis:badInput',...
            'yarray must be a numeric vector: pair %d',j)
    end
    npts=length(varargin{i});
    if(npts~=length(varargin{i+1}))
        error('SAClab:bseis:badInput',...
            'x and y series are not the same length: pair %d',j)
    end
    
    % fill in dependent variable
    data(j).x=varargin{i+1}(:);
    
    % fill in knowns/presets
    delta=(varargin{i}(end)-varargin{i}(1))/(npts-1);
    data(j)=ch(data(j),...
        'delta',delta,'b',varargin{i}(1),'e',varargin{i}(end),...
        'npts',npts,'depmin',min(data(j).x(:)),...
        'depmax',max(data(j).x(:)),'depmen',mean(data(j).x(:)),...
        'iftype','General X vs Y file','leven','true','lcalda','true',...
        'lovrok','true','lpspol','false','nvhdr',pref,...
        'knetwk','SAClab');
    
    % if timeseries is unevenly spaced add proper info
    if(abs(delta-(varargin{i}(min([2 end]))-varargin{i}(1)))>10*eps)
        data(j).t=varargin{i}(:);
        data(j)=ch(data(j),'leven','false',...
            'odelta',data(j).t(min([2 end]))-data(j).t(1));
    end
end

end