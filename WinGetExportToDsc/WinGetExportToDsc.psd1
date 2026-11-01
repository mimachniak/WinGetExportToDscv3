@{
    RootModule        = 'WinGetExportToDsc.psm1'
    ModuleVersion     = '1.0.1'
    GUID              = '4ac76d47-39a4-4948-aa4e-1b556ebdfe08'
    # Author of this module
    Author               = 'Michal Machniak'
    # Company or vendor of this module
    CompanyName          = 'Michal Machniak'
    # Copyright statement for this module
    Copyright            = '(c) Michal Machniak. All rights reserved.'
    Description       = 'Converts WinGet JSON exports to DSC v3 or WinGet DSC YAML configurations.'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    FunctionsToExport = @('Convert-WinGetExportToDsc')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'DSC', 'WinGet', 'Export', 'DSCV3', 'DevOps'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/mimachniak/WinGetExportToDscv3/blob/main/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/mimachniak/WinGetExportToDscv3'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '
        v.1.0.0
            - Add base function using convert-WinGetExportToDsc, to convert WinGet JSON exports to DSC v3 or WinGet DSC YAML configurations.
        v.1.0.1
            - Update module version and metadata.
        '

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable
}
