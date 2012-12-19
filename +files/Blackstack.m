classdef Blackstack < files.ASCIIData
    %
    % Class which reads Labview generated data files from Blackstack 
    %
    % 
    
    % Author: Åge Andreas Falnes Olsen, Justervesenet
    % Date: 26-nov-2012
    
    properties (SetAccess = protected)
                
        % Room environment data from header. Empty if unavailable
        humidity;
        temperature;
        % Date for start of measurements
        date;
        description;
        
    end
    
    methods
        
        function this = Blackstack(varargin)
            %
            % 
            % 
            
            this = this@files.ASCIIData(varargin{:});
            
            % Columns are time and temperature
            this.setColumnTypes('string', 'number');
            this.decimal = ',';
            this.columnSep = '\t';
            
            % read the header. 
            this.parseHeader();
            
        end
        
        function data = read(this, varargin)
            %
            % Read data from file
            %
            % data = read()
            % data = read(n)
            %
            
            [tmString, temp] = read@files.ASCIIData(this, varargin{:});
            
            % A default day is added to times by Matlab. Here we want to
            % replace that default day with the actual day of measurements.
            tm = datenum(tmString, 'HH:MM:SS');
            tm = files.ASCIIData.unwrapTimes(tm);
            tm = files.Blackstack.changeDate(tm, this.date);
            
            % FIXME!failure when changing day during the measurement. 
            
            data = Data1D(tm, temp, 'Blackstack temperature');
            
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
            lines = this.getl(8);
            
            r = regexp(lines{3}, ':', 'split');
            this.date = strtrim(r{2});
            
            r = regexp(lines{4}, ':', 'split');            
            if isempty(r{2})
                this.temperature = [];
            else
                this.temperature = str2double(strrep(r{2}, ',', '.'));
            end
            
            r = regexp(lines{5}, ':', 'split');            
            if isempty(r{2})
                this.humidity = [];
            else
                this.humidity = str2double(strrep(r{2}, ',', '.'));
            end
            
            r = regexp(lines{6}, ':', 'split');
            this.description = strtrim(r{2});
            
        end
        
    end
    
    methods (Static = true)
        
        
        function tm = changeDate(tm, newDate, fmt)
            %
            % For a list of numeric Matlab times, shift the date
            %
            % tm = changeDate(tm, newDate)
            %
            % tm       - time vector (Matlab times, class double)
            % newDate  - any date in string format
            % fmt      - date string format. Default is 'dd.mm.yyyy'
            %
            % 
            
            if nargin < 3
                fmt = 'dd.mm.yyyy';
            end
            
            day = datenum(newDate, fmt);
            defaultDay = datenum(datestr(tm(1), 'ddmmmyyyy'), 'ddmmmyyyy');
            
            tm = tm - defaultDay + day;
        end
        
    end
    
    
end

