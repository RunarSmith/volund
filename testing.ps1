[CmdletBinding()]
param (
    [Switch]
    $Lint,

    [Switch]
    $Base,

    [Switch]
    $Profiles
)

Clear-Host

$DistributionsSet = @( "arch", "blackarch", "debian", "fedora", "kali", "parrot" )

$ProfilesSet = @( "devsecops", "offensivesec", "offensivesec_web" )

$LogFile = "build.log"

Remove-Item -Path $LogFile -ErrorAction SilentlyContinue -Force

if ($Lint.IsPresent -eq $true) {
  Write-Host -ForegroundColor Cyan "============================================================" | Tee-Object -FilePath $LogFile -Append
  Write-Host -ForegroundColor Cyan "# Linting                                                  #" | Tee-Object -FilePath $LogFile -Append
  Write-Host -ForegroundColor Cyan "============================================================" | Tee-Object -FilePath $LogFile -Append

  $Version="0.0.1-testing"

  ./volund.ps1 build -Image base-arch -Distribution arch -Version $Version | Tee-Object -FilePath $LogFile -Append

  ./volund.ps1 lsi | Tee-Object -FilePath $LogFile -Append

  ./volund.ps1 start -Container base-test -Image base-arch:$Version | Tee-Object -FilePath $LogFile -Append

  Write-Host -ForegroundColor Cyan "Linting ..." | Tee-Object -FilePath $LogFile -Append

  podman container exec test-vpn2 /opt/resources/ansible/lint.sh | Tee-Object -FilePath $LogFile -Append

  ./volund.ps1 rmi -Image base-arch:$Version | Tee-Object -FilePath $LogFile -Append
}


if ($Base.IsPresent -eq $true) {
  Write-Host -ForegroundColor Cyan "============================================================" | Tee-Object -FilePath $LogFile -Append
  Write-Host -ForegroundColor Cyan "# Testing building base distribution                       #" | Tee-Object -FilePath $LogFile -Append
  Write-Host -ForegroundColor Cyan "============================================================" | Tee-Object -FilePath $LogFile -Append

  $Version="0.0.2-testing"

  $DistributionsSet | ForEach-Object {
      $Distribution = $_
      Write-Host "Testing base distribution: $Distribution" | Tee-Object -FilePath $LogFile -Append
      $Command = ("./volund.ps1 build -Image base-{0} -Distribution {0} -Version {1}" -f $Distribution, $Version)
      Write-Host "Running command: $Command" | Tee-Object -FilePath $LogFile -Append
      Invoke-Expression $Command | Tee-Object -FilePath $LogFile -Append
  }
}

if ( $Profiles.IsPresent -eq $true ) {


  Write-Host -ForegroundColor Cyan "============================================================" | Tee-Object -FilePath $LogFile -Append
  Write-Host -ForegroundColor Cyan "# Testing building all distribution and profiles           #" | Tee-Object -FilePath $LogFile -Append
  Write-Host -ForegroundColor Cyan "============================================================" | Tee-Object -FilePath $LogFile -Append

  $Version="0.0.3-testing"

  $ProfilesSet | ForEach-Object {
      $ProfileName = $_
      $DistributionsSet | ForEach-Object {
          $Distribution = $_

          Write-Host "Testing distribution: $Distribution, profile: $ProfileName" | Tee-Object -FilePath $LogFile -Append
          $Command = ("./volund.ps1 build -Image {1}-{0} -Distribution {0} -Version {2}" -f $Distribution, $ProfileName, $Version)
          Write-Host "Running command: $Command" | Tee-Object -FilePath $LogFile -Append
          Invoke-Expression $Command | Tee-Object -FilePath $LogFile -Append
      }
  }
}
