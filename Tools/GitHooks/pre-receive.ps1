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
$PSScriptRoot = $MyInvocation.MyCommand.Path | Split-Path

. "$PSScriptRoot\Common.ps1"

Trap [Exception] `
{
    ProcessErrors $_
}
    
$missingRef = "0000000000000000000000000000000000000000"

if ($RefName -notlike "refs/heads/*")
{
    Write-Debug "$RefName is not a branch commit"
    ExitWithSuccess
}

$branchName = $RefName -replace "refs/heads/"

if ($OldRef -eq $missingRef)
{
    Write-Debug "$branchName is a new branch"
    ExitWithSuccess
}

$mergeCommits = git log --first-parent --merges --format=%H "$OldRef..$NewRef"
if (-not $mergeCommits)
{
    ExitWithSuccess
}

[Array]::Reverse($mergeCommits)

foreach ($mergeCommit in $mergeCommits)
{
    $firstParentCommit = git rev-parse $mergeCommit^1
    if (-not (Test-FastForward -From $OldRef -To $firstParentCommit))
    {
        $commitMessage = git log -1 $mergeCommit --format=oneline
        Write-Warning "The following commit should not exist in branch $branchName`n$commitMessage"
        ExitWithFailure
    }
}

ExitWithSuccess