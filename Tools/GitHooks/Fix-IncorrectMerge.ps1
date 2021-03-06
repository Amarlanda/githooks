#requires -version 2.0

[CmdletBinding()]
param
(
)

$script:ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
function PSScriptRoot { $MyInvocation.ScriptName | Split-Path }

Trap { throw $_ }

function Main
{
    . "$(PSScriptRoot)\Common.ps1"

    Add-Type -AssemblyName PresentationFramework

    $hooksConfiguration = Get-HooksConfiguration

    if (Test-CommitPushed)
    {
        Write-Debug "`nCurrent commit was already pushed"
        ExitWithSuccess
    }

    $mergeInfo = Get-MergeInfo HEAD

    if (-not $mergeInfo.IsMerge)
    {
        Write-Debug "`nCurrent commit is not a merge commit"
        ExitWithSuccess
    }

    $currentBranchName = $mergeInfo.Into
    $mergedBranchName = $mergeInfo.From

    if (Test-PullMerge)
    {
        Fix-PullMerge
    }
    else
    {
        Fix-UnallowedMerge
    }
}

function Fix-PullMerge
{
    if (-not ([Convert]::ToBoolean($hooksConfiguration.Merges.fixPullMerges)))
    {
        Write-Debug "Merges/@fixPullMerges is disabled in HooksConfiguration.xml"
        return
    }

    if (Has-UnrebaseableMerges -From $mergedBranchName -Into $currentBranchName)
    {
        Write-Debug "Rebase is not allowed"
        return
    }

    Write-Host "`nCurrent merge '$currentBranchName' with '$mergedBranchName' is a pull merge"

    $xaml = [xml] @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Merge pull warning"
    Height="110"
    Width="450"
    ResizeMode="NoResize">
<Grid>
    <TextBlock HorizontalAlignment="Left"
               Margin="10,10,0,0"
               TextWrapping="Wrap"
               Text="Usage of merge pulls is a bad practice. Do you want to use rebase pull instead?"
               VerticalAlignment="Top" />
    <Button x:Name="yesButton"
            Content="Yes"
            HorizontalAlignment="Left"
            Margin="118,44,0,0"
            VerticalAlignment="Top"
            Width="100"
            IsDefault="True" />
    <Button x:Name="yesPermanentlyButton"
            Content="Yes, permanently"
            HorizontalAlignment="Left"
            Margin="223,44,0,0"
            VerticalAlignment="Top"
            Width="100" />
    <Button x:Name="noButton"
            Content="No"
            HorizontalAlignment="Left"
            Margin="328,44,0,0"
            VerticalAlignment="Top"
            Width="100"
            IsCancel="True" />
</Grid>
</Window>
"@

    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $form = [Windows.Markup.XamlReader]::Load($reader)

    $yesButton = $form.FindName("yesButton")
    $yesPermanentlyButton = $form.FindName("yesPermanentlyButton")
    $noButton = $form.FindName("noButton")

    $yesButton.add_Click(
        {
            $form.Close()
            Write-Host "`nExecuting 'git git pull --rebase'"
            git pull --rebase | Write-Host
        })

    $yesPermanentlyButton.add_Click(
        {
            $form.Close()

            Write-Host "`nExecuting 'git config branch.$currentBranchName.rebase true'"
            git config "branch.$currentBranchName.rebase" true | Write-Host

            Write-Host "`nExecuting 'git git pull --rebase'"
            git pull --rebase | Write-Host
        })

    $noButton.add_Click(
        {
            $form.Close()
            Write-HooksWarning "Pull merge commits are not recommended.`nSee wiki-url/index.php?title=Git#Pull_merges"
        })

    $form.WindowStartupLocation = "CenterScreen"
    [void] $form.ShowDialog();
}

function Fix-UnallowedMerge
{
    $mergeAllowed = Test-MergeAllowed -From $mergedBranchName -Into $currentBranchName

    if ($mergeAllowed)
    {
        Write-Debug "Merge '$mergedBranchName' into '$currentBranchName' is allowed."
        ExitWithSuccess
    }

    $xaml = [xml] @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Unallowed merge"
    Height="110"
    Width="450"
    ResizeMode="NoResize">
<Grid>
    <TextBlock HorizontalAlignment="Left"
               Margin="10,10,0,0"
               TextWrapping="Wrap"
               Text="Merge '$mergedBranchName' into '$currentBranchName' is unallowed. Do you want to revert it?"
               VerticalAlignment="Top" />
    <Button x:Name="yesButton"
            Content="Yes"
            HorizontalAlignment="Left"
            Margin="223,44,0,0"
            VerticalAlignment="Top"
            Width="100"
            IsDefault="True" />
    <Button x:Name="noButton"
            Content="No"
            HorizontalAlignment="Left"
            Margin="328,44,0,0"
            VerticalAlignment="Top"
            Width="100"
            IsCancel="True" />
</Grid>
</Window>
"@

    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $form = [Windows.Markup.XamlReader]::Load($reader)

    $yesButton = $form.FindName("yesButton")
    $noButton = $form.FindName("noButton")

    $yesButton.add_Click(
        {
            $form.Close()
            Write-Host "`nReverting merge commit by 'git reset --hard HEAD^1'"
            git reset --hard HEAD^1 | Write-Host
        })

    $noButton.add_Click(
        {
            $form.Close()
            Write-HooksWarning "Merge from '$mergedBranchName' into '$currentBranchName' is not allowed.`nSee wiki-url/index.php?title=Git#Merges"
        })

    $form.WindowStartupLocation = "CenterScreen"
    [void] $form.ShowDialog();
}

Main