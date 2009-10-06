% Seismology Toolbox for Matlab and Octave
% Version 0.6.0-r97 Ararat 05-Oct-2009
%
% Low-level internal functions
%CHECKPARAMETERS       - Parses options passed to CHECKHEADER
%CUTPARAMETERS         - Parses inputs defining the data window(s)
%GET_CHECKHEADER_STATE - Returns TRUE if CHECKHEADER is on, FALSE if not
%GETFILEVERSION        - Get filetype, version and byte-order of SEIZMO datafile
%GET_SEIZMOCHECK_STATE - Returns TRUE if SEIZMOCHECK is on, FALSE if not
%ISSEIZMO              - True for SEIZMO data structures
%PLOTCONFIGFIX         - Fixes the SEIZMO plot configuration struct
%SEIZMOCHECK           - Validate SEIZMO data structure
%SEIZMODEF             - Returns specified SEIZMO definition structure
%SEIZMOSIZE            - Returns header-estimated disksize of SEIZMO records in bytes
%SET_CHECKHEADER_STATE - Turn CHECKHEADER on (TRUE) or off (FALSE)
%SET_SEIZMOCHECK_STATE - Turn SEIZMOCHECK on (TRUE) or off (FALSE)
%VALIDSEIZMO           - Returns valid SEIZMO datafile versions
%VERSIONINFO           - Returns version info for SEIZMO data records
%WRITEPARAMETERS       - Implements options passed to WRITE functions

