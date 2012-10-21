#requires -version 2.0

[CmdletBinding()]
param
(
)

$script:ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$PSScriptRoot = $MyInvocation.MyCommand.Path | Split-Path

Import-Module "$PSScriptRoot\..\PoshUnit.psm1"

Test-Fixture "Output Tests" `
    -Tests `
    (
        Test "Write-Output should not be visible with -ShowOutput `$false" `
        {
            Write-Output "Write-Output"
        }
    ),
    (
        Test "Write-Debug should not be visible with -ShowOutput `$false" `
        {
            Write-Debug "Write-Debug"
        }
    ),
    (
        Test "Write-Warning should not be visible with -ShowOutput `$false" `
        {
            Write-Warning "Write-Warning"
        }
    ),
    (
        Test "Write-Error should not be visible with -ShowOutput `$false" `
        {
            Write-Error "Write-Error"
        }
    ),
    (
        Test "Write-Verbose should not be visible with -ShowOutput `$false" `
        {
            Write-Verbose "Write-Verbose"
        }
    ),
    (
        Test "Write-Host should not be visible with -ShowOutput `$false" `
        {
            Write-Host "Write-Host"
        }
    )