classdef TRT2 < files.ASCIIData
    %
    % Class which reads TRT2 exported ASCII data files
    %
    % 
    
    % Author: Åge Andreas Falnes Olsen, Justervesenet
    % Date: 26-nov-2012
    
    properties (SetAccess = protected)
        
        % Emissivity used by TRT2 when computing temperatures
        emissivity;
        % Date for first measurement
        date;
        description;
        
        % Recorded data names. "Number" and "time" is always in the file
        % and they are excluded here.
        recordedData;
        
    end
    
    methods
        
        function this = TRT2(varargin)
            %
            %
            %
            
            this = this@files.ASCIIData(varargin{:});
            
            this.setColumnTypes('number', 'string', 'number');
            this.decimal = ',';
            this.columnSep = {'\t'};
            this.mdao = true;
            
            this.parseHeader();
            
        end
        
        
        function varargout = read(this, varargin)
            %
            % [data1, data2, ...] = read()
            % [data1, data2, ...] = read(n)
            %
            % data<i>    - Data1D objects.
            %
            % The output variables are determined from the number of stored
            % data in the data file. See property "recordedData".
            %
            
            m = length(this.recordedData);
            assert(nargout >= 1 && nargout <= 1 + m, 'JV:badOutput', ...
                'At least 1 outputs required and at most %d outputs allowed', 1 + m);
            
            tmp = read@files.ASCIIData(this, varargin{:});
            
            varargout = cell(nargout, 1);
            num = tmp{1};
            tm = datenum(tmp{2}, 'HH:MM:SS');
            tm = files.ASCIIData.unwrapTimes(tm);
            tm = files.Blackstack.changeDate(tm, this.date);
            
            n = length(tm);
            
            for q = 1:m
                if q > nargout
                    break
                end
                ix = q:m:n;
                varargout{q} = Data1D(tm(ix), tmp{3}(ix), this.recordedData{q});
            end
            
            % Return reading index as last output if so desired by caller.
            if q < nargout
                varargout{q+1} = num;
            end
            
        end
        
    end
    
    methods (Access = protected)
        
        function parseHeader(this)
            %
            % Parses file header
            %
            
            % The parser assumes a very strict adherence to header format
            
            % reset file pointer to start of file
            fseek(this.fid, 0, 'bof');
            
            % read 8 header lines
            lines = this.getl(13);
            
            r = regexp(lines{2}, ':', 'split');
            this.date = strtrim(r{end});
            % Remove last " and info on minutes/hours
            this.date = strtrim(this.date(3:end-1));
            
            
            r = regexp(lines{8}, ':', 'split');
            value = r{2}(1:end-1);
            if isempty(value)
                this.emissivity = [];
            else
                this.emissivity = str2double(value);
            end
                        
            r = regexp(lines{1}, ':', 'split');
            this.description = strtrim(r{2});
            % Also remove the last "
            this.description = this.description(1:end-1);
            
            % Parse the column header names
            r = regexp(strtrim(lines{12}), '\s+', 'split');
            this.recordedData = r(3:end);
            
        end
        
    end
    
end

