using namespace System.Drawing

Function Get-WallpaperPath
{
    Get-ItemProperty 'HKCU:\Control Panel\Desktop' | Select-Object -ExpandProperty WallPaper
}


Function Get-WallpaperFileExt
{
    [String]$BaseImage = Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name WallPaper | Select-Object -ExpandProperty WallPaper
    (Get-Item $BaseImage).Extension
}


<#
.Synopsis
   Gets the active background image
.DESCRIPTION
   Long description
.EXAMPLE
   Get-PSBGInfoBackgroundImage
   This command gets the active wallpaper, as set in registry key
      HKCU:\Control Panel\Desktop\WallPaper
#>
function Get-PSBGInfoBackgroundImage
{
    [CmdletBinding()]
    [OutputType([image])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$BaseImage
    )

    Begin
    {
        [bool]$PSBGInfoImage = $false
    }
    Process
    {
        Try {
            $Image = [Image]::FromFile($baseimage)
            IF ((Get-Item $BaseImage | Select-Object -ExpandProperty Name) -like "PSBGImage*") {
                $PSBGInfoImage = $true
            }

            $returnObj = New-Object -TypeName psobject -Property @{
                'Image'         = $image
                'BaseImage'     = $BaseImage
                'Extension'     = (Get-WallpaperFileExt)
                'PSBGInfoImage' = $PSBGInfoImage 
            }
        }
        catch {
            throw 'Wallpaper not found!'
        }
    }
    End
    {
        $returnObj
    }
}

Function New-PSBGInfoImageFiles
{
    [CmdletBinding()]
    [OutputType([void])]
    Param
    (
    )
    
    begin
    {
    }
    
    process
    { 
        [String]$BaseImage = Get-WallpaperPath
        [string]$PSBGInfoWallpaperOrig = "$env:TEMP\PSBGImage.orig.$(Get-WallpaperFileExt)"
        [string]$PSBGInfoWallpaper = "$env:TEMP\PSBGImage$(Get-WallpaperFileExt)"

        Copy-Item -Path $BaseImage -Destination $PSBGInfoWallpaperOrig -ErrorAction SilentlyContinue
        Copy-Item -Path $BaseImage -Destination $PSBGInfoWallpaper -ErrorAction SilentlyContinue
    }

    end
    {
    }
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Update-PSBGInfoBackgroundImage
{
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        # Original wallpaper
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [Image]$Image,

        # String[] to add to desktop wallpaper.
        [Parameter(Mandatory=$true,
                   Position=1)]
        [string[]]$text,
        
        # Fontfamily to use.
        [string]$FontFamily = 'courier',

        # Font size
        [float]$FontemSize = 24,

        # Font color by name, KnownColor. [enum]::GetValues([System.Drawing.KnownColor])
        [string]$FontColor = 'black'
    )

    Begin
    {
        # Validate fontcolor. this must be done in a better way.. later.
        IF ($FontColor -in ([enum]::GetValues([KnownColor]))) { }
        ELSEIF ($FontColor -eq '' -or $FontColor -eq $null) { $FontColor = 'black'}
        ELSE { Throw "Illegal fontcolor.`nUse one of $([enum]::GetValues([KnownColor]))" }    
        

        # Create textrendering objects
        $Font = [Font]::new( $FontFamily , $FontemSize )
        $brush = [SolidBrush]::new([Color]::$FontColor)

        # Starting Coordinates for text
        [float]$TextXCoordinate = ( $image.Width - ((($text | Sort-Object -Property Length -Descending | Select-Object -First 1).Length * 20) + 50 ) )
        [float]$TextYCoordinate = 20
        
        # Save location for temporary image
        [string]$PSBGInfoWallpaper = "$env:TEMP\PSBGImage$(Get-WallpaperFileExt)" 
    }
    Process
    {
        Try{
            $graphics = [Graphics]::FromImage($Image)
            Foreach ($String in $text){
                $graphics.DrawString( $String , $Font , $brush , $TextXCoordinate , $TextYCoordinate )
                $TextYCoordinate = $TextYCoordinate + 25
            }
            $Image.Save($PSBGInfoWallpaper)
            $PSBGInfoWallpaper
        }
        Catch{
            Write-Error 'Failed to update wallpaper!'
            $_.Exception.Message
        }
    }
    End
    {
        $graphics.dispose()
        $Image.dispose()
    }
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Set-PSBGInfoBackgroundImage
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$PSBGInfoWallpaper
    )

    Begin
    {
        # Blatantly stolen from Joel Bennet, http://poshcode.org/491
        try { 
            add-type @'
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32;
namespace Wallpaper
{
   public enum Style : int
   {
       Tile, Center, Stretch, NoChange
   }


   public class Setter {
      public const int SetDesktopWallpaper = 20;
      public const int UpdateIniFile = 0x01;
      public const int SendWinIniChange = 0x02;

      [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
      private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
      
      public static void SetWallpaper ( string path, Wallpaper.Style style ) {
         SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
         
         RegistryKey key = Registry.CurrentUser.OpenSubKey("Control Panel\\Desktop", true);
         switch( style )
         {
            case Style.Stretch :
               key.SetValue(@"WallpaperStyle", "2") ; 
               key.SetValue(@"TileWallpaper", "0") ;
               break;
            case Style.Center :
               key.SetValue(@"WallpaperStyle", "1") ; 
               key.SetValue(@"TileWallpaper", "0") ; 
               break;
            case Style.Tile :
               key.SetValue(@"WallpaperStyle", "1") ; 
               key.SetValue(@"TileWallpaper", "1") ;
               break;
            case Style.NoChange :
               break;
         }
         key.Close();
      }
   }
}
'@
        }
        catch {
            Write-Error 'Failed to create class'
            $_.exception.message
        }
    }

    Process
    {
        Try { 
            [Wallpaper.Setter]::SetWallpaper($PSBGInfoWallpaper , 'NoChange' )
        }
        catch {
            Write-Error 'Failed to set PSBGInfoWallpaper'
            $_.exception.message
        }
    }

    End
    {
    }
}
