param (
    [Parameter(Mandatory=$true)]
    [System.IO.DirectoryInfo]$SptDirectory
)

$ErrorActionPreference = "Stop"

if (-not $SptDirectory.Exists) {
    Write-Error "The directory does not exist: $($SptDirectory.FullName)"
    exit 1
}

$solutionRootDir = Join-Path ((Get-Item (Join-Path $PSScriptRoot "..")).FullName) "\"
$sharedUserPropsPath = Join-Path $PSScriptRoot "Shared.User.props"

$xml = New-Object System.Xml.XmlDocument
$xml.PreserveWhitespace = $true

function New-SharedUserProps {
    param (
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo]$Path
    )

    New-Item -Path $Path -ItemType File

    $settings = New-Object System.Xml.XmlWriterSettings
    $settings.Indent = $true
    $settings.OmitXmlDeclaration = $true

    $xmlWriter = [System.Xml.XmlWriter]::Create($Path, $settings)
    $xmlWriter.WriteStartDocument()

    $xmlWriter.WriteStartElement("Project")

    $xmlWriter.WriteStartElement("PropertyGroup")
    $xmlWriter.WriteStartElement("SolutionDir")
    $xmlWriter.WriteString($solutionRootDir)
    $xmlWriter.WriteEndElement()
    $xmlWriter.WriteEndElement()

    $xmlWriter.WriteStartElement("PropertyGroup")
    $xmlWriter.WriteStartElement("SptDir")
    $xmlWriter.WriteString($SptDirectory.FullName)
    $xmlWriter.WriteEndElement()
    $xmlWriter.WriteEndElement()

    $xmlWriter.WriteEndElement()

    $xmlWriter.WriteEndDocument()
    $xmlWriter.Flush()
    $xmlWriter.Close()
}

function Update-SharedUserProps {
    param (
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo]$Path
    )

    param (
        [Parameter(Mandatory=$true)]
        [xml]$Xml
    )

    $Xml.Load($sharedUserPropsPath)

    $solutionPropertyGroup = $Xml.SelectSingleNode("//PropertyGroup[SolutionDir]")

    if ($null -eq $solutionPropertyGroup) {
        Write-Host "The Solution <PropertyGroup> is missing. Creating node..." -ForegroundColor Yellow
        $solutionPropertyGroup = $Xml.CreateElement("PropertyGroup")
        $Xml.Project.AppendChild($solutionPropertyGroup) > $null
    }

    $solutionDirNode = $Xml.SelectSingleNode("//PropertyGroup/SolutionDir")
    
    if ($null -eq $solutionDirNode) {
        Write-Host "<SolutionDir> is missing. Creating node..." -ForegroundColor Yellow
        $solutionDirNode = $Xml.CreateElement("SolutionDir")
        $solutionPropertyGroup.AppendChild($solutionDirNode) > $null
    }

    $sptPropertyGroup = $Xml.SelectSingleNode("//PropertyGroup[SptDir]")

    if ($null -eq $sptPropertyGroup) {
        Write-Host "The SPT <PropertyGroup> is missing. Creating node..." -ForegroundColor Yellow
        $sptPropertyGroup = $Xml.CreateElement("PropertyGroup")
        $Xml.Project.AppendChild($sptPropertyGroup) > $null
    }

    $sptDirNode = $sptPropertyGroup.SelectSingleNode("//SptDir")

    if ($null -eq $sptDirNode) {
        Write-Host "<SptDir> is missing. Creating node..." -ForegroundColor Yellow
        $sptDirNode = $Xml.CreateElement("SptDir")
        $sptPropertyGroup.AppendChild($sptDirNode) > $null
    }

    $sptDirNode.InnerText = $SptDirectory.FullName
    $Xml.Save($sharedUserPropsPath)
}

if (-not (Test-Path -Path $sharedUserPropsPath)) {
    Write-Host "Shared.User.props not found. Creating the file..." -ForegroundColor Yellow
    New-SharedUserProps -Path $sharedUserPropsPath
} else {
    Write-Host "Shared.User.props found. Loading file..."
    Update-SharedUserProps -Path $sharedUserPropsPath -Xml $xml
}

Write-Host "Successfully set up shared mod project configuration!" -ForegroundColor Green