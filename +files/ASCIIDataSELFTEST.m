function ASCIIDataSELFTEST()

% Author: Åge Andreas Falnes Olsen, Justervesenet
% Date: 26-nov-2012


% Missing test: what happens if read() fails? There's a case when time
% conversion fails but file reading was successful. currentLine is not
% updated. 

allId = fopen('all');

setup();
testFileLeakage(allId);

readPlain();
testFileLeakage(allId);

readWithHead();
testFileLeakage(allId);

readCommented();
testFileLeakage(allId);

unwrapDates();
testFileLeakage(allId);

end

%% Tests

function setup()
%
% Tests that setup can be done
%

ad = files.ASCIIData;
assert(isempty(ad.filename), 'JV:SelftestFailed', ...
    'Without any filename supplied the filename property should be empty');

try
    ad.columnType = {'string'};
    error('JV:SelftestFailed', 'No error thrown when trying to access columnType directly');
catch me
    if ~strcmp(me.identifier, 'MATLAB:class:SetProhibited')
        rethrow(me);
    end
end

try
    ad.empty = {'NaN'};
    error('JV:SelftestFailed', 'No error thrown when trying to access columnType directly');
catch me
    if ~strcmp(me.identifier, 'MATLAB:class:SetProhibited')
        rethrow(me);
    end
end

ad.setColumnTypes('strING', 'DAte', 'daTe', 'nuMBer');
assert(all(strcmp(ad.columnType, {'string', 'date', 'date', 'number'})),...
    'JV:SelftestFailed', ...
    'Columntype property wrong');

ad.setEmptyValues('NaN', 'nan', 'NAAN', '[]');
assert(all(strcmp(ad.empty, {'NaN', 'nan', 'NAAN', '[]'})),...
    'JV:SelftestFailed', ...
    '"empty" property wrong');

test = file1();
ad.openFile(test);
assert(strcmp(test, ad.filename), 'JV:SelftestFailed', ...
    'File not opened correctly');

[pth, fn, xt] = fileparts(test);
test2 = fullfile(pth, [fn, '_copy', xt]);
copyfile(test, test2);

ad.openFile(pth, [fn, '_copy', xt]);
assert(strcmp(test2, ad.filename), 'JV:SelftestFailed', ...
    'File not opened correctly');

% before clearing: find the file id of the test file, then check if it is
% closed by the clear operation

allId = fopen('all');
m = length(allId);
for q = 1:m
    if strcmp(fopen(allId(q)), test)
        error('JV:SelftestFailed', ...
            'The file opening does not clean up any currently open files');
    elseif strcmp(fopen(allId(q)), test2)
        fid = allId(q);
    end
end

clear ad;

allId = fopen('all');
assert(~any(allId == fid), 'JV:SelftestFailed', ...
    'File not closed by the clear command');

ad = files.ASCIIData(test);
assert(strcmp(test, ad.filename), 'JV:SelftestFailed', ...
    'File not opened correctly');

clear ad;

ad = files.ASCIIData(pth, [fn, '_copy', xt]);
assert(strcmp(test2, ad.filename), 'JV:SelftestFailed', ...
    'File not opened correctly');


end

function readPlain()
%
% Reads a simple file
%

created = datenum(datestr(now, 'HH:MM:SS')); % used in a later test

test = file1();
ad = files.ASCIIData(test);

ad.decimal = '.';
ad.setColumnTypes('string', 'date', 'number');

assert(ad.currentLine == 0, 'JV:SelftestFailed', ...
    'Expected current line to 0 before any reading has been done');
% read all, first one way
ret = ad.read(inf);
ad.openFile(test); % reset file pointer to the first line to be read
[c1, c2, c3] = ad.read();

assert(isequal(c1, ret{1}), 'JV:SelftestFailed', ...
    'Expected same output when collecting all data in one output and when separating the columns');
assert(isequal(c2, ret{2}), 'JV:SelftestFailed', ...
    'Expected same output when collecting all data in one output and when separating the columns');
assert(isequal(c3, ret{3}), 'JV:SelftestFailed', ...
    'Expected same output when collecting all data in one output and when separating the columns');

assert(length(c1) == ad.currentLine, 'JV:SelftestFailed', ...
    'currentLine property is incorrect');

eofTest = ad.read(100);
assert(isempty(eofTest), 'JV:SelftestFailed', ...
    'Expected empty return variable at end-of-file');
eofTest = ad.getl();
assert(isempty(eofTest), 'JV:SelftestFailed', ...
    'Expected empty return variable at end-of-file');



ad.openFile(test); % reset file pointer to the first line to be read
assert(ad.currentLine == 0, 'JV:SelftestFailed', ...
    'Current line was not reset after reopening file');
% provoke error
try
    [c1Test, c2Test] = ad.read(); %#ok<NASGU,ASGLU>
    error('JV:SelftestFailed', ...
        'Expected error thrown when the number of columns in file does not match the number of output variables');
catch me
    if ~strcmp(me.identifier, 'JV:badOutput')
        rethrow(me);
    end
end

assert(ad.currentLine == 0, 'JV:SelftestFailed', ...
    'Expected current line = 0 after an erroneous reading attempt');

% Read lines five-by-five, expect output to be as before
ix = 1:5;
for q = 1:3
    [c1Test, c2Test, c3Test] = ad.read(5);
    assert(ad.currentLine == ix(end), 'JV:SelftestFailed', ...
        'currentLine incorrect');
    assert(isequal(c1Test, c1(ix)), 'JV:SelftestFailed', ...
        'Data not as expected');
    assert(isequal(c2Test, c2(ix)), 'JV:SelftestFailed', ...
        'Data not as expected');
    assert(isequal(c3Test, c3(ix)), 'JV:SelftestFailed', ...
        'Data not as expected');
    ix = ix + 5;
end

% read another line and expect empty outputs.
[c1Test, c2Test, c3Test] = ad.read(5);
assert(isempty(c1Test) && isempty(c2Test) && isempty(c3Test), ...
    'JV:SelftestFailed', ...
    'Expected empty outputs at end-of-file');


% -------------------------------------------------------------------------
%
% Now test on content and numeric type
%
% -------------------------------------------------------------------------

assert(iscellstr(c1), 'JV:SelftestFailed', ...
    'Expected strings in first column');
assert(isnumeric(c2), 'JV:SelftestFailed', ...
    'Expected times in second column');
assert(isnumeric(c3), 'JV:SelftestFailed', ...
    'Expected numbers in third column');
% This test will fail at midnight.
assert(all(c2 > created), 'JV:SelftestFailed', ...
    'Expected times in second column');


end

function readWithHead()
%
% Reads file with header in two ways
%

test = file2();
ad = files.ASCIIData(test);
ad.decimal = ',';
ad.firstLine = 4;
ad.setColumnTypes('number', 'number', 'number', 'number', 'number');

[c1, c2, c3, c4, c5] = ad.read();
assert(length(c1) == 12 && length(c2) == 12 && length(c3) == 12 ... 
    && length(c4) == 12 && length(c5) == 12, 'JV:SelftestFailed', ...
    'Number of lines read is wrong');

% test contents
c1True = 0.5 .* (1 + (1:12));
assert(all(c1(:) == c1True(:)), 'JV:SelftestFailed', ...
    'Read data incorrectly');
c2True = 0.5 .* (2 + (1:12));
assert(all(c2(:) == c2True(:)), 'JV:SelftestFailed', ...
    'Read data incorrectly');
c3True = 0.5 .* (3 + (1:12));
assert(all(c3(:) == c3True(:)), 'JV:SelftestFailed', ...
    'Read data incorrectly');
c4True = 0.5 .* (4 + (1:12));
assert(all(c4(:) == c4True(:)), 'JV:SelftestFailed', ...
    'Read data incorrectly');
c5True = 0.5 .* (5 + (1:12));
assert(all(c5(:) == c5True(:)), 'JV:SelftestFailed', ...
    'Read data incorrectly');

% reset to start of file
ad.openFile(test);
line = 'This is the final header line';
while 1
    ln = ad.getl;
    if strcmp(line, ln)
        break;
    end
    assert(~isempty(ln), 'JV:SelftestFailed', ...
        'Unable to read past header with line-by-line reading');
end

for q = 1:12
    [c1test, c2test, c3test, c4test, c5test] = ad.read(1);
    assert(ad.currentLine == q, 'JV:SelftestFailed', ...
        'Expected currentLine to increment while reading');
    assert(isequal(c1test, c1(q)) && isequal(c2test, c2(q)) && ...
        isequal(c3test, c3(q)) && isequal(c4test, c4(q)) && isequal(c5test, c5(q)), ...
        'JV:SelftestFailed', ...
        'Column contents inconsistent');
end

% Finally check that reading multiple lines well beyond end-of-file works
% as intended
ad.openFile(test);
lines = ad.getl(100);
assert(length(lines) == 16, 'JV:SelftestFailed', ...
    'Reading line-by-line failed');

end

function readCommented()
%
% Reads from a file with a header and comments
%

test = file3('#');
ad = files.ASCIIData(test);
ad.decimal = ',';
ad.firstLine = 4;
ad.setColumnTypes('number', 'number', 'number', 'number', 'number');
ad.comment = '#';

[c1, c2, c3, c4, c5] = ad.read();

assert(length(c1) == 15 && length(c2) == 15 && length(c3) == 15 && ...
    length(c4) == 15 && length(c5) == 15, ...
    'JV:SelftestFailed', ...
    'Reading a commented file failed');


end

function unwrapDates()
%
% Tests that date strings without day information are unwrapped at
% midnight.
%

fname = file4();

ad = files.ASCIIData(fname);
ad.setColumnTypes('date', 'number', 'string');
ad.firstLine = 2;

[tms, num, str] = ad.read();
tmsUnwrap = files.ASCIIData.unwrapTimes(tms);
assert(all(diff(tmsUnwrap) > 0) & ~all(diff(tms) > 0), ...
    'JV:SelftestFailed', ...
    'Expected times to be monotonically increasing');
assert(isnumeric(num), 'JV:SelftestFailed', ...
    'Wrong data type in "number" column');
assert(iscellstr(str), 'JV:SelftestFailed', ...
    'Wrong data type in "string" column');




end

function testFileLeakage(allBefore)
%
% Tests that no files have lingering unclosed IDs
%

allNow = fopen('all');
assert(isequal(allNow, allBefore), 'JV:SelftestFailed', ...
    'Some files were unclosed during the SELFTEST run');

end


%% Utilities

function fname = file1()
%
% Creates a simple test file
%
% The file has 3 columns, one text, one date, and one numeric.
%
%

pth = tempname;
mkdir(pth);
fname = fullfile(pth, 'test1.txt');

fid = fopen(fname, 'w');
tm = now;
for q = 1:15
    fprintf(fid, 'blabla%d\t%s\t%f\n', q, datestr(tm + q/24/60, 'HH:MM:SS'), mean(rand(q,1)));
end

fclose(fid);


end


function fname = file2()
%
% Creates a test file with a header.
%
% The file also has 5 numeric columns but numbers has , as decimal point.
%
% The rule for file content: each entry is the average of its row and
% column position. First entry is 1 (row = 1, col = 1, (1+1)/2 = 1). Second
% column in first row is 1.5: (1 + 2) / 2
%

pth = tempname;
mkdir(pth);
fname = fullfile(pth, 'test2.txt');

fid = fopen(fname, 'w');
fprintf(fid, 'This is a header line\n');
fprintf(fid, 'This is also a header line\n');
fprintf(fid, 'This is the final header line\n\n');

m = 5; % number of columns in the file

for q = 1:12
    data = 0.5 .* (q + (1:m));
    dataStr = num2str(data');
    dataStr = strrep(cellstr(dataStr), '.', ',');
    fprintf(fid, '%s\t%s\t%s\t%s\t%s\n', ...
        dataStr{1}, dataStr{2}, dataStr{3}, dataStr{4}, dataStr{5});
end

fclose(fid);


end


function fname = file3(commentstyle)
%
% A test file with comments written and empty lines interspersed between
% meaningful lines.
%


pth = tempname;
mkdir(pth);
fname = fullfile(pth, 'test3.txt');

fid = fopen(fname, 'w');
fprintf(fid, 'This is a header line\n');
fprintf(fid, 'This is also a header line\n');
fprintf(fid, 'This is the final header line\n\n');

m = 5; % number of columns in the file

for q = 1:20
    if q == 4 || q == 17
        fprintf(fid, '\n');
    elseif q == 7 || q == 9 || q == 19
        fprintf(fid, '%s This is a comment\n', commentstyle);
    else
        data = 0.5 .* (q + (1:m));
        dataStr = num2str(data');
        dataStr = strrep(cellstr(dataStr), '.', ',');
        fprintf(fid, '%s\t%s\t%s\t%s\t%s\n', ...
            dataStr{1}, dataStr{2}, dataStr{3}, dataStr{4}, dataStr{5});
    end
end

fclose(fid);

end


function fname = file4()
%
% Creates a file with date wrapping, ie times written in one column reach
% midnight and then keeps increasing
%
%

pth = tempname;
mkdir(pth);
fname = fullfile(pth, 'wrapping.txt');

midnight = datenum(datestr(now), 'dd-mmm-yyyy');
tm = (midnight-10/(24*2)):(1/(24*2)):(midnight+500/(24*2));
m = length(tm);

colNames = {'Time', 'number', 'string'};

fid = fopen(fname, 'w');
fprintf(fid, '%s\t%s\t%s\n', colNames{:});

for q = 1:m
    fprintf(fid, '%s\t%g\t%s\n', ...
        datestr(tm(q), 'HH:MM:SS'), ...
        randn(1,1), ...
        char(randi([65 125], 6, 1)));
end

fclose(fid);

end
