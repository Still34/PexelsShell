function Get-PexelsImage {
    param (
        [Parameter(Mandatory = $true)]
        [Alias('token')]
        [ValidateScript( { if (!([string]::IsNullOrEmpty($_))){
            $true;
        }else{
            throw [System.ArgumentException]::new("Pexels API token must be specified.")
        } })]
        $APIKey,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { if (!([string]::IsNullOrEmpty($_))){
            $true
        }else{
            throw [System.ArgumentException]::new("A search term or keyword must be specified.")
        } })]
        $Keyword,

        [ValidateScript( { if (($_ -ge 1)){
            $true
        }else{
            throw [System.ArgumentException]::new("Count must be greater than or equal to '1'.")
        } })]
        [int] $Count = [System.Int32]::MaxValue,

        [Alias('directory')]
        $Output,

        [ValidateScript({ if 
            (($PSVersionTable.PSVersion.Major -lt 6 -and $PSVersionTable.PSVersion.Major -gt 3) -or 
            ($IsWindows)){
            $true
        }else{
            throw [System.PlatformNotSupportedException]::new("Monitor resolution matching feature is only available on Windows.")
        } })]
        [switch]
        $MatchCurrentResolution = $false
    )
    begin {
        Clear-Host
        # Get current resolution
        if ($MatchCurrentResolution) {
            $videoController = Get-CimInstance -ClassName Win32_VideoController
            $TargetResolution = @{
                Horizontal = $videoController.CurrentHorizontalResolution
                Vertical   = $videoController.CurrentVerticalResolution
            }
        }

        # Create directory
        if ([string]::IsNullOrEmpty($Output)) {
            Write-Debug "$(Get-TimeStamp) Output not specified, assuming current directory..." 
            $Output = [System.IO.Path]::Combine((Get-Location).Path, "Pexels")
        }
        if (!(Test-Path $Output)) {
            Write-Warning "$(Get-TimeStamp) Directory not found, creating one..."
            $Output = ([System.IO.Directory]::CreateDirectory($Output)).FullName
        }

        # Create authentication header
        $authHeaders = @{
            "Authorization" = $APIKey
        }

        # Get page count
        $pageCeiling = 80
        $maxPages = 1
        if ($Count -gt $pageCeiling) {
            $maxPages = [math]::Ceiling($Count / $pageCeiling)
            $internalCount = 80
        }else{
            $internalCount = $Count
        }

        # Get invalid chars for filename sanitization
        $invalidChars = [System.IO.Path]::GetInvalidFileNameChars() + [System.IO.Path]::GetInvalidPathChars();

        Write-Host  "Current Configuration"
        Write-Host  "--------------------------------" -ForegroundColor DarkGray
        Write-Host  "   Search term: " -NoNewline
        Write-Host  $Keyword -ForegroundColor Cyan
        Write-Host  "   Number of image(s): " -NoNewline
        if ($Count -ge [System.Int32]::MaxValue){
            Write-Host  "All" -ForegroundColor Red
        }else{
            Write-Host  $Count -ForegroundColor Cyan
        }
        Write-Host  "   Output directory: " -NoNewline
        Write-Host  $Output -ForegroundColor Cyan
        if (!($null -eq $TargetResolution)){
            Write-Host  "   Resolution matching: " -NoNewline
            Write-Host  $MatchCurrentResolution -ForegroundColor Cyan
            Write-Host  "   Target resolution: $($TargetResolution.Horizontal)x$($TargetResolution.Vertical)"
        }
        Write-Host  "--------------------------------" -ForegroundColor DarkGray
    }
    process {
        for ($page = 1; $page -le $maxPages; $page++) {
            $results = Invoke-RestMethod -Uri "https://api.pexels.com/v1/search?query=$Keyword&per_page=$internalCount&page=$page" -Headers $authHeaders
            if ($page -eq 1){
                $imageCount = $results.total_results;
                Write-Host "$(Get-TimeStamp) $imageCount images found. Downloading $Count photos..."
                if ($imageCount -eq 0){
                    Write-Warning "$(Get-TimeStamp) No photos were found, exiting..."
                    return;
                }
            }
            foreach ($photo in $results.photos) {
                if (!($null -eq $TargetResolution) -and 
                    ($TargetResolution.Horizontal -gt 0) -and
                    ($TargetResolution.Vertical -gt 0)) {
                    if (($photo.width -lt $TargetResolution.Horizontal) -or 
                        ($photo.height -lt $TargetResolution.Vertical)) {
                        Write-Host "$(Get-Timestamp) Photo ID '$($photo.id)' does not meet the required resolution ($($TargetResolution.Horizontal)x$($TargetResolution.Vertical)), skipping..." -ForegroundColor Red
                        continue;
                    }
                }

                $photographer = ($photo.photographer).Replace(' ', "-");
                foreach ($c in $invalidChars) {
                    $photographer = $photographer.Replace($c, "-");
                }
                $filename = $photographer + "-$([System.IO.Path]::GetFileName($photo.src.original))"
                $fileOutput = [System.IO.Path]::Combine($Output, $filename)
                Write-Host "$(Get-TimeStamp) Downloading $filename from photo ID $($photo.id)..."
                Invoke-WebRequest -Uri $photo.src.original -OutFile $fileOutput
            }
            if (!$results.PSObject.Properties.Name -contains "next_page") {
                break
            }
        }
    }
    end{
        Write-Host "$(Get-timestamp) Download finished." -ForegroundColor Green
    }
}

function Get-TimeStamp {
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

Export-ModuleMember -Function Get-PexelsImage