<#
Portable JDK setup script for Windows (PowerShell)

Este script intenta:
 - detectar si ya existe `java` en PATH,
 - buscar el JDK/JBR incluido en instalaciones de IntelliJ/JetBrains,
 - si no encuentra, opcionalmente descargar un JDK (Eclipse Temurin 17) y extraerlo en `.jdk/` dentro del repo,
 - establecer variables de entorno para la sesión actual (JAVA_HOME, PATH) y opcionalmente ejecutar un JAR.

Uso:
  - Ejecuta en PowerShell desde la raíz del proyecto:
      .\tools\setup-jdk.ps1
  - Para forzar la descarga de un JDK desde URL:
      .\tools\setup-jdk.ps1 -JdkUrl "https://.../OpenJDK17U-jdk_x64_windows_hotspot.zip"
  - Para usar específicamente IntelliJ JBR si existe:
      .\tools\setup-jdk.ps1 -UseIntelliJ
  - Para ejecutar el JAR luego de configurar el JDK:
      .\tools\setup-jdk.ps1 -JarToRun "target\ong-email-service-0.0.1-SNAPSHOT.jar"
#>

param(
    [string]$JdkUrl = "",
    [string]$Dest = ".jdk",
    [switch]$Force,
    [switch]$UseIntelliJ,
    [string]$JarToRun = ""
)

function Test-JavaInstalled {
    try {
        $proc = Start-Process -FilePath java -ArgumentList '-version' -NoNewWindow -RedirectStandardError -PassThru -ErrorAction Stop
        $proc.WaitForExit()
        return $true
    } catch {
        return $false
    }
}

function Find-IntelliJJBR {
    $candidates = @()
    $searchRoots = @()
    if ($env:LOCALAPPDATA) { $searchRoots += Join-Path $env:LOCALAPPDATA "JetBrains" }
    $searchRoots += 'C:\Program Files\JetBrains', 'C:\Program Files (x86)\JetBrains', (Join-Path $env:PROGRAMFILES 'JetBrains')

    foreach ($root in $searchRoots) {
        if (-not (Test-Path $root)) { continue }
        try {
            $dirs = Get-ChildItem -Path $root -Directory -Recurse -ErrorAction SilentlyContinue
            foreach ($d in $dirs) {
                if (Test-Path (Join-Path $d.FullName 'bin\java.exe')) {
                    return $d.FullName
                }
            }
        } catch {
            # ignore
        }
    }
    return $null
}

function Download-And-Extract-JDK($url, $destination) {
    Write-Host "Descargando JDK desde: $url"
    $zip = "jdk-temp.zip"
    try {
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Error "Fallo la descarga: $_. Exception.Message"
        return $null
    }

    if (Test-Path $destination -and -not $Force) {
        Write-Host "La carpeta $destination ya existe. Usa -Force para sobreescribir." -ForegroundColor Yellow
    }

    try {
        if (Test-Path $destination -and $Force) { Remove-Item -Recurse -Force $destination }
        Expand-Archive -Path $zip -DestinationPath $destination -Force
        Remove-Item $zip -Force
    } catch {
        Write-Error "Error extrayendo el zip: $_"
        return $null
    }

    # Buscar carpeta que contenga bin\java.exe
    $jdkRoot = Get-ChildItem -Path $destination -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'bin\java.exe') } | Select-Object -First 1
    if ($jdkRoot) { return $jdkRoot.FullName }

    # En algunos paquetes la extracción deja la estructura directamente
    if (Test-Path (Join-Path $destination 'bin\java.exe')) { return (Resolve-Path $destination).Path }

    return $null
}

Write-Host "== Setup JDK portable (carpeta: $Dest) ==" -ForegroundColor Cyan

if (Test-JavaInstalled) {
    Write-Host "Java ya está instalado en PATH. Puedes ejecutar 'java -version' para confirmar." -ForegroundColor Green
    & java -version
    if ($JarToRun) {
        Write-Host "Ejecutando JAR con java del sistema: $JarToRun"
        & java -jar $JarToRun
    }
    return
}

if ($UseIntelliJ) {
    Write-Host "Buscando JBR en instalaciones de IntelliJ..."
    $jbr = Find-IntelliJJBR
    if ($jbr) {
        $javaBin = Join-Path $jbr 'bin'
        $env:JAVA_HOME = $jbr
        $env:Path = "$javaBin;$env:Path"
        Write-Host "Encontrado JBR en: $jbr" -ForegroundColor Green
        & (Join-Path $javaBin 'java.exe') -version
        if ($JarToRun) { & (Join-Path $javaBin 'java.exe') -jar $JarToRun }
        return
    } else {
        Write-Host "No se encontró JBR de IntelliJ." -ForegroundColor Yellow
    }
}

# intentar buscar JBR automáticamente si no se indicó explícitamente
$jbrAuto = Find-IntelliJJBR
if ($jbrAuto) {
    Write-Host "JBR encontrado automáticamente en: $jbrAuto" -ForegroundColor Green
    $env:JAVA_HOME = $jbrAuto
    $env:Path = "$(Join-Path $jbrAuto 'bin');$env:Path"
    & (Join-Path $jbrAuto 'bin\java.exe') -version
    if ($JarToRun) { & (Join-Path $jbrAuto 'bin\java.exe') -jar $JarToRun }
    return
}

# Si llegamos aquí, no hay java ni JBR encontrado.
if ([string]::IsNullOrWhiteSpace($JdkUrl)) {
    $answer = Read-Host "No se detectó Java ni JBR. ¿Deseas descargar Temurin JDK 17 (Windows x64) automáticamente? (s/n)"
    if ($answer -ne 's' -and $answer -ne 'S') {
        Write-Host "Operación cancelada. Puedes descargar un JDK manualmente y volver a ejecutar este script con -JdkUrl o usar -UseIntelliJ si tienes IntelliJ instalado." -ForegroundColor Yellow
        return
    }
    # URL de la API de Adoptium para descargar el binario (redirección al archivo real)
    $JdkUrl = 'https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/adoptium'
}

# Crear carpeta destino si no existe
if (-not (Test-Path $Dest)) { New-Item -ItemType Directory -Path $Dest | Out-Null }

$jdkHome = Download-And-Extract-JDK -url $JdkUrl -destination $Dest
if (-not $jdkHome) {
    Write-Error "No se pudo descargar/extractar el JDK. Intenta descargar manualmente y usa -JdkUrl o configura JAVA_HOME en tu sistema." ; return
}

# Establecer variables de entorno para la sesión actual
$env:JAVA_HOME = $jdkHome
$binPath = Join-Path $jdkHome 'bin'
$env:Path = "$binPath;$env:Path"

Write-Host "JDK preparado en: $jdkHome" -ForegroundColor Green
& (Join-Path $binPath 'java.exe') -version

if ($JarToRun) {
    $jarPath = Resolve-Path $JarToRun -ErrorAction SilentlyContinue
    if (-not $jarPath) { Write-Error "No se encontró el JAR: $JarToRun"; return }
    Write-Host "Ejecutando JAR con JDK portable: $jarPath"
    & (Join-Path $binPath 'java.exe') -jar $jarPath
}

Write-Host "
Para usar este JDK en la sesión actual, las variables JAVA_HOME y PATH han sido actualizadas temporalmente.
Si quieres que estén disponibles permanentemente, exporta JAVA_HOME en tu perfil o en variables de entorno del sistema." -ForegroundColor Cyan

