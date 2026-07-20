<#
.SYNOPSIS
    Script helper para gestionar codebase-memory-mcp en el proyecto Godot.
.DESCRIPTION
    Permite re-indexar el proyecto, iniciar la interfaz gráfica 3D, consultar el estado o reparar la configuración en Devin Desktop.
#>

param (
    [Parameter(Position=0)]
    [ValidateSet("menu", "index", "ui", "status", "fix-devin")]
    [string]$Action = "menu"
)

$ErrorActionPreference = "Stop"

# Ruta del ejecutable codebase-memory-mcp
$CbmExe = "$env:LOCALAPPDATA\Programs\codebase-memory-mcp\codebase-memory-mcp.exe"
if (-not (Test-Path $CbmExe)) {
    $CbmExe = "codebase-memory-mcp"
}

$RepoPath = $PSScriptRoot

function Reindex-Project {
    Write-Host "`n[+] Indexando proyecto: $RepoPath ..." -ForegroundColor Cyan
    & $CbmExe cli index_repository --repo-path "$RepoPath" --mode fast
    Write-Host "`n[V] Indexado completado con exito.`n" -ForegroundColor Green
}

function Start-UI {
    Write-Host "`n[+] Verificando/iniciando servidor de visualizacion 3D (localhost:9749)..." -ForegroundColor Cyan
    try {
        $check = Invoke-WebRequest -Uri "http://localhost:9749" -UseBasicParsing -ErrorAction SilentlyContinue
    } catch {
        $check = $null
    }
    if (-not $check -or $check.StatusCode -ne 200) {
        Start-Process -FilePath $CbmExe -ArgumentList "--ui=true", "--port=9749" -WindowStyle Hidden
        Start-Sleep -Seconds 2
    }
    Write-Host "[V] Servidor UI activo. Abriendo http://localhost:9749 en tu navegador..." -ForegroundColor Green
    Start-Process "http://localhost:9749"
}

function Show-Status {
    Write-Host "`n[+] Proyectos indexados:" -ForegroundColor Cyan
    & $CbmExe cli list_projects
    Write-Host ""
}

function Fix-Devin {
    Write-Host "`n[+] Reparando / Vinculando MCP en Devin Desktop..." -ForegroundColor Cyan
    $devinConfigDir = "$env:USERPROFILE\.codeium\windsurf"
    $devinConfigFile = "$devinConfigDir\mcp_config.json"
    $exeBinPath = "$env:USERPROFILE\.local\bin\codebase-memory-mcp.exe"

    if (-not (Test-Path $devinConfigDir)) {
        New-Item -ItemType Directory -Path $devinConfigDir -Force | Out-Null
    }

    $configObj = @{ mcpServers = @{} }
    if (Test-Path $devinConfigFile) {
        try {
            $configObj = Get-Content $devinConfigFile -Raw | ConvertFrom-Json
        } catch {
            Write-Host "[!] Advertencia: No se pudo leer el archivo existente, creando uno nuevo." -ForegroundColor Yellow
        }
    }

    if (-not $configObj.mcpServers) {
        $configObj | Add-Member -MemberType NoteProperty -Name "mcpServers" -Value @{}
    }

    $configObj.mcpServers | Add-Member -MemberType NoteProperty -Name "codebase-memory-mcp" -Value @{ command = $exeBinPath.Replace('\', '/') } -Force

    $configObj | ConvertTo-Json -Depth 10 | Set-Content $devinConfigFile -Encoding UTF8
    Write-Host "[V] Configuracion guardada en: $devinConfigFile" -ForegroundColor Green
    Write-Host "[V] Reinicia Devin Desktop si es necesario para recargar la lista de MCPs.`n" -ForegroundColor Green
}

function Show-Menu {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "     Codebase Memory MCP Helper - Godot   " -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "Carpeta del proyecto: $RepoPath`n" -ForegroundColor Gray
    Write-Host "1) Re-indexar proyecto Godot"
    Write-Host "2) Abrir Interfaz Grafica 3D (localhost:9749)"
    Write-Host "3) Ver lista de proyectos indexados"
    Write-Host "4) Reparar / Re-vincular MCP en Devin Desktop"
    Write-Host "5) Salir`n"
    
    $choice = Read-Host "Selecciona una opcion (1-5)"
    switch ($choice) {
        "1" { Reindex-Project }
        "2" { Start-UI }
        "3" { Show-Status }
        "4" { Fix-Devin }
        "5" { exit }
        default { 
            Write-Host "Opcion invalida." -ForegroundColor Red
        }
    }
}

switch ($Action) {
    "index"     { Reindex-Project }
    "ui"        { Start-UI }
    "status"    { Show-Status }
    "fix-devin" { Fix-Devin }
    default     { Show-Menu }
}
