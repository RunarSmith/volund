# Télécharge et installe Meslo Nerd Font pour l'utilisateur courant
# Pas besoin de droits administrateur

$ErrorActionPreference = "Stop"

# 1. Définir URL API GitHub pour la dernière release
$repo = "ryanoasis/nerd-fonts"
$assetPattern = "Meslo.zip"
$apiUrl = "https://api.github.com/repos/$repo/releases/latest"

Write-Output ">>> Récupération de la dernière release Nerd Fonts..."

# 2. Récupérer la dernière release via API GitHub
$release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" }

$asset = $release.assets | Where-Object { $_.name -match $assetPattern } | Select-Object -First 1
if (-not $asset) {
    throw "Impossible de trouver l'asset correspondant à Meslo.zip dans la release."
}

$downloadUrl = $asset.browser_download_url
Write-Output ">>> Téléchargement : $downloadUrl"

# 3. Préparer dossier temporaire
$tempPath = Join-Path $env:TEMP "MesloNerdFont.zip"
$extractPath = Join-Path $env:TEMP "MesloNerdFont"

#Invoke-WebRequest -Uri $downloadUrl -OutFile $tempPath
Start-BitsTransfer -Source $downloadUrl -Destination $tempPath

if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
Expand-Archive -Path $tempPath -DestinationPath $extractPath

# 4. Préparer dossier fonts utilisateur
$fontsUser = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
if (-not (Test-Path $fontsUser)) { New-Item -ItemType Directory -Path $fontsUser | Out-Null }

# 5. Installer les polices dans le profil utilisateur
$fonts = Get-ChildItem -Path $extractPath -Include *.ttf, *.otf -Recurse
foreach ($font in $fonts) {
    $targetPath = Join-Path $fontsUser $font.Name
    try {
      Copy-Item $font.FullName -Destination $targetPath -Force
    } catch {
      Write-Output "!!! Erreur lors de la copie de $($font.Name) : $_"
    }


    # Extraire le nom "FriendlyName" de la font
    try {
        Add-Type -AssemblyName PresentationCore
        $glyphTypeface = New-Object Windows.Media.GlyphTypeface($targetPath)
        $fontName = $glyphTypeface.Win32FamilyNames.Values | Select-Object -First 1
    } catch {
        $fontName = [System.IO.Path]::GetFileNameWithoutExtension($font.Name)
    }

    # Enregistrer dans la registry utilisateur
    $regPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    $regName = "$fontName (TrueType)"
    Set-ItemProperty -Path $regPath -Name $regName -Value $font.Name
    Write-Output ">>> Installée : $fontName"
}

Write-Output ">>> Installation terminée. Un redémarrage ou une reconnexion peut être nécessaire."
