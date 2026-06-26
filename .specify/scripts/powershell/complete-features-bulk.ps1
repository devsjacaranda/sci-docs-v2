#!/usr/bin/env pwsh
# complete-features-bulk.ps1
# Arquiva retroativamente um intervalo de specs (spec.md Completed + STATUS.md stub).

[CmdletBinding()]
param(
    [Parameter()]
    [string[]]$FeatureDirs,

    [string]$ArchiveDate = (Get-Date -Format 'yyyy-MM-dd')
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/common.ps1"

function Get-RelativePath {
    param([string]$Absolute, [string]$Root)
    $abs = [System.IO.Path]::GetFullPath($Absolute)
    $root = [System.IO.Path]::GetFullPath($Root)
    if (-not $root.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $root += [System.IO.Path]::DirectorySeparatorChar
    }
    $uriAbs = New-Object System.Uri($abs)
    $uriRoot = New-Object System.Uri($root)
    return [System.Uri]::UnescapeDataString($uriRoot.MakeRelativeUri($uriAbs).ToString()).Replace('\', '/')
}

function Read-Utf8 {
    param([string]$Path)
    $rawBytes = [System.IO.File]::ReadAllBytes($Path)
    if ($rawBytes.Length -ge 3 -and $rawBytes[0] -eq 0xEF -and $rawBytes[1] -eq 0xBB -and $rawBytes[2] -eq 0xBF) {
        return [System.Text.Encoding]::UTF8.GetString($rawBytes, 3, $rawBytes.Length - 3)
    }
    return [System.Text.Encoding]::UTF8.GetString($rawBytes)
}

function Write-Utf8 {
    param([string]$Path, [string]$Content)
    [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

function Get-FeatureTitle {
    param([string]$FeatureDir)
    $specPath = Join-Path $FeatureDir 'spec.md'
    if (Test-Path -LiteralPath $specPath) {
        $line = (Read-Utf8 $specPath) -split "`n" | Select-Object -First 1
        if ($line -match '^#\s*Feature Specification:\s*(.+)$') {
            return $Matches[1].Trim()
        }
    }
    $planPath = Join-Path $FeatureDir 'plan.md'
    if (Test-Path -LiteralPath $planPath) {
        $line = (Read-Utf8 $planPath) -split "`n" | Select-Object -First 1
        if ($line -match '^#\s*Implementation Plan:\s*(.+)$') {
            return $Matches[1].Trim()
        }
    }
    return (Split-Path -Leaf $FeatureDir)
}

function Get-TaskCounts {
    param([string]$FeatureDir)
    $tasksPath = Join-Path $FeatureDir 'tasks.md'
    if (-not (Test-Path -LiteralPath $tasksPath)) {
        return @{ Done = 0; Open = 0; Total = 0; HasTasks = $false }
    }
    $raw = Read-Utf8 $tasksPath
    $done = ([regex]::Matches($raw, '(?m)^- \[X\]')).Count
    $open = ([regex]::Matches($raw, '(?m)^- \[ \]')).Count
    return @{ Done = $done; Open = $open; Total = ($done + $open); HasTasks = $true }
}

$repoRoot = Get-RepoRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
$results = @()

foreach ($dir in $FeatureDirs) {
    if (-not [System.IO.Path]::IsPathRooted($dir)) {
        $dir = Join-Path $repoRoot $dir
    }
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
        Write-Warning "SKIP: diretorio nao encontrado: $dir"
        continue
    }

    $name = Split-Path -Leaf $dir
    $num = if ($name -match '^(\d+)') { $Matches[1] } else { '???' }
    $title = Get-FeatureTitle -FeatureDir $dir
    $counts = Get-TaskCounts -FeatureDir $dir
    $specPath = Join-Path $dir 'spec.md'
    $statusPath = Join-Path $dir 'STATUS.md'

    if (Test-Path -LiteralPath $specPath) {
        $specContent = Read-Utf8 $specPath
        $specContent = $specContent -replace '(?m)^(\*\*Status\*\*:\s*).*$', '${1}Completed'
        Write-Utf8 $specPath $specContent
    }

    if (-not (Test-Path -LiteralPath $statusPath)) {
        $stateLine = if ($counts.HasTasks) {
            if ($counts.Open -eq 0) {
                ('Concluida - {0}/{1} tasks em ``tasks.md``' -f $counts.Done, $counts.Total)
            } else {
                ('Arquivada retroativamente - {0}/{1} tasks [X], {2} aberta(s) como divida historica' -f $counts.Done, $counts.Total, $counts.Open)
            }
        } else {
            'Arquivada retroativamente - spec sem tasks.md (entrega historica pre-Spec Kit)'
        }

        $note = if ($counts.Open -gt 0) {
            @(
                '',
                '## Notas',
                '',
                ('- Arquivada retroativamente em {0} via /speckit-complete.' -f $ArchiveDate),
                ('- {0} task(s) permanecem abertas em tasks.md - entrega considerada historica.' -f $counts.Open),
                ''
            ) -join "`n"
        } else {
            @(
                '',
                '## Notas',
                '',
                ('- Arquivada retroativamente em {0} via /speckit-complete.' -f $ArchiveDate),
                ''
            ) -join "`n"
        }

        $body = @(
            "# STATUS - $num $title",
            '',
            "**Data**: $ArchiveDate  ",
            "**Estado**: $stateLine",
            '',
            '## Entregue',
            '',
            'Entrega historica do monorepo CI v2. Consulte spec.md, plan.md e codigo nos modulos correspondentes.',
            '',
            '## Validacao',
            '',
            '```powershell',
            '# Ver quickstart.md desta spec, se existir',
            '```',
            $note
        ) -join "`n"
        Write-Utf8 $statusPath $body
        $statusAction = 'criado'
    } else {
        $statusAction = 'existente'
        if (Test-Path -LiteralPath $specPath) {
            # ensure spec completed even if status exists
        }
    }

    $results += [pscustomobject]@{
        Spec = $name
        StatusFile = $statusAction
        TasksDone = $counts.Done
        TasksOpen = $counts.Open
    }
    Write-Host "bulk-complete: $name ($statusAction) open=$($counts.Open)"
}

$results | Format-Table -AutoSize
Write-Host ('bulk-complete: {0} specs processadas' -f $results.Count)
