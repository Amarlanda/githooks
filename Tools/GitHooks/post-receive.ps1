#requires -version 2.0

[CmdletBinding()]
param
(
    [string] $OldRef,
    [string] $NewRef,
    [string] $RefName
)

$script:ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
function PSScriptRoot { $MyInvocation.ScriptName | Split-Path }
Trap { throw $_ }

. "$(PSScriptRoot)\Common.ps1"

if ($RefName -notlike "refs/heads/*")
{
    Write-Debug "$RefName is not a branch commit"
    ExitWithSuccess
}

$branchName = $RefName -replace "refs/heads/"

$nextBranch = Get-NextBranchName $branchName

if ($nextBranch -ne $null)
{
    Write-HooksWarning "You pushed branch '$branchName'. Please merge it to the branch '$nextBranch' and push it as well ASAP.`nSee wiki-url/index.php?title=Git#Unmerged_changes"
}