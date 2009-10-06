function [data]=mat2records(data,dep,idx1,ind,idx2,store,npts)
%MAT2RECORDS    Distributes a record matrix back into a SEIZMO struct
%
%    Usage:    data=mat2records(data,dep,idx1,ind,idx2,store,npts)
%
%    Description: MAT2RECORDS(DATA,DEP,IDX1,IND,IDX2,STORE,NPTS) imports
%     the data in DEP and IND (numeric arrays with each column as a
%     separate component of records - DEP contains the dependent components
%     and IND contains the independent components) into SEIZMO structure
%     DATA, outputing the updated structure.  IDX1 and IDX2 give the record
%     in DATA that each column corresponds to (if multiple columns belong
%     to a single record they will be ordered the same as they are in
%     DEP -- note IND cannot have multiple components for the same record).
%     STORE gives the data storage class for each record in DATA (not for
%     each column/component).  NPTS gives the number of points in each
%     record in DATA (not for each column/component).  This function is
%     typically used in conjunction with RECORDS2MAT to access functions
%     not in the SEIZMO toolbox.
%
%     **********************************************
%     FOR CREATING A NEW SEIZMO DATA STRUCTURE FROM
%     A MATRIX OF DATA, SEE THE COMMAND BSEIZMO!
%     **********************************************
%
%    Notes:
%     - IDX1 and IDX2 must match the number of columns in DEP and IND
%     - STORE must be a cell string array with as many elements as DATA
%     - NPTS must have the same number of elements as DATA
%
%    Header changes: see CHECKHEADER
%
%    Examples:
%     The typical usage:
%      [dep,idx1,ind,idx2,store,npts]=records2mat(data);
%      ...non-seizmo commands...
%      data=mat2records(data,dep,idx1,ind,idx2,store,npts);
%
%    See also: records2mat, bseizmo

%     Version History:
%        Feb. 16, 2008 - initial version
%        Feb. 21, 2008 - minor doc update
%        Feb. 23, 2008 - minor doc update
%        Feb. 28, 2008 - seischk support
%        Mar.  4, 2008 - minor doc update
%        June 15, 2008 - doc update
%        June 29, 2008 - doc update, .dep rather than .x
%        Nov. 22, 2008 - update for new name schema (now DISTRIBUTERECORDS)
%                        now accepts independent component input
%        Apr. 23, 2009 - fix nargchk and seizmocheck for octave,
%                        move usage up
%        June 25, 2009 - name change from DISTRIBUTERECORDS to MAT2RECORDS
%        Oct.  5, 2009 - update checkheader call, force checking
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Oct.  5, 2009 at 22:15 GMT

% todo:

% check input
msg=nargchk(7,7,nargin);
if(~isempty(msg)); error(msg); end

% check data structure
msg=seizmocheck(data);
if(~isempty(msg)); error(msg.identifier,msg.message); end

% loop through records
for i=1:numel(data)
    % retrieve dependent components from matrix
    oclass=str2func(store{i});
    data(i).dep=oclass(dep(1:npts(i),i==idx1));
    
    % add in independent component if given
    if(~isempty(i==idx2))
        data(i).ind=oclass(ind(1:npts(i),i==idx2));
    end
end

% turn on header checking
oldcheckheaderstate=get_checkheader_state;
set_checkheader_state(true);

% update header
data=checkheader(data);

% toggle checking back
set_checkheader_state(oldcheckheaderstate);

end
