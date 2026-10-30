@{
    RootModule        = 'WinGetExportToDsc.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '4ac76d47-39a4-4948-aa4e-1b556ebdfe08'
    Author            = 'WinGetExportToDsc contributors'
    Description       = 'Converts WinGet JSON exports to DSC v3 or WinGet DSC YAML configurations.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Convert-WinGetExportToDsc')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
