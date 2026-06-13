param (
    [Parameter(Mandatory=$true)]
    [System.IO.DirectoryInfo]$SptDirectory
)

$ErrorActionPreference = "Stop"

if (-not $SptDirectory.Exists) {
    Write-Error "The directory does not exist: $($SptDirectory.FullName)"
    exit 1
}

$sharedUserPropsPath = "$($PSScriptRoot)\Shared.User.props"

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

    $xmlWriter.WriteStartElement("SptDir")
    $xmlWriter.WriteString($SptDirectory.FullName)
    $xmlWriter.WriteEndElement()

    $xmlWriter.WriteEndElement()

    $xmlWriter.WriteEndElement()

    $xmlWriter.WriteEndDocument()
    $xmlWriter.Flush()
    $xmlWriter.Close()
}

if (-not (Test-Path -Path $sharedUserPropsPath)) {
    Write-Host "Shared.User.props not found. Creating the file..." -ForegroundColor Yellow
    New-SharedUserProps -Path $sharedUserPropsPath
} else {
    Write-Host "Shared.User.props found. Loading file..."
    
    $xml.Load($sharedUserPropsPath)

    $sptPropertyGroup = $xml.SelectSingleNode("//PropertyGroup[SptDir]")

    if ($null -eq $sptPropertyGroup) {
        Write-Host "The SPT <PropertyGroup> is missing. Creating node..." -ForegroundColor Yellow
        $sptPropertyGroup = $xml.CreateElement("PropertyGroup")
        $xml.Project.AppendChild($sptPropertyGroup) > $null
    }

    $sptDirNode = $sptPropertyGroup.SelectSingleNode("//SptDir")

    if ($null -eq $sptDirNode) {
        Write-Host "<SptDir> is missing. Creating node..." -ForegroundColor Yellow
        $sptDirNode = $xml.CreateElement("SptDir")
        $sptPropertyGroup.AppendChild($sptDirNode) > $null
    }

    $sptDirNode.InnerText = $SptDirectory.FullName
    $xml.Save($sharedUserPropsPath)
}

Write-Host "Successfully set up shared mod project configuration!" -ForegroundColor Green