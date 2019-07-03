# PexelsShell

![](https://img.shields.io/github/license/still34/pexelsshell.svg)
![](https://img.shields.io/github/issues/still34/pexelsshell.svg)
![](https://img.shields.io/github/issues-pr/still34/pexelsshell.svg)

Download photos off [Pexels](https://www.pexels.com/about/), a Creative-Common Zero stock photo website, with little to no hassle! Whether you are building your own library of CC0 stock photos or just getting wallpapers, this should suit you perfectly!

Compatible with both PowerShell and PowerShell Core.

## Features

- Easily scriptable
- Download a number of or all images at once
- (Windows-only, optional) Resolution matching
  - Download only photos that match or exceed your monitor's resolution
- Feel free to PR more!

## Usage

### Syntax

```
NAME
    Get-PexelsImage

SYNTAX
    Get-PexelsImage [-APIKey] <Object> [-Keyword] <Object> [[-Count] <int>] [[-Output] <Object>] [-MatchCurrentResolution] [<CommonParameters>]
```

### Example

Download 20 images labeled `night` to Desktop:
```powershell
$Desktop = [System.Environment]::GetFolderPath('desktop')
Get-PexelsImage -APIKey $key -Keyword night -count 20 -Output $Desktop
```

Download any images labeled `blackboard` to the current directory:
```powershell
Get-PexelsImage -APIKey $key -Keyword blackboard
```

Download any images labeled `skyline` to the current directory that matches monitor resolution:
```powershell
Get-PexelsImage -APIKey $key -Keyword skyline -MatchCurrentResolution
```

## Installation

1. Import the module via

```powershell
Import-Module ./Get-PexelsImage.psm1
```

2. Have fun!