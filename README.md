# sewmat
MATLAB wrapper for SQLite functionality using mksqlite (https://mksqlite.sourceforge.net/index.html). 
Adapted from https://github.com/icyveins7/sew.


# Opening a database
Initialise a ```Database``` object, which either creates or opens up an existing database.

```matlab
addpath sewmat
d = Database("testdb.db");
```

# Creating tables
Creation of tables requires a fmt input, which specifies the table columns and properties, as well as other conditions. Refer to ```FormatSpecifier``` for more details.
```matlab
d.createTable(fmt, "tablename");
```

# Format Specifiers
The framework uses a 1x2 cell array to store 1. columns and their associated properties; and 2. store other conditionals (e.g. UNIQUE(col1, col2)). Columns are stored as a MATLAB ```struct``` and additional conditions as a ```string array```. The format of the ```struct``` used is the same as that obtained when getTableColumns is called to query a table's columns and associated properties.

```matlab
fmt = cell(1,2)
fmt{1} = struct('name','col1','type','REAL','notnull',0,'dflt_value',[],'pk',0) 
fmt{1}(end+1) = struct('name','col2','type','REAL','notnull',0,'dflt_value',[],'pk',0) 
fmt{1}(end+1) = struct('name','col3','type','STRING','notnull',1,'dflt_value',[],'pk',0)
fmt{2} = ["UNIQUE(col1, col2)"];
```

Instead of manually defining the formats, the ```FormatSpecifier``` object can be instead used.
```matlab
fmtspec = FormatSpecifier();
fmtspec.addColumn('col1', 'REAL');
fmtspec.addColumn('col2', 'REAL');
fmtspec.addColumn('col3', 'STRING', notnull=1);
fmtspec.addCondition('UNIQUE(col1, col2)');
fmt = fmtspec.generate(); % use this to generate the cell array for input into other functions like createTable
```

# Inserts
For inserts, we package the data into a N x M ```cell array```, where N is the number of rows to inserts and M the number of columns. The following code provides two examples, one where a complete row (all columns) are being inserted, and another where only specific columns are being inserted into (hence requiring an additional input into the method).

```matlab
values = {1 10 "string1"; 
          2 20 "string2"; 
          3 30 "string3"}

% Inserts complete rows - insertValues automatically finds the column names of "tablenames"
d.insertValues("tablename", values); 

% Inserts incomplete rows - specify columns to insert into
values_incomplete = values(:, [1 3]);
columns_incomplete = ["col1" "col3"]; % Column names for insertion of incomplete rows
d.insertValues("tablename", values, columnNames = columnNames); 
```

# Queries
```matlab
d.selectValues("tablename"); % SELECT * FROM tablename
d.selectValues("tablename", conditions = ["col1 > 2"]); % SELECT * FROM tablename WHERE col1 > 2
d.selectValues("tablename", columnNames = ["col3"], conditions = ["col1 > 2"]); % SELECT col3 FROM tablename WHERE col1 > 2
d.selectValues("tablename", columnNames = ["col3"], conditions = ["col1 > 2"], orderBy = ["col2 DESC"]); % SELECT col3 FROM tablename WHERE col1 > 2 ORDER BY col2 DESC
```


