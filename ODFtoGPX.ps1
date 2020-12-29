# ODF-Track to GPX by Ting3l
# Version 0.1
# Description:
<#
    Extracts trackpoint from a routeplotter-file (type odf) and converts them to GPX to use in most usual gps-programs.
    Does not convert height- or timestamps, as those were not given in the file I had for comparison.
    Files are being imported/exported from/to the desktop. This can be changed in the UserVar-region.
#>

#region UserVar
$FileName = "kpxx99.odf" # Name der Quelldatei
$GPXName = "GPX.gpx" # Name der erzeugten GPX-Datei
$BasePath = "$env:USERPROFILE\Desktop"
#endregion

#region GlobalVar
$xml_header = '<?xml version="1.0" encoding="UTF-8" standalone="no" ?>'
$gpx_header = '<gpx xmlns="http://www.topografix.com/GPX/1/1" version="1.1" creator="Henning Scheel"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">'

$start_attr = '<'
$end_attr = '>'
$close_attr = '/'
$newline = "`n"
$tabulator = "`t"

$comment_start = "$($start_attr)!--"
$comment_end = "--$($end_attr)"
$track_start = "$($start_attr)trk$($end_attr)"
$track_end = "$($start_attr)$($close_attr)trk$($end_attr)"
$gpx_end = "$($start_attr)$($close_attr)gpx$($end_attr)"
$segment_start = "$($start_attr)trkseg$($end_attr)"
$segment_end = "$($start_attr)$($close_attr)trkseg$($end_attr)"
$point_end = "$($start_attr)$($close_attr)trkpt$($end_attr)"
#endregion

$gpx_data = [string]""
$gpx_data += $xml_header
$gpx_data += $newline
$gpx_data += $gpx_header
$gpx_data += $newline
$gpx_data += "$($start_attr)metadata$($end_attr)$($newline)"
$gpx_data += "$($start_attr)name$($end_attr)GPXTrack$($start_attr)$($close_attr)name$($end_attr)$($newline)"
$gpx_data += "$($start_attr)desc$($end_attr)Converted from ODF-Plotter-File$($start_attr)$($close_attr)desc$($end_attr)$($newline)"
$gpx_data += "$($start_attr)author$($end_attr)$($newline)"
$gpx_data += "$($start_attr)name$($end_attr)Henning Scheel$($start_attr)$($close_attr)name$($end_attr)$($newline)"
$gpx_data += "$($start_attr)$($close_attr)author$($end_attr)$($newline)"
$gpx_data += "$($start_attr)$($close_attr)metadata$($end_attr)$($newline)"


#region ConvertFile
$content = Get-Content -Path ("$($BasePath)\$($FileName)")
$TrackCount = 0

for ($i = 0; $i -lt $content.count; $i++){
    if ($content[$i] -like '$trk*'){
        $TrackCount++
    }
}

$lastIndex = 0

for ($h = 0; $h -lt $TrackCount; $h++){
    $gpx_data += $track_start
    $gpx_data += $newline
    $gpx_data += "$($start_attr)name$($end_attr)Track$($h + 1)$($start_attr)$($close_attr)name$($end_attr)$($newline)"
    $gpx_data += $segment_start
    $gpx_data += $newline

    for ($i = $lastIndex; $i -lt $content.count; $i++){
        if ($content[$i] -like '$trk*'){
            $index_start = $i
            break;
        }
    }
    for ($i = $index_start; $i -lt $content.count; $i++){
        if ($content[$i] -like '$END*'){
            $index_end = $i
            break;
        }
    }
    $lastIndex = $index_end

    $trackdata = $content[($index_start+1)..($index_end-1)]

    foreach ($point in $trackdata){
        $split = $point.Split(",")

        $nr = $split[0].TrimStart("$")

        $lat = $split[2].TrimEnd("S").TrimEnd("N")
        $splitLat = $lat.Split("D").Split(".")
        $decLat = [float]$splitLat[0] + [float]([float]$splitLat[1] / 60) + [float]([float]$splitLat[2] / 3600)

        $lon = $split[3].TrimEnd("*").TrimEnd("E").TrimEnd("W")
        $splitLon = $lon.Split("D").Split(".")
        $decLon = [float]$splitLon[0] + [float]([float]$splitLon[1] / 60) + [float]([float]$splitLon[2] / 3600)

        if (($decLat -eq 0) -or ($decLon -eq 0)){continue;}

        $gpx_data += "$($start_attr)trkpt lat=`"$($decLat)`" lon=`"$($decLon)`"$($end_attr)$($newline)"
        $gpx_data += "$($start_attr)ele$($end_attr)0.0$($start_attr)$($close_attr)ele$($end_attr)$($newline)"
        $gpx_data += "$($start_attr)desc$($end_attr)Trackpunkt #$($nr)$($start_attr)$($close_attr)desc$($end_attr)$($newline)"
        $gpx_data += "$($start_attr)$($close_attr)trkpt$($end_attr)$($newline)"
    }

    $gpx_data += $segment_end
    $gpx_data += $newline
    $gpx_data += $track_end
    $gpx_data += $newline
}



#endregion

$gpx_data += $gpx_end
$gpx_data += $newline

New-Item -Path $BasePath -Name $GPXName -ItemType File -Value $gpx_data -Force