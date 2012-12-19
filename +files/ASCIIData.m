classdef ASCIIData < handle
    %
    % Generic ASCII data file reading.
    % 
    % Loads data in column format.
    %
    % The class acts as a wrapper around the Matlab function textscan(). It
    % has properties corresponding to most of the options possible to send
    % down to textscan(), including the column separator and comment
    % characters. 
    %
    % The class is doing some generic parsing of the file contents. All
    % data is read as strings, but numbers and date strings are converted
    % by the class. Whether to use "." or "," as decimal point is
    % configurable.
    %
    % NOT IMPLEMENTED YET: If any date columns exist in the data file the
    % class can assume that data are in chronological order and force
    % unwrap the times at midnight if the time strings do not contain day
    % information.
    %
    
    
    %
    % Author: Åge Andreas Falnes Olsen, Justervesenet
    % Date: 26-nov-2012
    %
    
    properties
        
        columnSep = '\t';
        decimal = '.';
        % The line to begin parsing at. 
        firstLine = 1; 
        % A combination of characters indicating a comment, ie a line to be
        % skipped
        comment = '%';
                
    end
    
    properties (SetAccess = protected)
        
        filename = '';
        % 'string', 'number', or 'date', one entry for each column in the
        % file.
        columnType = {};
        
        % Strings which indicates empty values in case of numeric type
        empty = {};
        
        % current line in file, not including the header lines.
        currentLine = 0;
        
    end
    
    properties (Access = protected)
        % File id
        fid;
        
        % Format string used in textscan()
        fmt;
        
        % Multiple delimiters as one
        mdao = false;
                
    end
    
    methods
        
        function this = ASCIIData(pth, fname)
            %
            % this = ASCIIData()
            % this = ASCIIData(pth)
            % this = ASCIIData(pth, fname)
            %
            
            if nargin == 0
                % Do nothing
            elseif nargin > 2
                error('JV:badInput', ...
                    'Use 0, 1 or 2 inputs');
            elseif nargin == 1
                this.openFile(pth);
            elseif nargin == 2
                this.openFile(pth, fname);
            end
            
            
        end
        
        function openFile(this, pth, name)
            %
            % Open new file or reset file pointer to start of file
            %
            % openFile(pth)
            % openFile(pth, name)
            %
            
            if nargin == 2
                this.filename = pth;
            elseif nargin == 3
                this.filename = fullfile(pth, name);
            end
            
            this.closeFile();
            
            this.fid = fopen(this.filename, 'r');
            
            this.currentLine = 0;
            
        end
        
        function delete(this)
            % Object destructor
            
            this.closeFile();
            
        end
        
        function setColumnTypes(this, varargin)
            %
            % Set data types in all columns.
            %
            % setColumnTypes(col1, col2, ...)
            %
            % col<i>   - string, either 'string', 'number', or 'date'.
            %
            
            this.columnType = lower(varargin);
            tmp = '';
            n = nargin - 1;
            for q = 1:n
                if q < n
                    tmp = [tmp '%s' this.columnSep]; %#ok<AGROW>
                else
                    tmp = [tmp '%s']; %#ok<AGROW>
                end
            end
            this.fmt = tmp;
            
        end
        
        function setEmptyValues(this, varargin)
            %
            % Set strings which indicate empty values, eg NaN, NA.
            %
            % setEmptyValues(string1, string2, ...)
            %
            % string<i>   - any string.
            %
            
            this.empty = varargin;
            
        end
        
        function varargout = read(this, n)
            %
            % Read and parse the next data block
            %
            % read()
            % read(n)
            % ret = read(...)
            % [col1 col2 col3 ...] = read(...)
            %
            % n    - the number of lines to read. inf = all. Default is
            %        inf.
            %
            
            types = this.columnType;
            assert(~isempty(types), 'JV:badSetup', ...
                'Column data types must be specified');
            m = length(types);
            
            if nargin == 1
                n = inf; 
            end
            
            if nargout > 1
                % make sure every column is assigned an output
                assert(nargout == m, 'JV:badOutput', ...
                    'Every column must be assigned an output, or else all columns must be collected into a single output');
            end
            
            % Skip headerlines ONLY if file pointer is at beginning of file
            if ftell(this.fid) == 0
                hdr = this.firstLine - 1;
            else
                hdr = 0;
            end
            
            tmp = textscan(this.fid, this.fmt, n, ...
                'Delimiter', this.columnSep, ...
                'CommentStyle', this.comment, ...
                'HeaderLines', hdr, ...
                'MultipleDelimsAsOne', this.mdao);
            
            eof = all(cellfun(@(a)isempty(a), tmp));
            
            if ~eof
                % Convert date strings into Matlab time
                k = find(strcmp(types, 'date'));
                if ~isempty(k)
                    m = length(k);
                    for q = 1:m
                        tmp{k(q)} = datenum(tmp{k(q)});
                    end
                end
                
                % Convert numeric strings to numbers
                k = find(strcmp(types, 'number'));
                if ~isempty(k)
                    convert = ~strcmp(this.decimal, '.');
                    m = length(k);
                    for q = 1:m
                        if convert
                            tmp{k(q)} = strrep(tmp{k(q)}, this.decimal, '.');
                        end
                        tmp{k(q)} = str2double(tmp{k(q)});
                    end
                end
                
                % update currentLine
                this.currentLine = this.currentLine + length(tmp{1});
                
                % Finally wrap up results to comply with output arguments
                if nargout == 1
                    varargout{1} = tmp;
                elseif nargout > 1
                    varargout = cell(nargout, 1);
                    for q = 1:nargout
                        varargout{q} = tmp{q};
                    end
                end
                
            else
                varargout = cell(nargout, 1);
                for q = 1:nargout
                    varargout{q} = [];
                end
            end
            
            
        end
        
        function line = getl(this, n)
            %
            % Read the next lines without parsing.
            %
            % line = getl()
            % line = getl(n)
            %
            % No inputs: read only one line.
            %
            % Next time read() is called, it starts after the last line
            % read by getl().
            %
            
            if nargin == 1
                n = 1;
            end
            
            line = cell(n,1);
            
            for q = 1:n
                line{q} = fgetl(this.fid);
                if isnumeric(line{q})
                    line = line(1:q-1);
                    break
                end
            end
            
        end
        
    end
    
    methods (Access = protected)
                
        function closeFile(this)
            %
            % Closes currently open file if there is one
            %
            
            if ~isempty(this.fid)
                fg = fopen(this.fid);
                if ~isempty(fg)
                    fclose(this.fid);
                end
            end

        end
                
    end
    
    methods (Static = true)

        function tm = unwrapTimes(tm)
            %
            % Unwraps time stamps at midnight
            %
            % Applicable only to cases where the times have been parsed
            % from a datestring without day information, i.e. of the form
            % "21:30:23". Such strings wrap at midnight.
            % 
            
            % Find the indexes where time wraps from (i-1)th to i'th.
            n = find(diff(tm) < 0) + 1;
            m = length(n);
            for q = 1:m
                tm(n(q):end) = tm(n(q):end) + 1;
            end
            
        end
        
        function ad = browse(pth)
            %
            % Special GUI constructor which presents a file browser 
            %
            
            pattern = {'*.dat;*.txt;*.xls*', 'Data files'; '*.*', 'All files'};
            
            if nargin == 0
                [fn, pth] = uigetfile(pattern, ...
                    'Select data files to open', 'MultiSelect', 'on');
            else
                [fn, pth] = uigetfile(pattern, ...
                    'Select data files to open', pth, 'MultiSelect', 'on');
            end
            
            if isnumeric(fn) % assume user cancelled
                ad = [];
            elseif iscell(fn)
                m = length(fn);
                ad(m) = files.ASCIIData();
                for q = 1:m
                    ad(q).openFile(pth, fn{q});
                end
            else
                ad = files.ASCIIData(pth, fn);
            end
            
        end
        
    end
    
    
end

