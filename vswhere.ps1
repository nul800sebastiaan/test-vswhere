  $scriptRoot = "$PSScriptRoot"
  $scriptTemp = "$scriptRoot\temp"
  if (-not (test-path $scriptTemp)) { mkdir $scriptTemp > $null }
  
  $cache = 4
  $nuget = "$scriptTemp\nuget.exe"
  # ensure the correct NuGet-source is used (not the Umbraco one, but the NuGet-one)
  $nugetsource = "https://api.nuget.org/v3/index.json"
    
    $source = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
      Write-Host "Download NuGet..."
      Invoke-WebRequest $source -OutFile $nuget
      if (-not $?) { throw "Failed to download NuGet." }
    
	$vswhere = "$scriptTemp\vswhere.exe"
  
	Write-Host "Download VsWhere..."
	$params = "-OutputDirectory", $scriptTemp, "-Verbosity", "quiet", "-Source", $nugetsource
	&$nuget install vswhere @params
	if (-not $?) { throw "Failed to download VsWhere." }
	$dir = ls "$scriptTemp\vswhere.*" | sort -property Name -descending | select -first 1
	$file = ls -path "$dir" -name vswhere.exe -recurse
	Write-Host $dir\$file
	 
	mv "$dir\$file" $vswhere



    $vsPath = ""
    $vsVer = ""
    $msBuild = $null
    $toolsVersion = ""

    $vsMajor = if ($options.VsMajor) { $options.VsMajor } else { "17" } # default to 17 (VS2022) for now
	Write-Host "VS Major $vsMajor"
    $vsMajor = [int]::Parse($vsMajor)

    $vsPaths = new-object System.Collections.Generic.List[System.String]
    $vsVersions = new-object System.Collections.Generic.List[System.Version]

    # parse vswhere output
    $params = @()
    &$vswhere @params | ForEach-Object {
      if ($_.StartsWith("installationPath:")) { $vsPaths.Add($_.SubString("installationPath:".Length).Trim()) }
      if ($_.StartsWith("installationVersion:")) { $vsVersions.Add([System.Version]::Parse($_.SubString("installationVersion:".Length).Trim())) }
    }

	

    # get higest version lower than or equal to vsMajor
    $vsIx1 = -1
    $vsIx2 = -1
    $vsVersion = [System.Version]::Parse("0.0.0.0")
    $vsVersions | ForEach-Object {
      $vsIx1 = $vsIx1 + 1
      if ($_.Major -le $vsMajor -and $_ -gt $vsVersion) {
        $vsVersion = $_
        $vsIx2 = $vsIx1
      }
    }
	Write-Host "VS Major " $vsVersion.Major
    if ($vsIx2 -ge 0) {
      $vsPath = $vsPaths[$vsIx2]
	  
      if ($vsVersion.Major -gt 16) {
        $msBuild = "$vsPath\MSBuild\Current\Bin"
        $toolsVersion = "Current"
      }
      if ($vsVersion.Major -eq 15) {
        $msBuild = "$vsPath\MSBuild\$($vsVersion.Major).0\Bin"
        $toolsVersion = "15.0"
      }
      elseif ($vsVersion.Major -eq 14) {
        $msBuild = "c:\Program Files (x86)\MSBuild\$($vsVersion.Major)\Bin"
        $toolsVersion = "4.0"
      }
	  Write-Host "MSBuild: " $msbuild
    }