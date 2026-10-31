# WinGetExportToDsc

PowerShell module for converting a JSON file produced by `winget export` into
a DSC v3 or WinGet DSC YAML configuration. The conversion does not install
packages or run DSC, and it does not require a YAML module.

The module supports Windows PowerShell 5.1 and PowerShell 7 (Core).

![PowerShell Gallery](https://img.shields.io/powershellgallery/v/WinGetExportToDsc.svg)
![Downloads](https://img.shields.io/powershellgallery/dt/WinGetExportToDsc)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-PowerShell%207%2B-lightgrey)


## Import or install the module

```powershell

# Import module 
Import-Module .\WinGetExportToDsc\WinGetExportToDsc.psd1

# Install module

Install-Module -Name WinGetExportToDsc

```

Convert an export to a DSC v3 configuration:

```powershell
Convert-WinGetExportToDsc -InputPath .\packages.json
```

Select the legacy WinGet DSC schema and provide an explicit destination:

```powershell
Convert-WinGetExportToDsc -InputPath .\packages.json `
    -OutputPath .\packages.winget.yaml `
    -Schema WinGet `
    -ContentVersion '0.1.0'
```

The output defaults to `<input-name>.dsc.yaml`. Existing output files are not
replaced unless `-Force` is specified. The original
`Convert-WinGetExportToDsc.ps1` script remains available as a compatibility
entry point.

## Parameters

- `InputPath` (required): Path to a JSON file produced by `winget export`,
  regardless of its extension.
- `OutputPath`: Destination YAML file. Defaults to `<input-name>.dsc.yaml`
  beside the input.
- `Author`: Author recorded in configuration metadata. Defaults to the current
  user name.
- `Description`: Description recorded in configuration metadata.
- `ContentVersion` / `ConfigurationVersion`: Version written to
  `contentVersion` for DSCv3 or `configurationVersion` for WinGet. Defaults to
  `0.1.0`.
- `Schema`: Configuration format, either `DSCv3` (default) or `WinGet`.
  Selects the schema URL, resource type, version field, and default version.
- `Force`: Allows replacement of an existing output file, but never the input
  file.

## Examples

Export installed packages using either DSC or WinGet:

```powershell

# dsc export 

dsc resource export --resource Microsoft.WinGet/Package #DSC nedd to be installed 

# Winget export 
winget export -o example-output-winget.json
```

Convert a WinGet export to the default DSCv3 YAML configuration:

```powershell
Convert-WinGetExportToDsc -InputPath D:\Git\winget\sys4ops.json -Author 'Michal'
```

Convert to the WinGet DSC schema, supplying a version through the parameter's
`ConfigurationVersion` alias:

```powershell
Convert-WinGetExportToDsc -InputPath .\packages.json `
    -Schema WinGet `
    -ConfigurationVersion '0.1.0'
```

The compatibility script can also be used directly:

```powershell
.\Convert-WinGetExportToDsc.ps1 `
    -InputPath .\example-output.json `
    -OutputPath .\packages.dsc.yaml `
    -Schema DSCv3 `
    -ContentVersion '0.1.0' `
    -Force

.\Convert-WinGetExportToDsc.ps1 `
    -InputPath .\example-output.json `
    -OutputPath .\packages.winget.yaml `
    -Schema WinGet `
    -ConfigurationVersion '0.1.0'
```

## Test and apply a configuration

Test the generated configuration before applying it. Use the command matching
the schema:

```powershell

# winget cli
winget configure test -f .\packages.winget.yaml

# dsc cli 
dsc config test -f .\packages.dsc.yaml
```

After the test succeeds, apply the configuration with the corresponding
command:

```powershell

# winget cli

winget configure -f .\packages.winget.yaml

# dsc cli 
dsc config set -f .\packages.dsc.yaml
```

Applying a configuration can install or modify packages on the system. Review
and test the configuration before applying it. The conversion command itself
only generates the YAML file and returns it as a `System.IO.FileInfo` object.
