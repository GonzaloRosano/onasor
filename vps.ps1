<#
  Instala o actualiza onasor-vps (gestor de servidores SSH) desde las descargas públicas de
  github.com/GonzaloRosano/onasor. No necesita cuenta de GitHub ni permisos de
  administrador.

  Uso:
    irm https://raw.githubusercontent.com/GonzaloRosano/onasor/main/vps.ps1 | iex

  Con opciones (versión puntual, otra carpeta, sin tocar el PATH):
    & ([scriptblock]::Create((irm https://raw.githubusercontent.com/GonzaloRosano/onasor/main/vps.ps1))) -Version v1.4.0 -Dir C:\herramientas -NoPath
#>
param(
    [string]$Version = "",
    [string]$Dir = "",
    [switch]$NoPath
)

$Repo = "GonzaloRosano/onasor"
$Tool = "onasor-vps"
$Prefix = "vps-v"
$VersionArgs = @("version")

# Continue y errores explícitos: en PowerShell 5.1, Stop vuelve fatal cualquier
# salida a stderr; y throw (no exit) para no cerrar la terminal al correr con iex
$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"   # la barra de progreso hace lentísimo Invoke-WebRequest en 5.1
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

function Fail($msg) {
    Write-Host "x $msg" -ForegroundColor Red
    throw "instalación cancelada"
}

# 1. Release a instalar: el último de esta herramienta, o el pedido
$headers = @{ "User-Agent" = "onasor-installer"; "Accept" = "application/vnd.github+json" }
try {
    $releases = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases?per_page=100" -Headers $headers -ErrorAction Stop
} catch {
    Fail "no pude consultar las descargas de $Repo ($($_.Exception.Message))"
}
$want = if ($Version) { $Prefix + $Version.TrimStart("v") } else { "" }
$release = $releases | Where-Object { -not $_.draft -and -not $_.prerelease -and $_.tag_name -like "$Prefix*" -and (-not $want -or $_.tag_name -eq $want) } | Select-Object -First 1
if (-not $release) { Fail "no encontré un release de $Tool $(if ($Version) { $Version })" }

# 2. Ejecutable para esta arquitectura
$arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "amd64" }
$assetName = "$Tool-windows-$arch.exe"
$asset = $release.assets | Where-Object { $_.name -eq $assetName }
$sums = $release.assets | Where-Object { $_.name -eq "SHA256SUMS" }
if (-not $asset -or -not $sums) { Fail "el release $($release.tag_name) no tiene $assetName" }

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("$Tool-install-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tmp -ErrorAction Stop | Out-Null
try {
    Write-Host "> descargando $Tool $($release.tag_name.Substring($Prefix.Length - 1))..."
    $exe = Join-Path $tmp $assetName
    try {
        Invoke-WebRequest $asset.browser_download_url -OutFile $exe -UseBasicParsing -Headers $headers -ErrorAction Stop
        $sumText = (Invoke-WebRequest $sums.browser_download_url -UseBasicParsing -Headers $headers -ErrorAction Stop).Content
    } catch {
        Fail "falló la descarga ($($_.Exception.Message))"
    }
    if ($sumText -is [byte[]]) { $sumText = [Text.Encoding]::ASCII.GetString($sumText) }

    # 3. Verificar el SHA-256 contra SHA256SUMS del mismo release
    $line = ($sumText -split "`n") | Where-Object { $_ -match ([regex]::Escape($assetName) + '\s*$') } | Select-Object -First 1
    $expected = if ($line) { ($line -split '\s+')[0].ToLower() } else { "" }
    $actual = (Get-FileHash $exe -Algorithm SHA256).Hash.ToLower()
    if (-not $expected -or $expected -ne $actual) { Fail "el SHA-256 no coincide: descarga corrupta o alterada" }

    # 4. Instalar (si está abierto, Windows no deja reemplazarlo)
    if (-not $Dir) { $Dir = Join-Path $env:LOCALAPPDATA "Programs\$Tool" }
    New-Item -ItemType Directory -Path $Dir -Force -ErrorAction Stop | Out-Null
    $dest = Join-Path $Dir "$Tool.exe"
    try {
        Copy-Item $exe $dest -Force -ErrorAction Stop
    } catch {
        Fail "no pude reemplazar $dest; cerrá $Tool y volvé a correr el instalador"
    }
} finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

# 5. PATH del usuario
if (-not $NoPath) {
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $parts = @($userPath -split ';' | Where-Object { $_ })
    if ($parts -notcontains $Dir) {
        [Environment]::SetEnvironmentVariable("Path", (($parts + $Dir) -join ';'), "User")
        $env:Path = "$env:Path;$Dir"
        Write-Host "> agregado al PATH: $Dir (abrí una terminal nueva para usarlo en otras ventanas)"
    }
}

$installed = & $dest @VersionArgs
Write-Host "v $installed instalado en $dest" -ForegroundColor Green
Write-Host "  para actualizar, volvé a correr el mismo comando"
