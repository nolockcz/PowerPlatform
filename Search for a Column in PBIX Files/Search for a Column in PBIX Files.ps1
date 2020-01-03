<#
    .SYNOPSIS
        Search for all PBIX files containing a regex phrase.
    .DESCRIPTION
        It parses all PBIX files in a directory recursively and 
        searches for all occurences of a regex phrase.
        Developed as a helper tool for finding all PBIX files
        which contain a column in a measure, calculated table or
        calculated column.
    .INPUTS
        - PBIT file
        - searched phrase
    .OUTPUTS
        List of file paths
    .NOTES
        Version:        1.0
        Author:         Michal Dvorak (@nolockcz)
        Creation Date:  03.01.2020
        Purpose/Change: Initial script development
#>

##### CHANGE
    # where to search
    $rootDirectory = "C:\Users\..."
    # what to search (as regex)
    $searchedPhraseRegex = "Measure[A-Z][A-Z]C"
##### CHANGE END

# if rootDirectory doesn't exist, return
$rootDirectoryExists = Test-Path -Path $rootDirectory
if (!$rootDirectoryExists) {
    Throw "The path " + $rootDirectory + " doesn't exist."
}

# save the original working directory
$originalWorkingDirectory = Get-Location

try {
    # hide the progress of unpacking files
    $progressPreference = 'SilentlyContinue'

    # get paths of all *.pbix files in the rootDirectory or any other subdirectory
    $pbixFilePaths = Get-ChildItem -Path $rootDirectory -Include "*.pbix" -Recurse | ForEach-Object { $_.FullName }

    # a name of a temp working directory
    $tempDirectoryName = New-Guid
    # create a new temp working directory
    $tempDirectoryPath = New-Item -Path $rootDirectory -Name $tempDirectoryName -ItemType "directory"
    # go to the new directory
    Set-Location -Path $tempDirectoryPath

    # for each pbix-file
    foreach ($pbixFilePath in $pbixFilePaths) {    
        # create a copy of the file and change the extension to .zip
        Copy-Item $pbixFilePath -Destination "tmp.zip"

        # try unpack and read the content
        try {
            # unpack the zip file
            Expand-Archive -Path "tmp.zip" -DestinationPath "tmp"
            # read the content of the file Report\Layout
            $fileContent = Get-Content -Path "tmp\Report\Layout" -Encoding Unicode -Raw | ConvertFrom-Json
        }
        catch {        
            # if something goes wrong, log and continue
            Write-Output $("Not Evaluated: " + $pbixFilePath.Replace($rootDirectory, ""))
            continue
        }

        # if the file contains the search phrase, log the shorten file path
        if (($fileContent | Select-String  -Pattern $searchedPhraseRegex).length -gt 0) {
            Write-Output $($pbixFilePath.Replace($rootDirectory, ""))
        }

        # remove all temp files
        if (Test-Path -Path $tempDirectoryPath) {
            Get-ChildItem -Path $tempDirectoryPath -Recurse | Remove-Item -Force -Recurse
        }
    }

    # set the root working directory to leave the temp directory
    Set-Location -Path $rootDirectory

    # remove the tmp working direcotry
    if (Test-Path -Path $tempDirectoryPath) {
        Remove-Item -Path $tempDirectoryPath -Recurse -Force
    }
}
finally {
    # set the original working directory back again
    Set-Location -Path $originalWorkingDirectory    

    # show progress again
    $progressPreference = 'Continue'
}