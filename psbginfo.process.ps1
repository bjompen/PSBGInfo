$strWallpaperSet = Get-WallpaperPath
$strWallpaperSetImageName = $strWallpaperSet | Split-Path -Leaf

IF ($strWallpaperSetImageName -like "PSBGImage*") {
    IF (Test-Path -Path "$env:TEMP\PSBGImage.orig*") {
        # Sätt $strImageToUpdate till PSBGImage.orig
    }
    Else {
        Write-Error 'You appear to have a psbginfo image set, but no backup image..'
    }
}

ELSE {
    New-PSBGInfoImageFiles
    # Sätt $strImageToUpdate till PSBGImage.orig
}

$imgPSBGInfoImage = Get-PSBGInfoBackgroundImage -BaseImage $WallpaperSet

$txtTextToAdd = '' # [string[]] med info vi vill lägga till

$strUpdatedPSBGInfo = Update-PSBGInfoBackgroundImage -Image $imgPSBGInfoImage -Text $txtTextToAdd

Set-PSBGInfoBackgroundImage -PSBGInfoWallpaper $strUpdatedPSBGInfo