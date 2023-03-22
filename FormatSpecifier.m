%% FormatSpecifier
% Perry Hong
% 22 March 2023
%
% Class for specifying table format and conditions
% Adapted from lken sew (https://github.com/icyveins7/sew)

%% Begin class definition
classdef FormatSpecifier

    properties (Access=private)
        cols
        conds
    end
    
    methods

        %% Constructor
        function obj = FormatSpecifier()
            obj.cols = struct('name',{},'type',{},'notnull',{},'dflt_value',{},'pk',{}); % same format as mksqlite's output when calling getTableColumns 
            obj.conds = "";
        end

        %% Add column
        function addColumn(obj, columnName, columnType, options)
            arguments
                obj FormatSpecifier
                columnName char
                columnType char {mustBeMember(columnType,["INTEGER","REAL","NUMERIC","TEXT","BLOB"])}
                options.notNull logical = 0
                options.defaultValue = []
                options.primaryKey logical = 0
            end
        
            % Check if column already exists
            if any(strcmp({obj.cols.name}, columnName))
                error(['Error adding column - "' columnName '" already exists!'])
            end
            
            % Check if there is already a primary key 
            if options.primaryKey && any([obj.cols.pk])
                error('Error adding column as priamry key - a primary key already exists')
            end

            obj.cols(end+1) = struct('name',columnName,'type',columnType,'notnull',options.notNull,'dflt_value',options.defaultValue,'pk',options.primaryKey);
        end
        
        %% Get column names
        function columnNames = getColumns(obj)
            columnNames = string({obj.cols.name});
        end

        %% Clear all columns
        function obj = clearColumns(obj)
            obj.cols = struct('name',{},'type',{},'notnull',{},'dflt_value',{},'pk',{});
        end
        
        %% Add condition 
        function addCondition(obj, cond)
            arguments
                obj FormatSpecifier
                cond string
            end
            obj.conds(end+1) = cond;
        end

        %% Get conditions
        function conds = getConditions(obj)
            conds = obj.conds;
        end

        %% Clear conditions
        function obj = clearConditions(obj)
            obj.conds = "";
        end

        %% Output format
        function fmt = generate(obj)
            fmt = {obj.cols obj.conds};
        end

    end

end






