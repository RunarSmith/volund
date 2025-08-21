[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Command,

    [string]$Container,
    [string]$Image,
    [string]$Role = "base",

    [string]$Volume,
    [string]$Version = "0.0.1",
    [string]$VpnConfig = $null,

    # source distribution
[ValidateSet( "arch", "blackarch", "debian", "fedora", "kali", "parrot" )]
    [string]$Distribution = "debian",

    # Create a container with Gui feature
    [switch]$WithGui,

    # when removing a container, also remove its workspace folder
    [switch]$WithWorkspace,

    # when starting a container, open the workspace in VSCode
    [switch]$OpenWorkspace
)

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

# === Trace / Log =========================================

$global:TraceDebug = $false
$global:TraceExec = $false

function LogError {
    param (
        [Parameter(Mandatory=$true)]
        [String]$text
    )
    Write-Host -ForegroundColor Red ("❌ {0}" -f $text)
}

function LogWarn {
    param (
        [Parameter(Mandatory=$true)]
        [String]$text
    )
    Write-Host -ForegroundColor Yellow ("⚠️ {0}" -f $text)
}

function LogInfo {
    param (
        [Parameter(Mandatory=$true)]
        [String]$text
    )
    Write-Host -ForegroundColor Cyan ("ℹ️ {0}" -f $text)
}

function LogSuccess {
    param (
        [Parameter(Mandatory=$true)]
        [String]$text
    )
    Write-Host -ForegroundColor Green ("✅ {0}" -f $text)
}

function LogExec {
    param (
        [Parameter(Mandatory=$true)]
        [String]$text
    )
    
    if ($TraceExec -eq $true ) {
        Write-Host -ForegroundColor DarkGray ("⚙️ {0}" -f $text)
    }
}

function LogDbg {
    param (
        [Parameter(Mandatory=$true)]
        [String]$text
    )
    if ($TraceDebug -eq $true ) {
        Write-Host -ForegroundColor DarkMagenta ("🪳 {0}" -f $text)
    }
}

# === Console =============================================

function Show-RichTable {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Object[]] $InputObject,

        [ConsoleColor] $HeaderColor = 'Cyan',
        [ConsoleColor] $BorderColor = 'DarkGray',
        [ConsoleColor] $RowColor = 'White'
    )

    begin {
        $rows = @()
    }
    process {
        $rows += $_
    }
    end {
        if (-not $rows) { return }

        # Récupère les propriétés à afficher
        $props = $rows[0].PSObject.Properties.Name

        # Calcule la largeur max pour chaque colonne
        $colWidths = @{}
        $props | foreach-object {
            $p = $_
            $maxLen = ($rows | ForEach-Object { "$($_.$p)" }).ForEach({ $_.Length }) | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
            $colWidths[$p] = [Math]::Max($maxLen, $p.Length)
        }

        # Construit les lignes horizontales
        $hLineTop    = "+" + (($props | ForEach-Object { "-" * ($colWidths[$_] + 2) }) -join "+") + "+"
        $hLineHeader = "+" + (($props | ForEach-Object { "=" * ($colWidths[$_] + 2) }) -join "+") + "+"
        $hLineBottom = $hLineTop

        # Affiche top border
        Write-Host $hLineTop -ForegroundColor $BorderColor

        # Affiche l’en-tête
        Write-Host -NoNewLine -ForegroundColor $BorderColor "|"
        $props | foreach-object {
            $p = $_
            Write-Host -NoNewLine " "
            Write-Host -NoNewLine -ForegroundColor $HeaderColor $p.PadRight($colWidths[$p])
            Write-Host -NoNewLine -ForegroundColor $BorderColor " |"
        }
        Write-Host ""

        # Ligne de séparation en dessous de l’en-tête
        Write-Host $hLineHeader -ForegroundColor $BorderColor

        # Affiche les données
        $rows | foreach-object {
            $row = $_
            Write-Host -NoNewLine -ForegroundColor $BorderColor "|"
            $props | foreach-object {
                $p = $_
                $value = if ($null -eq $row.$p) { "" } else { "$($row.$p)" }
                Write-Host -NoNewLine " " 
                Write-Host -NoNewLine -ForegroundColor $RowColor $value.PadRight($colWidths[$p])
                
                Write-Host -NoNewLine -ForegroundColor $BorderColor " |"
            }
             Write-Host "" 
        }

        # Ligne de bas
        Write-Host $hLineBottom -ForegroundColor $BorderColor
    }
}

# === Configuration =======================================

class Configuration {
    [hashtable]$UserConfig = @{}
    [hashtable]$Defaults = @{
            "debug" = $false
            "debugexecs" = $false
            "Driver" = "podman"

            "podman" = @{
                "init" = @{
                    "command" = "podman machine init --rootful=false --user-mode-networking=true"
                }
            }

            "base_image" = @{
                "arch"      = "docker.io/archlinux/archlinux:latest"
                "blackarch" = "docker.io/blackarchlinux/blackarch:latest"
                "debian"    = "docker.io/debian:latest"
                "fedora"    = "docker.io/fedora:latest"
                "kali"      = "docker.io/kalilinux/kali-rolling"
                "parrot"    = "docker.io/parrotsec/security:latest"
            }

            "templateDir" = "${ScriptRoot}\buildfiles"
            "containerfile" = "Containerfile"

            # default container shell
            "shell" = "bash"

            "labelImages" = "volund"
            "labelContainers" = "volund"
            "labelVolumes" = "volund"

            "buildOpts" = "" # "--tls-verify=false"
            "pullOpts" = "--log-level debug"  # "--tls-verify=false"

            "sharedResourcesVolume" = @{
                "name"      = "sharedResources"
                "mountPath" = "/opt/resources"
                "hostPath"  = "${ScriptRoot}\resources"
            }
            "myResourcesVolume" = @{
                "name"      = "myresources"
                "mountPath" = "/opt/my-resources"
                "hostPath"  = "${env:USERPROFILE}\volund\my-resources"
            }
            "workspaceVolume" = @{
                "name"      = "workspace"
                "mountPath" = "/workspace"
                "hostPath"  = "${env:USERPROFILE}\volund\workspaces"
            }
        }

    [void] LoadFromJson([string]$path) {
        if (Test-Path $path) {
            try {
                $json = Get-Content $path -Raw | ConvertFrom-Json
                $this.UserConfig = @{}
                foreach ($property in $json.PSObject.Properties) {
                    $this.UserConfig[$property.Name] = $property.Value
                }
            } catch {
                throw "Erreur lors du chargement du fichier de configuration JSON : $_"
            }
        } else {
            LogInfo ("Config file {0} is not found. keeping defaults values" -f $path)
        }
    }

    [void]WriteUserConfig([string]$path) {
        try {
            $json = $this.Defaults | ConvertTo-Json -Depth 10
            # create folders if missing
            New-Item -ItemType Directory -Path (Split-Path -parent $path) -Force | Out-Null
            Set-Content -Path $path -Value $json -Force
            LogSuccess ("Configuration saved to {0}" -f $path)
        } catch {
            LogError ("Failed to write configuration to {0}: {1}" -f $path, $_.Exception.Message)
        }
    }

    [object] Get([string]$key) {
        $res = $null
        if ($this.UserConfig.ContainsKey($key)) {
            $res = $this.UserConfig[$key]
        } elseif ($this.Defaults.ContainsKey($key)) {
            $res = $this.Defaults[$key]
        }
        if($res) {
            if ($res.getType().Name -eq "String") {
                LogDbg ("Configuration::Get() config string value : key:{0} -> value:{1}" -f $key,$res )
            } else {
                LogDbg ("Configuration::Get() config value : key:{0} -> value:{1}" -f $key,($res | out-String ) )
            }
        } else {
            LogDbg ("Configuration::Get() config string value : key:{0} -> NOT FOUND" -f $key )
        }
        return $res
    }

}

# =========================================================
# = External Command Helper to execute system commands
# =========================================================

class ExternalCommandHelper {
    static [int] RunCommandInteractive([string]$command, [string[]]$cmdArgs) {

        # remove empty args, as it will cause Start-Process to fail
        $cmdArgsF = $cmdArgs | Where-Object { $_ -ne "" }

        LogDbg ("> ExternalCommandHelper::RunCommandInteractive")
        LogExec( ( "{0} {1}" -f $command,($cmdArgsF -join " ")))
        $proc = Start-Process -FilePath "$command" -ArgumentList $cmdArgsF -NoNewWindow -PassThru -Wait
        if ($proc.ExitCode -ne 0) {
            LogError "Erreur lors de l'exécution de $command (code $($proc.ExitCode))"
        }
        LogDbg ("ExternalCommandHelper::RunCommandInteractive ExitCode: {0}" -f $proc.ExitCode)
        return $proc.ExitCode
    }

    static [string] ExecCommand([string]$command) {

        LogDbg ("> ExternalCommandHelper::ExecCommand")        
        try {
            LogExec( $command )
            $rslt = Invoke-Expression -Command "$command 2>&1"
            if ($rslt -and ($rslt.Count -gt 0)) {
                LogDbg("$rslt")
            }
            if ($rslt -like "Error:*") {
                throw "$rslt"
            }
            return $rslt
        } catch {
            LogError( "command: " + $command )
            LogError( $_.Exception.Message -join " ### " )
        }
        return $null

    }
}

# =========================================================
# = Podman Driver Implementation
# =========================================================

class ContainerDriver {
    
    [Configuration]$Config

    ContainerDriver([Configuration]$config) {
        $this.Config = $config
        LogDbg ("> ContainerDriver::ContainerDriver() - config: {0}" -f ($this.Config | out-string))
    }

    [string] IsRunning() {
        LogDbg("> ContainerDriver::IsRunning()")
        try {
            [ExternalCommandHelper]::ExecCommand("podman --version")
        } catch {
            LogError "Podman n'est pas installé ou introuvable dans le PATH."
            return $null
        }

        # test running status of the podman machine
        try {
            $status = [ExternalCommandHelper]::ExecCommand("podman machine inspect --format '{{.State}}'")
            LogDbg("< ContainerDriver::IsRunning() - $status")
            return $status #-eq "running"
        } catch {
            LogError "Podman not responding to inspect"
            return $null
        }

        return $null
    }

    [void] Start() {
        LogDbg "> ContainerDriver::Start()"

        #if ( $this.isRunning() -eq "running") { 
        #    LogSuccess "podman is already running"
        #    return
        #}

        # Start Podman service if not running
        #try {
            # Linux
            # podman system service --time=0 --log-level=error --no-headers &

            # on Windows, podman is managed via WSL
            #Write-host "wsl image need to be restarted to take updated DNS config"
        #    LogInfo( "Restarting Podman WSL images to ensure proper configuration")
        #    [ExternalCommandHelper]::ExecCommand("wsl --terminate podman-machine-default")
        #    [ExternalCommandHelper]::ExecCommand("wsl --terminate podman-net-usermode")
        #    [ExternalCommandHelper]::ExecCommand("wsl --shutdown")
        #} catch {
        #    LogWarn "Problème d'arrêt des images WSL."
            # exit 1
        #}

        try {
            # initialise / create the VM
            #if ($this.config.get("podman").init.command) {
            #    LogInfo( "Initializing Podman WSL image")
            #    [ExternalCommandHelper]::ExecCommand($this.config.get("podman").init.command + " ; echo OK")
            #} else {
            #    LogInfo( "Initializing Podman WSL image with default command")
            #    [ExternalCommandHelper]::ExecCommand("podman machine init  ; echo OK")
            #}
            podman machine init --rootful=false --user-mode-networking=true
        } catch {
            LogWarn "Problème d'init de Podman."
            #exit 1
        }

        try {
            LogInfo( "start podman")
            [ExternalCommandHelper]::ExecCommand("podman machine start")
        } catch {
            LogError "Impossible de démarrer le service Podman."
            exit 1
        }
       LogSuccess "Podman service started successfully."
       LogDbg "< ContainerDriver::Start()"
    }

    [void] Stop() {
        LogDbg "> ContainerDriver::Stop()"
        try {
            [ExternalCommandHelper]::ExecCommand("podman machine stop")
        } catch {
            LogWarn ("Podman machine already stopped or failed to stop.")
        }
        LogDbg "< ContainerDriver::Stop()"
    }

    [string] BuildImage( [string]$buildPath, [hashtable]$params) {
        $imageName  = $params.Name
        $imageVersion = $params.Version
        $buildOpts  = $params.BuildOpts
        $baseDistrib = $params.Distribution
        $labels     = $params.Labels
        $envs       = $params.Envs
        $volumes    = $params.Volumes
        $buildDir   = $params.BuildDir
        $buildFile  = $params.BuildFile
        
        LogDbg "> ContainerDriver::BuildImage()"

        $imageNameTag = $imageName + ":" + $imageVersion

        if (-not $imageName) {
            LogError "Image name is required."
            return $null
        }

        $command = "build --rm --no-cache"
        if ($buildOpts -and $buildOpts -ne "" ) {
            $command += " " + $buildOpts
        }
        $command += " --build-arg BASE_IMAGE=" + $baseDistrib
        $labels.Keys | ForEach-Object {
            $command += ( " --label {0}={1}" -f $_, $labels[$_] )
        }
        $envs | ForEach-Object {
            $command += ( " --env {0}" -f $_ )
        }
        $volumes | ForEach-Object {
            $command += ( " --volume {0}:{1}" -f $_.HostPath, $_.MountPath )
        }
        $command += (" --tag {0}" -f $imageNameTag )
        
        $command += " " + "--file " + $buildFile
        $command += " " + $buildDir

        Write-Host ("Building image {0} {1} with distribution {2} ..." -f $imageName, $imageVersion, $baseDistrib)
        Write-Host ("Using command: {0}" -f $command)

        # Execute the command
        LogDbg ("Set Current Dir : {0}" -f $buildPath)
        $res = [ExternalCommandHelper]::RunCommandInteractive( "podman", ( $command -split ' ' ))

        if ($res -ne 0) {
            LogError "Failed to build image: $res"
            return $null
        }

        LogSuccess "Image built successfully: $imageNameTag"

        LogDbg "< ContainerDriver::BuildImage()"

        return $imageNameTag
    }


    [object[]] ListObjects( [string]$object, [string[]]$params , [string]$filterLabel = $null) {
        LogDbg ("> ContainerDriver::ListObjects() - {0} - filter:{1}" -f $object,$filterLabel)
        try {
            if ($filterLabel) {
                $objects = [ExternalCommandHelper]::ExecCommand("podman $object list $params  --filter label=`"$filterLabel`" --format json")
            } else {
                $objects = [ExternalCommandHelper]::ExecCommand("podman $object list $params  --format json")
            }
            $objectsJson = $objects | ConvertFrom-Json
            # Force the result to be an array, even of 1 element
            if ($objects.GetType().name -eq "PSCustomObject") {
                LogDbg "returning 1 object as Array"
                return @( $objectsJson )
            } else {
                LogDbg "returning Array"
                return $objectsJson
            }
        } catch {
            LogError "Failed to list podman objects."
            return @()
        }
    }

    [object] GetObject( [string]$object, [string]$Name ) {
        LogDbg ("> ContainerDriver::GetObject() - {0} - name:{1}" -f $object,$Name)

        [ExternalCommandHelper]::ExecCommand("podman $object exists $Name")
        if ( $LastExitCode -ne 0 ) {
            return $null
        }

        LogDbg ("Inspecting object: {0}" -f $Name)

        $res = [ExternalCommandHelper]::ExecCommand("podman $object inspect $Name")

        LogDbg ($res | out-string)

        return $res | ConvertFrom-Json
    }

    [object[]] ListImages( ) {
        LogDbg "> ContainerDriver::ListImages()"
        return $this.ListObjects( "image", @(""), $null )
    }

    [object[]] ListImages( [string]$filterLabel ) {
        LogDbg ("> ContainerDriver::ListImages() filter:{0}" -f $filterLabel)
        return $this.ListObjects( "image", @(""), $filterLabel )
    }

    [object] GetImage([string]$imageName) {
        LogDbg "> ContainerDriver::GetImage()"
        return $this.GetObject("image",$imageName)
    }

    [void] TagImage([string]$imageId, [string]$tag) {
        LogDbg "> ContainerDriver::TagImage()"
        try {
            [ExternalCommandHelper]::ExecCommand("podman tag $imageId $tag")
            LogSuccess "Image tagged successfully: $tag"
        } catch {
            LogError "Failed to tag image: $_"
        }
    }

    [void] UntagImage([string]$imageId, [string]$tag) {
        LogDbg "> ContainerDriver::UntagImage()"
        try {
            [ExternalCommandHelper]::ExecCommand("podman untag $imageId $tag")
            LogSuccess "Image untagged successfully: $tag"
        } catch {
            LogError "Failed to untag image: $_"
        }
    }

    [void] RemoveImage([string]$imageId) {
        LogDbg "> ContainerDriver::RemoveImage()"
        try {
            [ExternalCommandHelper]::ExecCommand("podman rmi $imageId")
            LogSuccess "Image removed successfully: $imageId"
        } catch {
            LogError "Failed to remove image: $_"
        }
    }

    [void] CleanImages() {
        LogDbg "> ContainerDriver::CleanImages()"
        try {
            [ExternalCommandHelper]::ExecCommand("podman image prune --force")
        } catch {
            LogError "Failed to clean images"
        }
    }

    [string] CreateContainer([string]$Name, [string]$ImageName, [hashtable]$params) {
        LogDbg "> ContainerDriver::CreateContainer()"

        if (-not $Name) {
            LogError "Container name is required."
            return $null
        }

        if (-not $imageName) {
            LogError "Image name is required."
            return $null
        }

        if (-not $params) {
            LogError "Params is required."
            return $null
        }

        $labels  = $params.Labels
        $volumes = $params.Volumes
        $venvs   = $params.Envs
        $containerHostname = $params.hostname
        
        $command = "run -it --cap-add=NET_ADMIN --privileged --name " + $Name
        $volumes | ForEach-Object {
            $command += ( " --volume {0}" -f $_ )
        }
        if ($venvs) {
            $venvs | ForEach-Object {
                $command += ( " -e {0}" -f $_ )
            }
        }
        $labels | ForEach-Object {
            $command += ( " --label {0}" -f $_ )
        }
        $command += (" --hostname {0}" -f $containerHostname)
        $command += " " + $ImageName

        $res = [ExternalCommandHelper]::RunCommandInteractive( "podman", ( $command -split ' ' ))

        if ($res -ne 0) {
            LogError "Failed to build image: $res"
            return $null
        }

        return ""
    }


    [object[]] ListContainers() {
        LogDbg ("> ContainerDriver::ListContainers()")
        return $this.ListObjects( "container", @("-a"),  $null )
    }

    [object[]] ListContainers( [string]$filterLabel ) {
        LogDbg ("> ContainerDriver::ListContainers() filter:{0}" -f $filterLabel)
        return $this.ListObjects( "container", @("-a"), $filterLabel )
    }

    [object] GetContainer([string]$containerId) {
        LogDbg ("> ContainerDriver::GetContainers() - {0}" -f $containerId)
        return $this.GetObject("container",$containerId)
    }

    [void] StartContainer([string]$Name, [string]$shell) {
        LogDbg "> ContainerDriver::StartContainer()"
        try {
            
            Write-Host -ForegroundColor Cyan "ℹ️ Starting container $Name"
            #   -a, --attach               Attach container's STDOUT and STDERR
            #   -i, --interactive          Make STDIN available to the contained process
            #   -t, --tty                  Allocate a pseudo-TTY
            $res = [ExternalCommandHelper]::RunCommandInteractive( "podman", @( "start", "-ia", $Name ))

            if ($res -ne 0) {
                LogError "Failed to start container: $res"
                return
            }



        } catch {
            LogError "Failed to start container: $_"
        }
    }

    [void] StopContainer([hashtable]$params) {
        LogDbg "> ContainerDriver::StopContainer()"
        $containerId = $params.Id
        try {
            [ExternalCommandHelper]::ExecCommand("podman container stop  --time 2 $containerId")
            LogSuccess "Container stopped successfully: $containerId"
        } catch {
            LogError "Failed to stop container: $_"
        }
    }

    [void] RemoveContainer([string]$containerId) {
        LogDbg "> ContainerDriver::RemoveContainer()"
        try {
            [ExternalCommandHelper]::ExecCommand("podman container rm -f $containerId")
           LogSuccess "Container removed successfully: $containerId"
        } catch {
            LogError "Failed to remove container: $_"
        }
    }

    [void] RunShell([string]$containerId) {
        LogDbg "> ContainerDriver::RunShell()"
        [ExternalCommandHelper]::RunCommandInteractive('podman', @('exec', '-it', $containerId, 'bash'))
    }

    [object[]] ListVolumes() {
        LogDbg "> ContainerDriver::ListVolumes()"
        try {
            $volumes = [ExternalCommandHelper]::ExecCommand("podman volume list --format json") | ConvertFrom-Json
            return $volumes
        } catch {
            LogError "Failed to list podman volumes."
            return @()
        }
    }

    [object[]] ListVolumes( [string]$filterLabel ) {
        LogDbg "> ContainerDriver::ListVolumes()"
        try {
            $volumes = [ExternalCommandHelper]::ExecCommand("podman volume list --filter label=`"$filterLabel`" --format json")
            return $volumes | ConvertFrom-Json
        } catch {
            LogError "Failed to list podman volumes."
            return @()
        }
    }

    [string] CreateVolume([string]$Name, [string[]]$labels) {
        LogDbg "> ContainerDriver::CreateVolume()"
        $labelParams=""
        $labels | ForEach-Object {
            $labelParams += ( " --label {0}" -f $_ )
        }
        [ExternalCommandHelper]::ExecCommand("podman volume create $labelParams $Name") 
        return ""
    }

    [object] GetVolume([string]$volumeId) {
        LogDbg "> ContainerDriver::GetVolume()"
        [ExternalCommandHelper]::ExecCommand("podman volume exists $volumeId")
        if ( $LastExitCode -ne 0 ) {
            return $null
        }

        try {
            $volume = [ExternalCommandHelper]::ExecCommand("podman volume inspect $volumeId --format json") | ConvertFrom-Json
            return $volume
        } catch {
            LogError "Failed to get podman volume: $_"
            return $null
        }
    }
    
    [void] RemoveVolume([string]$volumeId) {
        LogDbg "> ContainerDriver::RemoveVolume()"
        try {
            [ExternalCommandHelper]::ExecCommand("podman volume rm $volumeId")
           LogSuccess "Volume removed successfully: $volumeId"
        } catch {
            LogError "Failed to remove volume: $_"
        }
    }
}

# =========================================================
# = Image Manager
# =========================================================

class ImageManager {
    [ContainerDriver]$Driver
    [Configuration]$Config

    ImageManager([ContainerDriver]$driver, [Configuration]$config) {
        $this.Driver = $driver
        $this.Config = $config
    }

    [Object[]] ListImages() {
        LogDbg "> Imagemanager::ListImages"
        $labelImages = $this.Config.get("labelImages")

        $images = $this.Driver.ListImages( "{0}=true" -f $labelImages ) 

        LogDbg ( ("images ({0}): {1}" -f ($images.Length ),($images | Out-String)) )

        $imagesout = @()

        $images | Where-Object { -not $_.Dangling } | ForEach-Object {

            LogDbg ( ">>>> image: {0}" -f ($_ | out-string ) )

            $image = $this.Driver.GetImage( $_.id )
            #$image | Select-Object -Property RepoTags[0],Labels.distribution

            $imagesout += [PSCustomObject]@{
                Name = ($image.RepoTags -replace "localhost/","")
                Distribution = $image.Labels.distribution
                Role = ($image.Config.Env | Where-Object { $_ -like "VOLUND_IMAGE_ROLE=*"} | Select-Object -First 1) -replace "VOLUND_IMAGE_ROLE=",""
            }
        }
        return $imagesout
    }

    [void] BuildImage( [string]$ImageName, [string]$Role, [string]$Distribution, [string]$Version = "latest" ) {
        LogDbg "> Imagemanager::Buildimage"

        LogInfo "Ensure bash scripts are in UNIX line ending format for proper image build"
        # convert all files in folder $this.config.get("sharedResourcesVolume") from windows line endings to unix line endings
        Get-ChildItem -Path $this.config.get("sharedResourcesVolume").HostPath -Recurse | ForEach-Object {
            if ($_.PSIsContainer -eq $false) { # skip directories
                #(Get-Content $_.FullName) | Set-Content $_.FullName 
                $file = $_.FullName
                # Replace CR+LF with LF
                $text = [IO.File]::ReadAllText($file) -replace "`r`n", "`n"
                [IO.File]::WriteAllText($file, $text)
            }
        }
        Get-ChildItem -Path $this.config.get("myResourcesVolume").HostPath -Recurse | ForEach-Object {
            if ($_.PSIsContainer -eq $false) { # skip directories
                #(Get-Content $_.FullName) | Set-Content $_.FullName 
                $file = $_.FullName
                # Replace CR+LF with LF
                $text = [IO.File]::ReadAllText($file) -replace "`r`n", "`n"
                [IO.File]::WriteAllText($file, $text)
            }
        }

        # change between parameter / real distribution name on dockerhub
        $distribImageRef = $this.config.Get( "base_image" ).$Distribution
        LogDbg( ( "Distribution ref: {0} -> {1}" -f $Distribution, $distribImageRef) )

        [ExternalCommandHelper]::ExecCommand(("podman pull $distribImageRef {0}" -f $this.config.get("pullOpts")))
        if ($LastExitCode -ne 0) { 
            LogError "Failed to pull base distribution image: $distribImageRef"
            return #$null
        }

        $params = @{
            Name        = $ImageName
            Version     = $Version
            BuildOpts   = $this.config.get("buildOpts")
            Distribution = $distribImageRef
            Labels      = @{ 
                $this.config.get("labelImages") = "true"
                "distribution" = $Distribution
                "build_date" = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
                "version" = $Version
            }
            Volumes     = @(
                $this.config.get("sharedResourcesVolume"), 
                $this.config.get("myResourcesVolume")
            )
            Envs = @(
                ("VOLUND_IMAGE_NAME={0}" -f $ImageName)
                ("VOLUND_IMAGE_ROLE={0}" -f $Role)
            )
            BuildDir    = $this.config.get("templateDir")
            BuildFile   = $this.config.get("containerfile")
        }

        if ( -not (test-path $this.config.get("myResourcesVolume")) ) {
            New-Item -Path $this.config.get("myResourcesVolume").hostPath  -ItemType "Directory"
        }

        $imgName = $this.Driver.BuildImage( $this.Config.Get("buildBasePath"), $params)
        
        if (-not $imgName) {
            LogError "Failed to build image."
            return #$null
        }

        $image = $this.Driver.Getimage( ("{0}:{1}" -f $imageName,$Version) )

        if (-not $image) {
            LogError "Failed to retrieve image after build."
            return #$null
        }

        # Write-Host $image

        # return [Image]::new( $image.RepoTags[0], "" )
    }

    [void] CleanOldImages() {
        $labelImages = $this.Config.get("labelImages")

        $images = $this.Driver.ListImages( "$labelImages=true" )

        $images | 
            ForEach-Object { 
                if ( ($_.Names | Where-Object { $_ -notlike "*:latest" } ).Count -lt 0 ) { 
                    Write-Host ("Removing old image {0}" -f $_.Id)
                    $this.Driver.RemoveImage( $_.Id )
                }
            }

        $this.Driver.CleanImages()
    }

    [void] RemoveImage([string]$Image) {

        $imageObj = $this.Driver.GetImage( $Image )
        
        if (-not $imageObj) {
            Write-Host -ForegroundColor Yellow ("Image '{0}' does not exist, nothing to delete." -f $Image)
            return
        }

        $hasContainers = $this.Driver.ListContainers( $this.config.get("labelContainers")+"=true" ) | Where-Object { $_.Image -eq $Image }
        if ($hasContainers) {
            Write-Host -ForegroundColor Red ("Image '{0}' cannot be deleted because it has associated containers." -f $Image)
            exit 1
        }

        Write-Host ("Deleting image {0} ..." -f $Image)
        $this.Driver.RemoveImage( $ImageObj.Id )
    }


  

}

# =========================================================
# = Container and Workspace Manager
# =========================================================

class WorkspaceManager {
    [Configuration]$Config
    [string]$WorkspaceRootPath

    WorkspaceManager( [Configuration]$config) {
        $this.Config = $config
        $this.WorkspaceRootPath = $config.Get("workspaceVolume").hostPath
    }

    [string] GetWorkspacePath([string]$name) {
        LogDbg ( "> WorkspaceManager::GetWorkspacePath() - {0}" -f $name)
        # Return the workspace path for the given container name
        $workspacePath = Join-Path $this.WorkspaceRootPath $name
        return $workspacePath
    }


    [void] CreateWorkspace([string]$name) {

        $workspacePath = Join-Path $this.WorkspaceRootPath $name

        # create workspace folder if not exists
        if (-not (Test-Path $workspacePath)) {
            New-Item -ItemType Directory -Path $workspacePath -Force | Out-Null
            Write-Host ("Workspace directory created at {0}" -f $workspacePath)
        } else {
            Write-Host ("Workspace directory already exists at {0}" -f $workspacePath)
        }

        # Create a VSCode workspace file for the container
        $workspaceFilePath = Join-Path $workspacePath ("{0}.code-workspace" -f $name)

        $workspaceContent = @{
            "folders" = @(
                @{
                    "path" = "."
                }
            )
            "settings" = @{
                "remote.containers.dockerPath" = "podman"
                "remote.containers.workspaceFolder" = $workspacePath
            }
        }

        $workspaceContent | ConvertTo-Json -Depth 10 | Out-File -FilePath $workspaceFilePath -Encoding utf8

        Write-Host ("VSCode workspace created at {0}" -f $workspaceFilePath)

        # Add VSCode Project Manager configuration
        #$projectManagerDir = Join-Path $containerDescriptor.workspacePath ".vscode"
        $projectManagerFile = "$env:APPDATA\Code\User\globalStorage\alefragnani.project-manager\projects.json"

        #if (-not (Test-Path $projectManagerDir)) {
        #    New-Item -ItemType Directory -Path $projectManagerDir -Force | Out-Null
        #}

        $projectEntry = @{
            "name" = $name
            "rootPath" = $workspacePath
            "paths" = @()
            "tags" = @()
            "enabled" = $true
        }

        # If the Project Manager file exists, append to its projects array, else create new
        $existingContent = ""
        if (Test-Path $projectManagerFile) {

            $existingContent = Get-Content $projectManagerFile -Raw | ConvertFrom-Json
            if ($existingContent ) {
                # Avoid duplicates by name or rootPath
                $alreadyExists = $existingContent | Where-Object {
                    $_.name -eq $projectEntry.name -or $_.rootPath -eq $projectEntry.rootPath
                }
                if (-not $alreadyExists) {
                    $existingContent += $projectEntry
                }
            }
        }

        $json = $existingContent | ConvertTo-Json -Depth 5
        # Write file with UTF-8 without BOM
        [System.IO.File]::WriteAllText($projectManagerFile, $json, [System.Text.UTF8Encoding]::new($false))

        Write-Host ("VSCode Project Manager config created at {0}" -f $projectManagerFile)
    }



    [void] RemoveWorkspace([string]$name) {
        # Remove the workspace directory and its contents
        $workspacePath = Join-Path $this.Config.Get("workspaceRoot") $name
        if (Test-Path $workspacePath) {
            Remove-Item -Path $workspacePath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host ("Workspace '{0}' removed." -f $name)
        } else {
            Write-Host -ForegroundColor Red ("Workspace '{0}' does not exist." -f $name)
        }

        # Remove project from VSCode Project Manager if it exists
        $projectManagerFile = "$env:APPDATA\Code\User\globalStorage\alefragnani.project-manager\projects.json"
        if (Test-Path $projectManagerFile) {
            $existingContent = Get-Content $projectManagerFile -Raw | ConvertFrom-Json
            if ($existingContent) {
                $updatedContent = $existingContent | Where-Object {
                    $_.name -ne $containerDescriptor.shortName -and $_.rootPath -ne $containerDescriptor.workspacePath
                }
                $json = $updatedContent | ConvertTo-Json -Depth 5
                [System.IO.File]::WriteAllText($projectManagerFile, $json, [System.Text.UTF8Encoding]::new($false))
                Write-Host ("Removed project '{0}' from VSCode Project Manager." -f $name)
            }
        }

    }

}


class ContainerManager {
    [ContainerDriver]$Driver
    [Configuration]$Config
    [WorkspaceManager]$WorkspaceManager
    [ContainerListener]$ContainerListener

    ContainerManager([ContainerDriver]$driver, [Configuration]$config, [WorkspaceManager]$workspaceManager) {
        $this.Driver = $driver
        $this.Config = $config
        $this.WorkspaceManager = $workspaceManager
        $this.ContainerListener = $null
    }

    [void] StartContainer([string]$Name, [string]$ImageName, [string]$Volume, [boolean]$WithGui, [Boolean]$OpenWorkspace, [string]$VpnConfig = $null) {
        LogDbg ( "> ContainerManager::StartContainer() - c:{0} iamge:{1} Gui:{2} openWorkspece:{3}" -f $Name,$ImageName,$WithGui, $OpenWorkspace)
        
        $workspaceFilePath = $this.WorkspaceManager.GetWorkspacePath( $Name )
        $this.ContainerListener = [ContainerListener]::new( $this.WorkspaceManager, $Name )

        $this.ContainerListener.Start()

        $myresourcesPaths = $this.config.Get("myResourcesVolume")

        $realVpnConfigFile = $null
        if ( $VpnConfig ) {
            # determine the VpnConfig file path
            if (Test-Path -Path $VpnConfig) {
                # OK
                $realVpnConfigFile = $VpnConfig
            } else {
                $altPath = ("{0}/setup/openvpn/{1}" -f $myresourcesPaths.hostPath,$VpnConfig ) 

                if (Test-Path -Path $altPath) {
                    # OK
                    $realVpnConfigFile = $altPath
                } else {
                    # vpn file not found
                    LogError ("VPN configuration file '{0}' does not exist." -f $VpnConfig)
                    return #$null
                }
            }
        }

        #if ( $VpnConfig -and -not (Test-Path -Path $VpnConfig) -and -not (Test-Path -Path ( Join-Path -Path $myresourcesPaths -ChildPath setup/openvpn/$VpnConfig)) ) {
        #    LogError ("VPN configuration file '{0}' does not exist." -f $VpnConfig)
        #    return $null
        #}

        $rslt = $this.Driver.GetContainer( $Name )
        if ( $null -eq $rslt ) {

            LogDbg ("Container {0} do not exists yet" -f $name)
            
            $this.WorkspaceManager.CreateWorkspace( $Name )
            
            # Optionally, open the workspace in VSCode
            if ($OpenWorkspace ) {
                Write-Host ("Opening VSCode workspace at {0} ..." -f $workspaceFilePath)
                Start-Process "code" -ArgumentList $workspaceFilePath
            }

            Write-Host "Creating container ..."

            $resourcesPaths = $this.config.Get("sharedResourcesVolume")
            $BackendMountResources =  ( "{0}:{1}:ro" -f $resourcesPaths.hostPath ,$resourcesPaths.mountPath)

            $BackendMountMyresources =  ( "{0}:{1}" -f $myresourcesPaths.hostPath ,$myresourcesPaths.mountPath)

            $workspacePathObj = $this.config.Get("workspaceVolume")
            $workspacePath = $this.WorkspaceManager.GetWorkspacePath( $Name )
            $BackendMountWorkspace = ( "{0}:{1}" -f $workspacePath,$workspacePathObj.mountPath)

            $labelsList = @(  ( "{0}=true" -f $this.config.Get("labelContainers") )  )
            $volumesList = @( 
                        $BackendMountResources,
                        $BackendMountMyresources,
                        $BackendMountWorkspace
                    )

            if ($VpnConfig) {
                $BackendMountVpn = $null
                #if (Test-Path -Path $VpnConfig) { 
                #    $BackendMountVpn = ( "{0}:/opt/openvpn-config.ovpn" -f $VpnConfig )
                #} elseif (Test-Path -Path ( Join-Path -Path $myresourcesPaths -ChildPath setup/openvpn/$VpnConfig)) {
                #    $BackendMountVpn = ( "{0}:/opt/openvpn-config.ovpn" -f ( Join-Path -Path $myresourcesPaths -ChildPath setup/openvpn/$VpnConfig) )
                #} else {
                #    LogError ("VPN configuration file '{0}' dose not exists !" -f $VpnConfig)
                #    return $null
                #}
                $BackendMountVpn = ( "{0}:/opt/openvpn-config.ovpn" -f $realVpnConfigFile )
                $volumesList += @($BackendMountVpn)
                $labelsList += @( "VPNConfig=true" )
            }

            $envsList = @()

            if ( $WithGui) {
                LogDbg("Adding Gui parameters")
                $labelsList += @( "X11Gui=true" )
                $volumesList += @(
                    "/mnt/wslg/.X11-unix:/tmp/.X11-unix",
                    "/mnt/wslg/runtime-dir:/mnt/wslg/runtime-dir"
                )
                $envsList += @(
                    "XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir",
                    "WAYLAND_DISPLAY=wayland-0",
                    "DISPLAY=:0",
                    "PULSE_SERVER=unix:/mnt/wslg/runtime-dir/pulse/native"
                    )
            }

            # Mounting optional volumes
            if ($Volume) {
                $Volume -split ',' | ForEach-Object {
                    $volumesList += @( ("{0}:/opt/{0}" -f $_ ) )
                }
            }

            $params = @{
                "Labels" = $labelsList
                "Volumes" = $volumesList
                "hostname" = $Name
                "Envs" = $envsList
            }
            
            $this.Driver.CreateContainer($Name, $ImageName, $params )

        } else {

            # Optionally, open the workspace in VSCode
            if ($OpenWorkspace) {
                Write-Host ("Opening VSCode workspace at {0} ..." -f $workspaceFilePath)
                Start-Process "code" -ArgumentList $workspaceFilePath
            }

            $rslt = $this.Driver.GetContainer($Name)
            if ( $rslt.State.Running -eq $false ) {
                Write-Host "Starting container ..."
                $shell = $this.Config.Get("shell") # default shell
                $this.Driver.StartContainer($Name, $shell)
            } else {
                Write-Host "opening shell to the container ..."
                $this.Driver.RunShell($Name)
            }
        }

        #return [Container]::new( "","") #  $name, $name )
    }


    [void] StopContainer([string]$containerId) {

        # test if container exists
        $containerDescriptor = $this.Driver.GetContainer($containerId)
        if (-not $containerDescriptor) {
            Write-Host -ForegroundColor Red ("Container with ID '{0}' does not exist." -f $containerId)
            return
        }
    
        Write-Host ("Stopping container {0} ..." -f $containerId)
        $this.Driver.StopContainer( @{ Id = $containerId } )

        #$this.ContainerListener.Remove()

    }

    
    [Object[]] ListContainers() {

        LogDbg "> ContainerManager::ListContainer"
        $labelContainers = $this.Config.get("labelContainers")

        $containers = $this.Driver.ListContainers( "{0}=true" -f $labelContainers ) 

        LogDbg ( ("containers: ({0}): {1}" -f ($containers.Length ),($containers | Out-String)) )

        $containersout = @()

        $containers | ForEach-Object {

            LogDbg ( ">>>> container: {0}" -f ($_ | out-string ) )

            $container = $this.Driver.GetContainer( $_.id )

            $containersout += [PSCustomObject]@{
                Name = $container.Name
                State = $container.State.Status
                Image = ($container.ImageName -replace "localhost/","")
                Role = ($container.Config.Env | Where-Object { $_ -like "VOLUND_IMAGE_ROLE=*"} | Select-Object -First 1) -replace "VOLUND_IMAGE_ROLE=",""
                Gui = $container.Config.Labels.X11Gui
                Vpn = $container.Config.Labels.VPNConfig
            }
        }
        return $containersout
    }

    [void] DisplayContainers() {
        $containers = $this.ListContainers()
        if ($containers.Count -eq 0) {
            Write-Host "No containers found."
            return
        }

        $containers | ForEach-Object {


            Write-Host ("Container: {0}, Image: {1}, Created: {2}" -f $_.Name, $_.Image, $_.Created)
        }
    }

    [void] RemoveContainer([string]$containerId) {
        LogDbg( "> ContainerManager::RemoveContainer()" )
        $this.Driver.RemoveContainer( $containerId )
    }



}


class ContainerListener {

    [WorkspaceManager]$WorkspaceManager
    [String]$containerId
    [string]$listenerPath
    [string]$listenerWatchPath

    ContainerListener( [WorkspaceManager]$WorkspaceManager, [string]$containerId ) {
        $this.WorkspaceManager = $WorkspaceManager
        $this.containerid = $containerId
        $workspaceath = $this.WorkspaceManager.GetWorkspacePath($containerId)
        $this.listenerPath = join-Path $workspaceath ".listener_id"
        $this.listenerWatchPath = $workspaceath

        LogDbg ( "ContainerListener::ContainerListener() - listenerPath: {0}" -f $this.listenerPath)
    }

    [boolean] TestListenerStatus( ) {
        LogDbg ( "> ContainerListener::TestListenerStatus()")
        
        if ( -not (Test-Path $this.listenerPath)) {
            LogDbg ("No listener job found for container '{0}'." -f $this.containerId)
            return $false
        }

        $jobPid = Get-Content $this.listenerPath | Select-Object -First 1
        if ($jobPid -notmatch '^\d+$') {
            LogWarn ("Invalid PID in job info file : {0}" -f $jobPid)
            Remove-Item -Path $this.listenerPath -Force
            return $false
        }

        try {
            Get-Process -Id $jobPid -ErrorAction Stop | Out-Null
        } catch {
            LogDbg "Listener process not found or not running."
            Remove-Item -Path $this.listenerPath -Force
            return $false
        }

        LogDbg ("Listener is running with PID: {0}" -f $jobPid)
        return $true
    }

    [void] Start( ) {
        LogDbg ("> ContainerListener::Start()")

        $listenerStatus = $this.TestListenerStatus(  )

        if ($listenerStatus) {
            LogSuccess ("Listener for container '{0}' is already running." -f $this.containerId)
            return
        }

        # supprime les job en doublon
        Get-Job -Name $this.containerId -ErrorAction SilentlyContinue | Remove-Job -Force

        # Démarre un thread de surveillance des fichiers open_url.txt
        # Write job info to a file so other PowerShell instances can find it
        
        LogInfo ("Starting listener for container '{0}' at path '{1}'..." -f $this.containerId, $this.ListenerPath)
        $listenerJob = Start-Job -Name $this.containerId -ScriptBlock {
            param($worspacePath, $jobInfoPath)
            # Write PID to job info file for visibility
            $pid | Out-File -FilePath $jobInfoPath -Encoding ascii

            $watchPath = Join-Path -Path $worspacePath -ChildPath ".to_host"
            if ( -not (test-path -path $watchPath) ) {
                New-Item -Path $worspacePath -Name ".to_host" -ItemType Directory
            }

            try {
                while ($true) {
                    Get-ChildItem -Path $watchPath -Filter "open_url*.txt" -ErrorAction SilentlyContinue | ForEach-Object {
                        try {
                            $url = Get-Content $_.FullName -Raw
                            if ($url -match '^https?://') {
                                Start-Process $url
                                Remove-Item $_.FullName -Force
                            }
                        } catch {
                            Write-Host "Erreur lors de l'ouverture de l'URL : $_"
                        }
                    }
                    Start-Sleep -Seconds 2
                }
            } finally {
                # Remove job info file when job ends
                Remove-Item -Path $jobInfoPath -ErrorAction SilentlyContinue
            }
        } -ArgumentList $this.listenerWatchPath, $this.listenerPath

        Write-host -ForegroundColor Cyan ("ℹ️ Background Job {0} started" -f $listenerJob)
    }


    [void] Remove( ) {
        LogDbg ("> ContainerListener::Remove()" )

        $listenerStatus = $this.TestListenerStatus()

        if ( $listenerStatus -eq $false ) {
            LogSuccess ("Listener for container '{0}' is not running." -f $this.containerId)
            return
        }

        $jobPid = Get-Content $this.listenerPath | Select-Object -First 1

        Stop-Process -Id $jobPid -Force -ErrorAction SilentlyContinue
    }

    
}

# =========================================================
# = Volume Manager
# =========================================================

class VolumeManager {
    [ContainerDriver]$Driver
    [Configuration]$Config

    VolumeManager([ContainerDriver]$driver, [Configuration]$config) {
        $this.Driver = $driver
        $this.Config = $config
    }
    

    [Object[]] ListVolumes() {
        $labelVolumes = $this.Config.get("labelVolumes")
        $volumes = $this.Driver.ListVolumes( "{0}=true" -f $labelVolumes )

        LogDbg ( ("volumes: ({0}): {1}" -f ($volumes.Length ),($volumes | Out-String)) )

        $volumesout = @()

        $volumes | ForEach-Object {

            LogDbg ( ">>>> volume: {0}" -f ($_ | out-string ) )

            $volume = $this.Driver.GetVolume( $_.Name )

            $volumesout += $volume # [Volume]::new( $volume.Name)
        }
        return $volumesout
    }

    [void] CreateVolume( [string]$name ) {

        $rslt = $this.Driver.GetVolume( $Name )
        if ( $null -ne $rslt ) {
            LogError("Volume with nale '$name' already exists")
            return
        }

        $labelVolumes = $this.Config.get("labelVolumes")
        $this.Driver.CreateVolume( $Name, @( ( "{0}=true" -f $labelVolumes ) ) )

        LogSuccess "Volume created successfully: $Name"
    }

    [void] RemoveVolume([string]$volumeId) {
        LogDbg( "> VolumeManager::RemoveVolume()" )
        $this.Driver.RemoveVolume( $volumeId )
    }

}

# =========================================================
# = Main Script
# =========================================================

# FIXME: verifier la coherence des parametres

# Vérifie Podman avant toute commande

$config = [Configuration]::new()
$config.LoadFromJson((Join-Path "${env:USERPROFILE}\volund" "config.json"))

# show debug traces
if ( $config.Get("debug") -eq $true ) {
    $global:TraceDebug = $true
}

# show all executed commands
if ( $config.Get("debugexecs") -eq $true ) {
    $global:TraceExec = $true
}

$driverType = $config.get("Driver")
if (-not $driverType) {
    LogError "Driver type is not set in the configuration."
    exit 1
}

# Create the driver instance based on the configuration
$driver = [ContainerDriver]::new( $config )

if ( $driver.isRunning() -ne "running" ) {
    LogInfo "Container driver is not running, starting it now..."
    $driver.Start()

    #wsl --list

    #podman system connection list

    #podman machine inspect
    
    $Env:DOCKER_HOST = 'npipe:////./pipe/podman-machine-default'

    podman machine start

    if ( $driver.isRunning() -ne "running" ) {
        LogError "Could not start Container Driver !"
        exit 1
    }
}

$imageMngr = [ImageManager]::new( $driver, $config )
$workspaceManager = [WorkspaceManager]::new( $config )
$containerMngr = [ContainerManager]::new( $driver, $config, $workspaceManager )
$volumeMngr = [VolumeManager]::new( $driver, $config )

switch ($Command) {
    "info"                { 
        $images = $imageMngr.ListImages()
        Write-Host "Images :"
        $images | Show-RichTable
        
        $containers = $containerMngr.ListContainers()
        Write-Host "Containers :"
        $containers | Show-RichTable
        
        $volumes = $volumeMngr.ListVolumes()
        Write-Host "Volumes :"
        $volumes | Show-RichTable

        Write-Host "`n`nDisk space usage :`n"
        podman system df
    }
    "write_user_config" {
        $config.WriteUserConfig( (Join-Path "${env:USERPROFILE}\volund" "config.json") )
    }
# === images ==============================================
    "build"               {
        if (($Image -eq "") -or ($Distribution -eq "")  -or ($Version -eq "")) {
            LogError("Missing parameter: -Distribution <Distribution name> -Version <image version>")
            return
        }
        $imageMngr.BuildImage( $Image, $Role, $Distribution, $Version )
    } 
    "lsi"                 { 
        Write-Host "`nImages :"
        $imageMngr.ListImages() | Show-RichTable
    }
    "rmi"                 {
        if ($Image -eq "") {
            LogError("Missing parameter: -Image <Image name>")
            return
        }
        $imageMngr.RemoveImage( $Image )
    } 
# === containers ==========================================
    "start"               {
        if ($Container -eq "") {
            LogError("Missing parameter: -Container <container name>")
            return
        }

        $containerMngr.StartContainer( $Container, $Image, $Volume, $WithGui.IsPresent, $OpenWorkspace, $VpnConfig)
    } 
    "stop"                {
        if ($Container -eq "") {
            LogError("Missing parameter: -Container <container name>")
            return
        }
        #Init-ContainerDescriptor -shortName $Container -imageName "$Image"
        $containerMngr.StopContainer( $Container )
    } 
    "ls"                  {
        Write-Host "`nContainers :"
        $containerMngr.ListContainers() | Show-RichTable
    }
    "rm"                  {
        if ($Container -eq "") {
            LogError("Missing parameter: -Container <container name>")
            return
        }
        $containerMngr.RemoveContainer( $Container )
    }
    # other
    "start-listener"      {
        if ($Container -eq "") {
            LogError("Missing parameter: -Container <container name>")
            return
        }
        $listener = [ContainerListener]::new( $workspaceManager, $Container)
        $listener.Start()
        # now we block, to let the listener to its job
        Get-Job | Wait-Job
    } 
    "kill-listener"       { 
       # Init-ContainerDescriptor -shortName $Container -imageName "$Image"
       # Remove-Listener
    }
# === Volumes =============================================
    "lsv"                  {
        Write-Host "`nContainers disponibles :"
        $volumeMngr.ListVolumes() | Show-RichTable
    }
    "newv"                 { 
        if ($Volume -eq "") {
            LogError("Missing parameter: -Volume <volume name>")
            return
        }
        $volumeMngr.CreateVolume( $Volume )
    }
    "rmv"                  { 
        if ($Volume -eq "") {
            LogError("Missing parameter: -Volume <volume name>")
            return
        }
        $volumeMngr.RemoveVolume( $Volume )
    }
# === Others ==============================================
    default         { Write-Host ("Commande '{0}' inconnue." -f $Command )}
}

# =========================================================
# = End of File
# =========================================================
