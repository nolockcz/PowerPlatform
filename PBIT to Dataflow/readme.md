# Convert a Power BI dataset to a Power BI Dataflow

I have analyzed the internals of PBIT files and Power BI Dataflow JSON files in depth and created a PowerShell script which converts any PBIT into Power BI Dataflow JSON.

## High-level description
It parses Power Query queries, their names, Power Query Editor groups, and some additional properties from a PBIT file. Then it transforms all the parsed information into a form which is used by Power BI Dataflows. It is a JSON file used for import/export of dataflows. An example of such a file follows:
```json
{
    "name": "Migration Test",
    "description": "",
    "version": "1.0",
    "culture": "de-DE",
    "modifiedTime": "2019-12-04T10:15:10.9208101+00:00",
    "pbi:mashup": {
        "fastCombine": false,
        "allowNativeQueries": false,
        "queriesMetadata": {
            "Test Tabelle 1": {
                "queryId": "c366b94f-cf0b-4cf2-badd-8cae128741a2",
                "queryName": "Test Tabelle 1",
                "queryGroupId": "96d1e7ce-8815-4582-9e5e-592fb7ac51cd",
                "loadEnabled": true
            },
            "Test Tabelle 2": {
                "queryId": "2b7d7845-06ba-4348-ab7d-107905d8e40a",
                "queryName": "Test Tabelle 2",
                "loadEnabled": true
            }
        },
        "document": "section Section1;\r\nshared #\"Test Tabelle 1\" = let\r\n  Quelle = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText(\"i45WMlSK1YlWMgKTxkqxsQA=\", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type text) meta [Serialized.Text = true]) in type table [#\"Spalte 1\" = _t]),\r\n  #\"Geänderter Spaltentyp\" = Table.TransformColumnTypes(Quelle, {{\"Spalte 1\", Int64.Type}})\r\nin\r\n  #\"Geänderter Spaltentyp\";\r\nshared #\"Test Tabelle 2\" = let\r\n  Quelle = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText(\"i45WMlSK1YlWMgKTxkqxsQA=\", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type text) meta [Serialized.Text = true]) in type table [#\"Spalte 1\" = _t]),\r\n  #\"Geänderter Spaltentyp\" = Table.TransformColumnTypes(Quelle, {{\"Spalte 1\", Int64.Type}})\r\nin\r\n  #\"Geänderter Spaltentyp\";\r\n"
    },
    "annotations": [
        {
            "name": "pbi:QueryGroups",
            "value": "[{\"id\":\"96d1e7ce-8815-4582-9e5e-592fb7ac51cd\",\"name\":\"a\",\"description\":null,\"parentId\":null,\"order\":0}]"
        }
    ],
    "entities": [
        {
            "$type": "LocalEntity",
            "name": "Test Tabelle 1",
            "description": "",
            "pbi:refreshPolicy": {
                "$type": "FullRefreshPolicy",
                "location": "Test%20Tabelle%201.csv"
            },
            "attributes": [
                {
                    "name": "Spalte 1",
                    "dataType": "int64"
                }
            ]
        },
        {
            "$type": "LocalEntity",
            "name": "Test Tabelle 2",
            "description": "",
            "pbi:refreshPolicy": {
                "$type": "FullRefreshPolicy",
                "location": "Test%20Tabelle%202.csv"
            },
            "attributes": [
                {
                    "name": "Spalte 1",
                    "dataType": "int64"
                }
            ]
        }
    ]
}
```

## Low-level description
The low-level description is the PowerShell code itself. I have documented every single line and I hope it is understandable for everybody.

In this project I use the files DataMashup and DataModelSchema. When you open the file DataMashup, you only see some binary text.

![img](https://github.com/nolockcz/PowerPlatform/raw/master/PBIT%20to%20Dataflow/readme%20images/1.PNG)

But when you scroll to the right you see there is an XML object. That is the part of the file I am interested in. It contains all the Power Query queries and their properties.

![img](https://github.com/nolockcz/PowerPlatform/raw/master/PBIT%20to%20Dataflow/readme%20images/2.PNG)

The second file, DataModelSchema, is a JSON file. It contains all tables and their columns which are loaded into the tabular model.

![img](https://github.com/nolockcz/PowerPlatform/raw/master/PBIT%20to%20Dataflow/readme%20images/3.PNG)

There are also columns’ properties but many of them, like *summarizeBy* or *Format*, are important for the Power BI model but not for a dataflow. The only important property is the data type of a column. The rest can be ignored.

## How to use the script
The script is written in PowerShell 5.1. There is a plenty of functions defined at the beginning. The start of the execution is in the end of the script. 

But first, navigate to the directory where your PBIT file is stored. Then go to the end of the script and change the variable *$fileName* to the name of your PBIT file. The output file will be generated in the same directory with a name of your PBIT file + “.json”. You can change the name if needed, too. The last line is the call of the function *GenerateMigrationString*. Its return value is then saved to the output file.
```powershell
# name of the input PBIT file
$fileName = "BaseIT Dataset v1.2.pbit"
# name of the output JSON file
$jsonOutputFileName = $fileName + ".json"

# generate the migration string from a PBIT file
GenerateMigrationString($fileName) | Out-File $jsonOutputFileName -Encoding utf8
```

The last step is an import into Power BI Dataflows as you can see on the following screenshot.

![img](https://github.com/nolockcz/PowerPlatform/raw/master/PBIT%20to%20Dataflow/readme%20images/20.png)

I have tested the code with a huge dataset having over 300 complex queries in its ETL process.

![img](https://github.com/nolockcz/PowerPlatform/raw/master/PBIT%20to%20Dataflow/readme%20images/4.PNG)

And the working result in Power BI Dataflows:

![img](https://github.com/nolockcz/PowerPlatform/raw/master/PBIT%20to%20Dataflow/readme%20images/5.png)

## Limitations
I would like to describe some limitations of Power BI source files and Power BI Dataflows.

### Group names and group hierarchy
While analyzing the structure of a PBIT/PBIX file I found out that I can parse a group ID of a Power Query Group, but not its name. Moreover, I could not read the hierarchy of groups.

![img](https://github.com/nolockcz/PowerPlatform/raw/master/PBIT%20to%20Dataflow/readme%20images/10.PNG)

These both properties are stored encrypted in the file DataMashup, as you can see on the following screenshot.

![img](https://github.com/nolockcz/PowerPlatform/raw/master/PBIT%20to%20Dataflow/readme%20images/11.PNG)

I have tried to decode it with a Base64 decoder, but I have got only a binary object. My next idea was to check if it is an encoded table like in Power Query Enter Data Explained. Also not working. If somebody has an idea, how to decode and interpret the group names and the group hierarchy, please let me know.

### The exact order of properties

There were some stumbling stones during the development. One of them is an order of properties. Do not ask me why, but sometimes the order of properties in the dataflow JSON import file plays a role. If you do not keep the exact order, the import file is rejected by Power BI Dataflow. I worked with objects which are serialized to JSON. At the beginning, I did not know how to force the JSON serializer to generate properties in an exact order. The solution was using the Add-Member method.

![img](https://github.com/nolockcz/PowerPlatform/raw/master/PBIT%20to%20Dataflow/readme%20images/12.PNG)

### #shared
Do you know the record #shared? It contains all build-in and custom functions and all your custom queries. More about that for example here. The problem is this record works in Power BI Desktop only and cannot be used in Power BI Service. The PowerShell script ignores all queries containing the keyword #shared and writes a warning like “WARNING: The query 'Record Table' uses the record #shared. This is not allowed in Power BI Dataflows and the query won't be migrated.”

### Multiline comments in Power BI Dataflows
The Power BI Dataflows do not support multiline comments at the time of writing the article. There is already an official issue LINK and the bug will be fixed in the near future.

## Final words
I have a dataset containing an ETL process with more than 300 queries. If I wanted to migrate this dataset manually into Power BI Dataflows, it would take hours or even days. Thanks to this script, the job is done in minutes. And every single next dataset, too 😊

## The original blog post
The code is a part of a blog post: https://community.powerbi.com/t5/Community-Blog/How-To-Convert-a-Power-BI-Dataset-To-a-Power-BI-Dataflow/ba-p/918870