#requires -version 2.0

[CmdletBinding()]
param
(
    [string] $NewBaseCommit,
    [string] $RebasingBranchName
)

$script:ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
function PSScriptRoot { $MyInvocation.ScriptName | Split-Path }

. "$(PSScriptRoot)\Common.ps1"

$ErrorActionPreference = "Stop"

if ([Convert]::ToBoolean((Get-HooksConfiguration).Rebases.allowRebasePushedBranches))
{
    Write-Debug "Rebases/@allowRebasePushedBranches is enabled in HooksConfiguration.xml"
    ExitWithSuccess
}

if (-not $RebasingBranchName)
{
    $RebasingBranchName = Get-CurrentBranchName
}

if (Test-BranchPushed)
{
    $remoteBranchName = Get-TrackedBranchName $RebasingBranchName

    if ((Test-FastForward -From $remoteBranchName -To $NewBaseCommit))
    {
        Write-Debug "Rebase '$RebasingBranchName' with descendant of '$remoteBranchName' detected"
        ExitWithSuccess
    }

    Write-HooksWarning "You cannot rebase branch '$RebasingBranchName' because it was already pushed"
    ExitWithFailure
}
else
{
    Write-Debug "Branch '$RebasingBranchName' was not pushed. Rebase allowed."
    ExitWithSuccess
}