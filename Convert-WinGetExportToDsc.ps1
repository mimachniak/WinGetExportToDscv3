#requires -Version 5.1
<#
.SYNOPSIS
Compatibility entry point for the WinGetExportToDsc module.
.DESCRIPTION
Imports the module and forwards the supplied parameters to
Convert-WinGetExportToDsc.
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
.\Convert-WinGetExportToDsc.ps1 -InputPath D:\Git\winget\sys4ops.json -Author 'Michal'
.EXAMPLE
.\Convert-WinGetExportToDsc.ps1 -InputPath .\packages.json -Schema WinGet -ConfigurationVersion '0.2.0'
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

Import-Module -Name (Join-Path $PSScriptRoot 'WinGetExportToDsc\WinGetExportToDsc.psd1') -ErrorAction Stop
Convert-WinGetExportToDsc @PSBoundParameters
