function ConvertTo-YamlString {
    param([Parameter(Mandatory)][string] $Value)

    ConvertTo-Json -InputObject $Value -Compress
}

function Convert-WinGetExportToDsc {
    <#
    .SYNOPSIS
    Converts a WinGet JSON export to a DSC v3 or WinGet DSC YAML configuration.
    .DESCRIPTION
    Reads the Sources and Packages arrays produced by winget export. Each package
    becomes a Microsoft.WinGet/Package resource for DSCv3 or a
    Microsoft.WinGet.DSC/WinGetPackage resource for WinGet.
    Resource names use the exact package IDs. Duplicate IDs are rejected.
    The legacy WinGet schema restricts resource names to letters, numbers, and
    spaces, so package IDs containing punctuation do not satisfy that restriction.
    Source names and known versions are preserved as strings. Missing, empty, or
    Unknown versions are omitted with a warning so DSC can select a version.
    JSON exports without Version fields are supported without additional options.
    WinGet resources include ensure: Present; DSCv3 resources do not.

    No YAML module is required. Existing output files are protected unless -Force
    is specified. Conversion does not install packages or run DSC.
    .PARAMETER InputPath
    Path to a JSON file produced by winget export, regardless of its extension.
    .PARAMETER OutputPath
    Destination YAML file. Defaults to <input-name>.dsc.yaml beside the input.
    .PARAMETER Author
    Author recorded in configuration metadata. Defaults to the current user name.
    .PARAMETER Description
    Description recorded in configuration metadata.
    .PARAMETER ContentVersion
    Version string written to contentVersion for DSCv3 (default "0.1.0") or
    configurationVersion for WinGet (default "0.1.0").
    ConfigurationVersion is an alias for this parameter.
    .PARAMETER Schema
    Configuration format: DSCv3 (default) or WinGet. Selects the schema URL,
    resource type, version field, and default version.
    .PARAMETER Force
    Allows replacement of an existing output file, but never the input file.
    .EXAMPLE
    Convert-WinGetExportToDsc -InputPath D:\Git\winget\sys4ops.json -Author 'Michal'
    .EXAMPLE
    Convert-WinGetExportToDsc -InputPath .\packages.json -Schema WinGet -ConfigurationVersion '0.2.0'
    .OUTPUTS
    System.IO.FileInfo
    The generated configuration file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $InputPath,

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $OutputPath,

        [ValidateNotNullOrEmpty()]
        [string] $Author = [Environment]::UserName,

        [ValidateNotNullOrEmpty()]
        [string] $Description = 'WinGet packages converted from winget export',

        [Alias('ConfigurationVersion')]
        [ValidateNotNullOrEmpty()]
        [string] $ContentVersion,

        [ValidateSet('DSCv3', 'WinGet')]
        [string] $Schema = 'DSCv3',

        [switch] $Force
    )

    $ErrorActionPreference = 'Stop'

    if ($Schema -eq 'WinGet') {
        $schemaUri = 'https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/2023/08/config/document.json'
        $resourceType = 'Microsoft.WinGet.DSC/WinGetPackage'
        $versionField = 'configurationVersion'
        $defaultVersion = '0.1.0'
    }
    else {
        $schemaUri = 'https://aka.ms/dsc/schemas/v3/bundled/config/document.json'
        $resourceType = 'Microsoft.WinGet/Package'
        $versionField = 'contentVersion'
        $defaultVersion = '0.1.0'
    }
    if (-not $PSBoundParameters.ContainsKey('ContentVersion')) {
        $ContentVersion = $defaultVersion
    }

    $inputFile = Get-Item -LiteralPath $InputPath
    if ($inputFile -isnot [System.IO.FileInfo]) {
        throw "InputPath must refer to a file: $InputPath"
    }

    if (-not $PSBoundParameters.ContainsKey('OutputPath')) {
        $OutputPath = [System.IO.Path]::ChangeExtension($inputFile.FullName, '.dsc.yaml')
    }
    $outputFilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
    if ([string]::Equals($inputFile.FullName, $outputFilePath, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'InputPath and OutputPath must refer to different files.'
    }
    if ((Test-Path -LiteralPath $outputFilePath) -and -not $Force) {
        throw "Output file already exists. Use -Force to replace it: $outputFilePath"
    }

    $export = Get-Content -LiteralPath $inputFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($null -eq $export -or $export -isnot [pscustomobject] -or $export.Sources -isnot [array]) {
        throw 'Invalid WinGet export: expected an object containing a Sources array.'
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('$schema: ' + $schemaUri)
    $lines.Add('')
    $lines.Add('metadata:')
    $lines.Add('  author: ' + (ConvertTo-YamlString $Author))
    $lines.Add('  description: ' + (ConvertTo-YamlString $Description))
    $lines.Add('')
    $lines.Add($versionField + ': ' + (ConvertTo-YamlString $ContentVersion))
    $lines.Add('')
    $lines.Add('resources:')

    $packageIds = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($source in $export.Sources) {
        if ($null -eq $source -or $source -isnot [pscustomobject] -or
            $source.SourceDetails.Name -isnot [string] -or
            [string]::IsNullOrWhiteSpace($source.SourceDetails.Name) -or
            $source.Packages -isnot [array]) {
            throw 'Invalid WinGet export: every source must contain SourceDetails.Name and a Packages array.'
        }

        foreach ($package in $source.Packages) {
            if ($null -eq $package -or $package -isnot [pscustomobject] -or
                $package.PackageIdentifier -isnot [string] -or
                [string]::IsNullOrWhiteSpace($package.PackageIdentifier)) {
                throw 'Invalid WinGet export: every package must contain a nonempty string PackageIdentifier.'
            }

            $id = $package.PackageIdentifier
            if (-not $packageIds.Add($id)) {
                throw "Duplicate package ID '$id'. Each package must appear only once across all sources."
            }

            $lines.Add('  - name: ' + (ConvertTo-YamlString $id))
            $lines.Add('    type: ' + $resourceType)
            $lines.Add('    properties:')
            $lines.Add('      id: ' + (ConvertTo-YamlString $id))
            $lines.Add('      source: ' + (ConvertTo-YamlString $source.SourceDetails.Name))
            if ($Schema -eq 'WinGet') {
                $lines.Add('      ensure: Present')
            }

            $version = $package.Version
            if ($null -ne $version -and $version -isnot [string]) {
                throw "Invalid version for '$id': Version must be a string when provided."
            }
            if ([string]::IsNullOrWhiteSpace($version) -or $version.Trim() -ieq 'Unknown') {
                Write-Warning "Package '$id' has no known version; omitting the version property."
            }
            else {
                $lines.Add('      version: ' + (ConvertTo-YamlString $version))
            }
            $lines.Add('')
        }
    }

    if ($packageIds.Count -eq 0) {
        throw 'The WinGet export contains no packages. No configuration was written.'
    }

    $encoding = [System.Text.UTF8Encoding]::new($false)
    $fileMode = [System.IO.FileMode]::CreateNew
    if ($Force) {
        $fileMode = [System.IO.FileMode]::Create
    }
    $stream = [System.IO.File]::Open($outputFilePath, $fileMode, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    try {
        $content = $lines -join [Environment]::NewLine
        $bytes = $encoding.GetBytes($content)
        $stream.Write($bytes, 0, $bytes.Length)
    }
    finally {
        $stream.Dispose()
    }

    Get-Item -LiteralPath $outputFilePath
}

Export-ModuleMember -Function Convert-WinGetExportToDsc
