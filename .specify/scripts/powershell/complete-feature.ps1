#!/usr/bin/env pwsh
# complete-feature.ps1
#
# Archive a completed Spec Kit feature: validate tasks, write STATUS.md metadata,
# clear active feature.json pin, update agent context (specify-rules.mdc).
#
# Usage: complete-feature.ps1 [-FeatureDir <path>] [-SkipTasksCheck]

[CmdletBinding()]
param(
    [Parameter()]
    [string]$FeatureDir,

    [switch]$SkipTasksCheck
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

$repoRoot = Get-RepoRoot
$specifyDir = Get-SpecifyDir -RepoRoot $repoRoot
$featureJsonPath = Join-Path $specifyDir 'feature.json'

if (-not $FeatureDir) {
    if (Test-Path -LiteralPath $featureJsonPath) {
        $cfg = Get-Content -LiteralPath $featureJsonPath -Raw | ConvertFrom-Json
        if ($cfg.feature_directory) {
            $FeatureDir = $cfg.feature_directory
        }
    }
}

if (-not $FeatureDir) {
    Write-Error 'complete-feature: informe -FeatureDir ou defina feature_directory em civ2-docs/.specify/feature.json'
}

if (-not [System.IO.Path]::IsPathRooted($FeatureDir)) {
    $FeatureDir = Join-Path $repoRoot $FeatureDir
}

if (-not (Test-Path -LiteralPath $FeatureDir -PathType Container)) {
    Write-Error "complete-feature: diretório não encontrado: $FeatureDir"
}

$featureName = Split-Path -Leaf $FeatureDir
$tasksPath = Join-Path $FeatureDir 'tasks.md'
$statusPath = Join-Path $FeatureDir 'STATUS.md'
$specPath = Join-Path $FeatureDir 'spec.md'
$planPath = Join-Path $FeatureDir 'plan.md'

if (-not (Test-Path -LiteralPath $tasksPath)) {
    Write-Error "complete-feature: tasks.md não encontrado em $FeatureDir"
}

$tasksRaw = Get-Content -LiteralPath $tasksPath -Raw
$doneCount = ([regex]::Matches($tasksRaw, '(?m)^- \[X\]')).Count
$openCount = ([regex]::Matches($tasksRaw, '(?m)^- \[ \]')).Count
$totalCount = $doneCount + $openCount

if (-not $SkipTasksCheck -and $openCount -gt 0) {
    Write-Error "complete-feature: $openCount task(s) ainda aberta(s) em tasks.md ($doneCount/$totalCount concluídas)"
}

$today = Get-Date -Format 'yyyy-MM-dd'

# spec.md: Status → Completed
if (Test-Path -LiteralPath $specPath) {
    $specContent = Get-Content -LiteralPath $specPath -Raw
    $specContent = $specContent -replace '(?m)^(\*\*Status\*\*:\s*).*$', "`${1}Completed"
    [System.IO.File]::WriteAllText($specPath, $specContent, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host 'complete-feature: spec.md status -> Completed'
}

# STATUS.md — criar stub mínimo se ausente
if (-not (Test-Path -LiteralPath $statusPath)) {
    $title = $featureName
    if (Test-Path -LiteralPath $planPath) {
        $planLine = (Get-Content -LiteralPath $planPath -TotalCount 1) -replace '^#\s*Implementation Plan:\s*', ''
        if ($planLine) { $title = $planLine.Trim() }
    }
    $num = if ($featureName -match '^(\d+)') { $Matches[1] } else { '???' }
    $stub = @(
        ("# STATUS - {0} {1}" -f $num, $title),
        '',
        ("**Data**: {0}  " -f $today),
        ("**Estado**: Concluida - {0}/{1} tasks em ``tasks.md``" -f $doneCount, $totalCount),
        '',
        '## Entregue',
        '',
        '*(Preencher resumo API/client - ou executar /speckit-complete com agente para detalhar.)*',
        '',
        '## Validacao',
        '',
        '```powershell',
        '# Comandos de teste da feature',
        '```',
        ''
    ) -join "`n"
    [System.IO.File]::WriteAllText($statusPath, $stub, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host 'complete-feature: STATUS.md criado (stub - enriquecer manualmente se necessario)'
} else {
    Write-Host 'complete-feature: STATUS.md ja existe'
}

# Mover para specs/arquivados/ se ainda estiver na raiz ativa
$archivedRoot = Get-ArchivedSpecsDir -RepoRoot $repoRoot
if ($FeatureDir -notmatch '[\\/]arquivados[\\/]') {
    if (-not (Test-Path -LiteralPath $archivedRoot)) {
        New-Item -ItemType Directory -Path $archivedRoot -Force | Out-Null
    }
    $destDir = Join-Path $archivedRoot $featureName
    if (Test-Path -LiteralPath $destDir) {
        Write-Warning "complete-feature: destino ja existe, mantendo $destDir"
        $FeatureDir = $destDir
    } else {
        Move-Item -LiteralPath $FeatureDir -Destination $destDir
        $FeatureDir = $destDir
        Write-Host ('complete-feature: movido para {0}' -f (Get-RelativePath -Absolute $FeatureDir -Root $repoRoot))
    }
}

$relFeatureDir = Get-RelativePath -Absolute $FeatureDir -Root $repoRoot

# feature.json — arquivar pin ativo
$previousCompleted = $null
if (Test-Path -LiteralPath $featureJsonPath) {
    try {
        $existing = Get-Content -LiteralPath $featureJsonPath -Raw | ConvertFrom-Json
        if ($existing.last_completed -and $existing.last_completed.feature_directory) {
            $prevDir = [string]$existing.last_completed.feature_directory
            if (-not [string]::Equals($prevDir.Replace('\', '/'), $relFeatureDir, 'OrdinalIgnoreCase')) {
                $previousCompleted = $prevDir
            }
        } elseif ($existing.feature_directory -and
            -not [string]::Equals([string]$existing.feature_directory, $relFeatureDir, 'OrdinalIgnoreCase')) {
            $previousCompleted = [string]$existing.feature_directory
        }
    } catch {
        # ignore parse errors
    }
}

$newCfg = [ordered]@{
    last_completed = [ordered]@{
        feature_directory = $relFeatureDir
        completed_at      = $today
        tasks_done        = $doneCount
        tasks_total       = $totalCount
    }
}
$newJson = ($newCfg | ConvertTo-Json -Depth 4) + "`n"
[System.IO.File]::WriteAllText($featureJsonPath, $newJson, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('complete-feature: feature.json -> last_completed={0}' -f $relFeatureDir)

# specify-rules.mdc — atualizar linhas de plano ativo / última concluída / anterior
$ctxPath = Join-Path $repoRoot '.cursor/rules/specify-rules.mdc'
if (Test-Path -LiteralPath $ctxPath) {
    $rawBytes = [System.IO.File]::ReadAllBytes($ctxPath)
    if ($rawBytes.Length -ge 3 -and $rawBytes[0] -eq 0xEF -and $rawBytes[1] -eq 0xBB -and $rawBytes[2] -eq 0xBF) {
        $ctx = [System.Text.Encoding]::UTF8.GetString($rawBytes, 3, $rawBytes.Length - 3)
    } else {
        $ctx = [System.Text.Encoding]::UTF8.GetString($rawBytes)
    }

    $statusRel = "../../$relFeatureDir/STATUS.md"

    $num = if ($featureName -match '^(\d+)') { $Matches[1] } else { $featureName }
    $shortTitle = ($featureName -replace '^\d+-', '') -replace '-', ' '
    $shortTitle = (Get-Culture).TextInfo.ToTitleCase($shortTitle)
    if ($shortTitle -match '^Purchasing Crud$') { $shortTitle = 'Purchasing CRUD' }

    $prevLink = '*(nenhuma)*'
    if ($previousCompleted) {
        $prevRel = $previousCompleted.Replace('\', '/')
        if ($prevRel -match '(\d+)-([^/]+)$') {
            $prevNum = $Matches[1]
            $prevLink = "[$prevNum](../../$prevRel/STATUS.md)"
        }
    } else {
        # infer previous from feature number - 1 in same specs dir
        if ($num -match '^\d+$') {
            $prevNumInt = [int]$num - 1
            $prevNumStr = $prevNumInt.ToString('000')
            $archivedDir = Get-ArchivedSpecsDir -RepoRoot $repoRoot
            $prevDirs = @()
            if (Test-Path -LiteralPath $archivedDir) {
                $prevDirs = @(Get-ChildItem -LiteralPath $archivedDir -Directory -Filter "$prevNumStr-*" -ErrorAction SilentlyContinue)
            }
            if ($prevDirs.Count -eq 0) {
                $specsDir = Get-SpecsDir -RepoRoot $repoRoot
                $prevDirs = @(Get-ChildItem -LiteralPath $specsDir -Directory -Filter "$prevNumStr-*" -ErrorAction SilentlyContinue |
                    Where-Object { -not (Test-IsArchivedSpecsContainer $_.Name) })
            }
            if ($prevDirs.Count -eq 1) {
                $prevRel = Get-RelativePath -Absolute $prevDirs[0].FullName -Root $repoRoot
                $prevName = $prevDirs[0].Name
                $prevLabel = if ($prevName -match '^017-') { '017 Usuários e Setores Gabinete' } else { $prevNumInt.ToString() }
                $prevLink = "[$prevLabel](../../$prevRel/STATUS.md)"
            }
        }
    }

    $noneWaiting = '*(nenhum — aguardando próxima spec)*'
    $ultimaLabel = 'Última concluída'
    $planoLine = "**Plano ativo:** $noneWaiting · **${ultimaLabel}:** [$num $shortTitle]($statusRel) · **Anterior:** $prevLink"
    if ($ctx -match '(?m)^\*\*Plano ativo:\*\*.*$') {
        $ctx = [regex]::Replace($ctx, '(?m)^\*\*Plano ativo:\*\*.*$', $planoLine)
    } else {
        Write-Warning 'complete-feature: linha **Plano ativo:** não encontrada em specify-rules.mdc'
    }

    [System.IO.File]::WriteAllText($ctxPath, $ctx, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "complete-feature: specify-rules.mdc atualizado"
}

Write-Host ('complete-feature: arquivamento concluido para {0} ({1}/{2} tasks)' -f $relFeatureDir, $doneCount, $totalCount)
