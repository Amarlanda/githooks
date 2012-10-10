#requires -version 2.0

[CmdletBinding()]
param
(
)

$ErrorActionPreference = "Stop";

function Commit-File
{
    param
    (
        [string] $FileContent
        [string] $FileName
        [string] $CommitMessage
    )

    $FileContent | Out-File $FileName -Encoding Ascii
    git add $FileName
    $currentBranchName = git name-rev --name-only HEAD
    $prefix = if ($currentBranchName -like "TFS*") { "" } else { "ADH" }
    git commit -m ($prefix + $CommitMessage) --quiet
}

function Make-ParentCommit
{
    Commit-File -FileContent "Parent commit" -FileName "ParentCommit.txt" -CommitMessage "Parent commit"
}


Write-Output "Installing git hooks"
Tools\GitHooks\Install-GitHooks.ps1

$localGitRepoPath = "C:\Temp\LocalGitRepo"

if (Test-Path $localGitRepoPath)
{
    Write-Output "Removing existing local git repository '$localGitRepoPath'"
    Remove-Item $localGitRepoPath -Recurse -Force
}

Write-Output "Creating local git repository '$localGitRepoPath'"
New-Item $localGitRepoPath -ItemType Directory | Out-Null
git init --bare --quiet $localGitRepoPath

$remotes = git remote

if ($remotes -contains "local")
{
    Write-Output "Removing existing git remote 'local'"
    git remote rm local
}

Write-Output "Creating git remote 'local' within '$localGitRepoPath'"
git remote add local $localGitRepoPath

Write-Output "Preparing branch test_merge_pull"
git checkout master -B test_merge_pull --quiet | Out-Null

Make-ParentCommit

"Commit which will cause pull merge" | Out-File CommitWhichWilCausePullMerge.txt -Encoding Ascii
git add CommitWhichWilCausePullMerge.txt
git commit -m "ADH Commit which will cause pull merge" --quiet

git push local test_merge_pull --set-upstream --quiet | Out-Null

git reset --hard HEAD~1 --quiet

"Another commit which will cause pull merge" | Out-File AnotherCommitWhichWilCausePullMerge.txt -Encoding Ascii
git add AnotherCommitWhichWilCausePullMerge.txt
git commit -m "ADH Another commit which will cause pull merge" --quiet

git config branch.test_merge_pull.rebase false

Write-Output "Creating branch test_merge_pull_backup"
git checkout test_merge_pull -B test_merge_pull_backup --quiet | Out-Null

Write-Output "Preparing branch test_merge_pull_conflict"
git checkout master -B test_merge_pull_conflict --quiet | Out-Null

Make-ParentCommit

"Commit which will cause pull merge conflict" | Out-File CommitWhichWilCausePullMergeConflict.txt -Encoding Ascii
git add CommitWhichWilCausePullMergeConflict.txt
git commit -m "ADH Commit which will cause pull merge conflict" --quiet

git push local test_merge_pull_conflict --set-upstream --quiet | Out-Null

git reset --hard HEAD~1 --quiet

"Another commit which will cause pull merge conflict" | Out-File CommitWhichWilCausePullMergeConflict.txt -Encoding Ascii
git add CommitWhichWilCausePullMergeConflict.txt
git commit -m "ADH Another commit which will cause pull merge conflict" --quiet

git config branch.test_merge_pull_conflict.rebase false

Write-Output "Creating branch test_merge_pull_conflict_backup"
git checkout test_merge_pull_conflict -B test_merge_pull_conflict_backup --quiet | Out-Null

Write-Output "Creating branch TFS1234"
git checkout master -B TFS1234 --quiet | Out-Null

Make-ParentCommit

Write-Output "Creating branch non_TFS_branch"
git checkout master -B non_TFS_branch --quiet | Out-Null

Write-Output "Checkout master branch"
git checkout master --quiet