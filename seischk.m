function [report]=seischk(data,varargin)
%SEISCHK    Validate SAClab data structure
%
%    Description: Returns an appropriate error message structure if the
%     input variable fails certain SAClab data structure requirements.
%     Extra arguments must be strings corresponding to additional required 
%     fields in the SAClab data structure ('head' and 'version' are pre-
%     included).  The structure contains the fields 'identifier' and 
%     'message'.
%
%    Usage: error(seischk(data))
%           warning(seischk(data))
%           error(seischk(data,'requiredfield1','requiredfield2',...))
%           warning(seischk(data,'requiredfield1','requiredfield2',...))
%
%    Examples:
%     Writing out SAClab files requires the names and byte-orders of the
%     output files be set, so to include the fields 'name' and 'endian' in 
%     the check:
%
%           error(seischk(data,'endian','name'))
%
%     Most functions require data records stored in the field 'x'.  This
%     will perform a regular check as well as assure the 'x' field exists:
%
%           error(seischk(data,'x')
%
%    See also: isseis, seisdef

%     Version History:
%        ????????????? - Initial Version
%        June 12, 2008 - Documentation Update
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated June 12, 2008 at 05:35 GMT

% check data structure
report=[];
if(~isstruct(data))
    report.identifier='SAClab:seischk:dataNotStruct';
    report.message='SAClab data must be a structure';
elseif(isempty(data))
    report.identifier='SAClab:seischk:dataEmpty';
    report.message='SAClab data structure must not be empty';
elseif(~isvector(data))
    report.identifier='SAClab:seischk:dataNotVector';
    report.message='SAClab data structure must be a vector';
else
    reqfields=[{'head' 'version'} varargin];
    
    % this works with older isfield (check one at a time)
    for i=reqfields
        if(~isfield(data,i))
            report.identifier='SAClab:seischk:reqFieldNotFound';
            report.message=sprintf('SAClab data structure must have field ''%s''',i);
        end
    end
end

end