%% Database
% Perry Hong
% 20 March 2023
%
% Wrapper class for SQLite implementations in MATLAB
% For use with mksqlite
% Adapted from lken sew (https://github.com/icyveins7/sew)

%% Begin class definition
classdef Database

    properties (Access = private)
        filename 
        dbid 
    end

    %% Methods
    methods 
        
        %% Constructor
        % Creates the database object by opening an existing database or creating 

        function db = Database(filename)
            db.filename = filename;
            db.dbid = mksqlite('open', filename);
        end

        %% getFilename
        % Returns filename associated with the Database object

        function filename = getFilename(db)
            filename = db.filename;
        end

        %% getDbid
        % Returns dbid associated with the Database object

        function dbid = getDbid(db)
            dbid = db.dbid;
        end

        %% listTables
        % Returns a list of all tables in the database

        function tbs = listTables(db)
            tbs = mksqlite(db.dbid, 'SELECT name FROM sqlite_master WHERE type="table"');
        end

        %% createTable
        % Creates a table in the database with a given format - use FormatSpecifier to generate the cell array input for fmt

        function createTable(db, tablename, fmt, options)

            arguments
                db Database
                tablename char % Table name
                fmt (1,2) cell % [1 x 2] cell array of columns name-types and constraints. Instantiate a FormatSpecifier object and use generate() to create this
                options.ifNotExists logical = 0; % Prevents creation if the table already exists - default is 0.
            end

            stmt = Database.makeCreateTableStatement(tablename, fmt, options.ifNotExists);
            mksqlite(db.dbid, stmt);

        end

        %% getTableColumns
        % Returns column names and their associated constraints (type, NOT NULL, DEFAULT VALUE, PRIMARY KEY)

        function tbcols = getTableColumns(db, tablename)

            arguments
                db Database
                tablename char % Table name
            end

            tbcols = mksqlite(db.dbid, ['PRAGMA table_info(' tablename ')']);

        end

        %% dropTable
        % Drops a table from the database

        function dropTable(db, tablename)

            arguments
                db Database
                tablename char % Table name
            end

            stmt = Database.makeDropTableStatement(tablename);
            mksqlite(db.dbid, stmt);

        end

        %% insertValues
        % Insert values into a table
        % Input values specified as an [N x M] cell array, where N is the number of rows to insert and M the number of columns
        
        % Specific columns these values should be inserted into specified as a string array
        % If columns are not specified, it is assumed that the number of input values per entry are equal to the number of columns

        function insertValues(db, tablename, values, options)

            arguments
                db Database
                tablename char % Table name
                values cell % [N x M] cell array of values to insert, where N is the number of rows to insert and M the number of columns
                options.columnNames string = []; % [1 x M] string array of column names to insert values into
                options.replace logical = 0; % Overwrites the same data if 1, otherwise, a new row is always created - default is 0
            end

            % Read table schema
            if isempty(options.columnNames)
                tbcols = getTableColumns(db, tablename); 
                options.columnNames = string({tbcols.name});
            end

            if ~(length(options.columnNames) == size(values,2))
                error('Number of columns in input values does not correspond to the number of columns specified!')
            end

            stmt = Database.makeInsertStatement(tablename, columnNames, options.replace);

            % Loop over number of inserts
            for n = 1:size(values, 1)
                mksqlite(db.dbid, stmt, values(n,:));
            end

        end

        %% deleteValues
        % Delete values from a table that fulfill specified conditions

        % Conditions are input as a string array of conditions, which are always combined using AND
        % If an "OR" condition is desired, construct it manually and input as one value in the string array
        % e.g. ["time < 10 OR count >= 5", "cost < 3"] means (time < 10 OR count >= 5) AND (cost < 3)

        function deleteValues(db, tablename, options)

            arguments
                db Database
                tablename char % Table name
                options.conditions string = []; % String array of conditions for deletion. Multiple conditions are combined using AND -- e.g. ["time < 10", "count >= 5"]
            end 

            stmt = Database.makeDeleteStatement(tablename, options.conditions);
            mksqlite(db.dbid, stmt);
            
        end

        %% selectValues
        % Select values from specific columns of a table that fulfill specified conditions
        % Supports queries that combine multiple columns -- e.g. "100*dollars + cents AS total_cents"
        % If columns are not specified, all columns will be selected

        % Conditions are input as a string array of conditions, which are always combined using AND
        % If an "OR" condition is desired, construct it manually and input as one value in the string array
        % e.g. ["time < 10 OR count >= 5", "cost < 3"] means (time < 10 OR count >= 5) AND (cost < 3)

        % Output is ordered by orderBy, which is input as a string array of ordering priorities
        
        function output = selectValues(db, tablename, options)

            arguments
                db Database
                tablename char % Table name
                options.columnNames string = "*"; % [1 x M] cell array of column names to select values from
                options.conditions string = []; % String array of conditions for selection. Multiple conditions are combined using AND -- e.g. ["time < 10", "count >= 5"]
                options.orderBy string = []; % String array of ordering criteria for sorting of output, in order of priority -- e.g. ["time ASC", "count DESC"]
            end

           stmt = Database.makeSelectStatement(tablename, columnNames, options.conditions, options.orderBy);
           output = mksqlite(db.dbid, stmt);

        end

    end
        
    %% Static Methods
    methods (Static)

        %% Static method makeTableColumns
        function stmt = makeTableColumns(cols)

            stmt = '';

            names = {cols.keys};
            types = {cols.values};
            notnull = [cols.notnull];
            dflt_value = {cols.dflt_value};
            pk = [cols.pk];

            for n = 1:length(cols)

                % Primary key
                if pk(n)
                    pk_str = ' PRIMARY KEY';
                else
                    pk_str = '';
                end

                % Not null
                if notnull(n)
                    notnull_str = ' NOT NULL';
                else
                    notnull_str = '';
                end

                % Default value
                if ~isempty(dflt_value{n})
                    dflt_str = [' DEFAULT "' char(string(dflt_value{n})) '"'];
                else
                    dflt_str = '';
                end

                stmt = [stmt ', ' names{n} ' ' types{n} pk_str notnull_str dflt_str];
            end

            stmt = stmt(3:end); % Remove leading ", "

        end
    
        %% Static method makeTableConstraints
        function stmt = makeTableConstraints(constraints)

            arguments
                constraints string
            end

            stmt = char(strjoin(constraints, ', '));

            if ~isempty(stmt)
                stmt = [', ' stmt]; % Add leading ", "
            end

        end
        
        %% Static method makeCreateTableStatement
        function stmt = makeCreateTableStatement(tablename, fmt, ifNotExists)
    
            arguments
                tablename char
                fmt (1,2) cell
                ifNotExists logical = 0;
            end
        
            if ifNotExists
                exists_stmt = ' IF NOT EXISTS';
            else
                exists_stmt = '';
            end

            stmt = ['CREATE TABLE ' tablename exists_stmt ' (' Database.makeTableColumns(fmt{1}) Database.makeTableConstraints(fmt{2}) ')'];

        end

        %% Static method makeQuestionMarks
        function qmarks = makeQuestionMarks(n)

            arguments 
                n {mustBeInteger}
            end
            
            qmarks = repmat('?,', 1, n);
            qmarks = ['(' qmarks(1:end-1) ')']; % remove trailing ",", add "( )"

        end

        %% Static method makeInsertStatement
        function stmt = makeInsertStatement(tablename, columnNames, replace)

            arguments
                tablename char
                columnNames string
                replace logical = 0;
            end

            if replace
                insertstr = 'INSERT';
            else
                insertstr = 'REPLACE';
            end

            stmt = [insertstr ' INTO ' tablename '(' char(strjoin(columnNames, ',')) ') VALUES ' Database.makeQuestionMarks(length(columnNames))];

        end

        %% Static method stitchConditions
        function condsstr = stitchConditions(conditions)

            arguments
                conditions string
            end

            if isempty(conditions)
                condsstr = '';
            else
                condsstr = [' WHERE (' char(strjoin(conditions, ') AND (')) ')'];
            end

        end

        %% Static method stitchConditions
        function orderstr = stitchOrderBy(orderBy)

            arguments 
                orderBy string
            end

            if isempty(orderBy)
                orderstr = '';
            else
                orderstr = [' ORDER BY ' char(strjoin(orderBy, ', '))];
            end

        end

        %% Static method makeSelectStatement
        function stmt = makeSelectStatement(tablename, columnNames, conditions, orderBy)

            arguments
                tablename char
                columnNames string
                conditions string = {};
                orderBy string = {};
            end

            stmt = ['SELECT ' char(strjoin(columnNames,','))  ' FROM ' tablename Database.stitchConditions(conditions) Database.stitchOrderBy(orderBy)];

        end

        %% Static method makeDropTableStatement
        function stmt = makeDropTableStatement(tablename)

            arguments
                tablename char
            end

            stmt = ['DROP TABLE ' tablename];

        end

        %% Static method makeDeleteStatement
        function stmt = makeDeleteStatement(tablename, conditions)

            arguments
                tablename char
                conditions string = {};
            end

            stmt = ['DELETE FROM ' tablename Database.stitchConditions(conditions)];

        end

    end % end of static methods

end