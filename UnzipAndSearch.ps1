# Define the path to the parent folder that contains the compressed files
$parentFolderPath = "C:\ParentFolder"

# Define the keywords to search for. Add more as needed
$keywords = @("keyword1", "keyword2")

# Define the path to 7-Zip, change as required depending on your install location
$sevenZipPath = "C:\Program Files\7-Zip\7z.exe"

# Define the path to the keyword output file
$outputFilePath = "C:\ParentFolder\output.txt"

# Initialize the output file
New-Item -Path $outputFilePath -ItemType File -Force | Out-Null

# Function to search for keywords in files
function Search-Keywords {
    param (
        [string]$path,
        [string[]]$keywords,
        [string]$outputFilePath
    )

    Get-ChildItem -Path $path -Recurse -File | ForEach-Object {
        $fileContent = Get-Content -Path $_.FullName -Raw
        foreach ($keyword in $keywords) {
            if ($fileContent -match $keyword) {
                $output = "Keyword '$keyword' found in file: $($_.FullName)"
                Write-Host $output
                Add-Content -Path $outputFilePath -Value $output
            }
        }
    }
}

# Function to extract zip files using 7-Zip
function Extract-ZipFile {
    param (
        [string]$zipPath,
        [string]$destinationPath,
        [string]$sevenZipPath
    )

    # Create destination folder if it doesn't exist
    if (-not (Test-Path -Path $destinationPath)) {
        New-Item -Path $destinationPath -ItemType Directory | Out-Null
    }

    # Extract the zip file using 7-Zip
    $arguments = "x `"$zipPath`" -o`"$destinationPath`" -y"
    & "$sevenZipPath" $arguments

    if ($LASTEXITCODE -ne 0) {
        $errorMessage = "Failed to extract zip file: $zipPath"
        Write-Host $errorMessage
        Add-Content -Path $outputFilePath -Value $errorMessage
        return $false
    }

    return $true
}

# Unzip all zip files in the parent folder and search for keywords
Get-ChildItem -Path $parentFolderPath -Recurse -Filter *.zip | ForEach-Object {
    $zipPath = $_.FullName
    $destinationPath = [System.IO.Path]::Combine($parentFolderPath, [System.IO.Path]::GetFileNameWithoutExtension($zipPath))

    # Extract the zip file
    if (Extract-ZipFile -zipPath $zipPath -destinationPath $destinationPath -sevenZipPath $sevenZipPath) {
        # Search for keywords in the unzipped files
        Search-Keywords -path $destinationPath -keywords $keywords -outputFilePath $outputFilePath
    }
}
