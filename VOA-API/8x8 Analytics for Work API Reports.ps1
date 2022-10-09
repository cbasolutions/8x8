<#
.SYNOPSIS
    8x8 Analytics for Work
.DESCRIPTION
    This script will pull reports via the API and place in a CSV file in a subdirectory call reports.
.PARAMETER reportType
    Current supported values: Cdr, ExtSum
.NOTES
    Author: Brandon Jenkins, CBA Solutions
    Date:   July 5, 2021
.VERSION
    .5
#>

param (
  [Parameter(Mandatory=$false)]
  $global:apiKey = "",
  [Parameter(Mandatory=$false)]
  $global:userName = "",
  [Parameter(Mandatory=$false)]
  $global:userPassword = "",
  [Parameter()]
  $pbxId= "allpbxes",
  [Parameter()]
  $apiVersion = "v1", 
  [Parameter()]
  $reportTimeZone = "UTC", 
  [Parameter()]
  [DateTime] $startTime = "",
  [Parameter()]
  [DateTime] $endTime = "",
  [Parameter()]
  [int] $reportDaysDuration,
  [Parameter(HelpMessage="Supported valeus: Daily, Hourly")]
  [String] $reportInterval = "Daily",
  [Parameter(Mandatory=$false,HelpMessage="Supported valeus: Cdr, ExtSum")]
  [String] $reportType = "cdr",
  [Parameter(Mandatory=$false,HelpMessage="Supported valeus: Csv, Email")]
  [String] $reportOutput = "Email",
  [Parameter()]
  [String]$global:emailSMTP= "",
  [Parameter()]
  [String]$global:emailFrom = "",
  [Parameter()]
  [String]$global:emailTo= ""
)

$reportURL = "https://api.8x8.com/analytics/work/" + $apiVersion + "/" + $reportType.ToLower()

$global:authURL = "https://api.8x8.com/analytics/work/" + $apiVersion + "/oauth/token"

function Get-Token {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]$userName,
        [Parameter(Mandatory)]
        [String]$userPassword,
        [Parameter(Mandatory)]
        [String]$apiKey,
        [Parameter(Mandatory)]
        [String]$authURL
    )
    
    $params = @{
      Uri = $authURL
      Headers = @{ '8x8-apikey' = $apiKey }
      Method = 'POST'
      ContentType = 'application/x-www-form-urlencoded'
      Body = "username=" + $userName + "&password=" + $userPassword
    }

    Invoke-RestMethod @params
}

function Get-ExtSum {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]$accessToken,
        [Parameter(Mandatory)]
        [String]$apiKey,
        [Parameter(Mandatory)]
        [String]$reportURL,
        [Parameter(Mandatory)]
        [DateTime]$startTime,
        [Parameter(Mandatory)]
        [DateTime]$endTime,
        [Parameter(Mandatory)]
        [String]$timeZone,
        [Parameter(Mandatory)]
        [String]$pbxId
    )
    
    $params = @{
      Uri = $reportURL + "?pbxId=" + $pbxId + "&endTime=" + $endTime.ToString("yyyy-MM-dd HH:mm:ss") + "&startTime=" + $startTime.ToString("yyyy-MM-dd HH:mm:ss") + "&timeZone=" + $timeZone
      Headers = @{
        'Authorization' = "Bearer " + $accessToken
        '8x8-apikey' = $apiKey
      }
      Method = 'GET'
    }
    Invoke-RestMethod @params
}

function Get-Cdr {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [String]$accessToken,
    [Parameter(Mandatory)]
    [String]$apiKey,
    [Parameter(Mandatory)]
    [String]$reportURL,
    [Parameter(Mandatory)]
    [DateTime]$startTime,
    [Parameter(Mandatory)]
    [DateTime]$endTime,
    [Parameter(Mandatory)]
    [String]$timeZone,
    [Parameter(Mandatory)]
    [String]$pbxId,
    [Parameter()]
    [Int]$pageSize = 7000,
    [Parameter()]
    [String]$scrollId,
    [Parameter()]
    [String]$isCallRecord = "false",
    [Parameter()]
    [String]$isSimplified = "false"
  )
  $reportData = @()
  $Uri = $reportURL + "?pbxId=" + $pbxId + "&endTime=" + $endTime.ToString("yyyy-MM-dd HH:mm:ss") + "&startTime=" + $startTime.ToString("yyyy-MM-dd HH:mm:ss") + "&timeZone=" + $timeZone + "&pageSize=" + $pageSize + "&isCallRecord=" + $isCallRecord + "&isSimplified=" + $isSimplified
  $params = @{
    Uri = $Uri
    Headers = @{
      'Authorization' = "Bearer " + $accessToken
      '8x8-apikey' = $apiKey
    }
    Method = 'GET'
  }
  While ($reportJSON.meta.scrollId -ne "No Data") {
    Try {
      $reportJSON = Invoke-RestMethod @params
    }
    Catch {
      if ($_.Exception.Response.StatusCode.value__ -eq 401) {
        $global:token = Get-Token -userName $global:userName -userPassword $global:userPassword -apiKey $globl:apiKey -authURL $global:authURL
      } else {
        Write-Host "Error Received"
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
        break
      }
    }
    If ( -Not $reportJSON.meta.scrollId ) { $reportJSON = Invoke-RestMethod @params }
    $reportData += $reportJSON.data | % {
      $result = $_ | Select-Object * -ExcludeProperty Branches, Departments
      $result | Add-Member -Name "Branches" -Value $($_.Branches -join "; " ) -MemberType NoteProperty
      $result | Add-Member -Name "Departments" -Value $( $_.Departments -join "; " ) -MemberType NoteProperty
      return $result
    }
    If ( $params.Uri.Contains("scrollId=") ) {
      $params.Uri = $params.Uri.Replace($scrollId,$reportJSON.meta.scrollId)
    } else {
      $params.Uri = $params.Uri + "&scrollId=" + $reportJSON.meta.scrollId
    }
    $scrollId = $reportJSON.meta.scrollId
  }
  return $reportData
}

function Save-to-CSV {
  [CmdletBinding()]
    param(
      [Parameter(Mandatory)]
      [Object]$reportData,
      [Parameter(Mandatory)]
      [DateTime]$startTime,
      [Parameter(Mandatory)]
      [DateTime]$endTime
      )
    $reportPath = "$PSScriptRoot\Reports"
    $reportName = "$reportPath\" + $reportType + "_output_$($startTime.toString('yyyy-MM-dd_HHmmss'))-$($endTime.toString('yyyy-MM-dd_HHmmss')).csv"
    If ( -Not $(Test-Path $reportPath -PathType Container)) { New-Item -ItemType Directory -Path $reportPath }  
    $reportData | Export-Csv -Path $ReportName -Encoding UTF8 -NoTypeInformation
}

## Stackoverflow example on sending CSV inline https://stackoverflow.com/questions/13648761/how-can-i-chain-export-csv-to-send-mailmessage-without-having-to-save-the-csv-to/62535823#62535823
function Save-To-Email {
Param(
    [Parameter(Mandatory=$true)]
    [String]$FileName,
    [Parameter(Mandatory=$true)]
    [String]$emailSubject,
    [Parameter(Mandatory=$true)]
    [String]$emailBody,
    [Parameter(Mandatory=$true)]
    [Object]$reportData,
    $Delimiter
    )
    $FileName
    If ($Delimiter -eq $null){$Delimiter = ","}
    $MS = [System.IO.MemoryStream]::new()
    $SW = [System.IO.StreamWriter]::new($MS)
    $SW.Write([String]($reportData | convertto-csv -NoTypeInformation -Delimiter $Delimiter | % {($_).replace('"','') + [System.Environment]::NewLine}))
    $SW.Flush()
    $MS.Seek(0,"Begin") | Out-Null
    $CT = [System.Net.Mime.ContentType]::new()
    $CT.MediaType = "text/csv"
    $mailer = new-object Net.Mail.SMTPclient($emailSMTP)
    $msg = new-object Net.Mail.MailMessage($emailFrom, $emailTo, $emailSubject, $emailbody)
    $msg.Attachments.Add([System.Net.Mail.Attachment]::new($MS,$FileName,$CT))
    $msg.IsBodyHTML = $false
    $mailer.send($msg)
}


if ($PSVersionTable.PSVersion.Major -ge 5) {
  
  ## Get Token
  $global:token = Get-Token -userName $userName -userPassword $userPassword -apiKey $apiKey -authURL $authURL
  
  ## Get Report
  $currentTime = Get-Date
  Switch ($reportInterval)
  {
    "Hourly" {
      $requestStart = $startTime
      If ( $endTime -lt $requestStart.AddHours(1).addSeconds(-1) ) {
        $requestEnd = $endTime
      } else {
        $requestEnd = $requestStart.AddHours(1).addSeconds(-1)
      }
      While ( $requestStart -lt $endTime ) {
        Switch ($reportType)
        {
          "ExtSum" {
            $reportRequest = Get-ExtSum -accessToken $token.access_token -apiKey $apiKey -reportURL $reportURL -timeZone $reportTimeZone -startTime $requestStart -endTime $requestEnd -pbxId $pbxId
          }
          "Cdr" {
            $reportRequest = Get-Cdr -accessToken $token.access_token -apiKey $apiKey -reportURL $reportURL -timeZone $reportTimeZone -startTime $requestStart -endTime $requestEnd -pbxId $pbxId
          }
          Default {
            Write-Host "reportType: Current supported values: Cdr, ExtSum"
            Break
          }
        }
        #& Save-to-$reportOutput -reportData $reportRequest -startTime $requestStart -endTime $requestEnd
        & Save-to-$reportOutput -reportData $reportRequest -FileName "$($reportType)_output_$($requestStart.toString('yyyy-MM-dd_HHmmss'))-$($requestEnd.toString('yyyy-MM-dd_HHmmss')).csv" -emailSubject "$reportType report for $requestStart - $requestEnd" -emailBody "`n`n`n`n`n`n`n`n`n`n`nGUID" -Delimiter "`t"
        $requestStart = $requestEnd.AddSeconds(1)
        If ( $endTime -lt $requestStart.AddHours(1).addSeconds(-1) ) {
          $requestEnd = $endTime
        } else {
          $requestEnd = $requestStart.AddHours(1).addSeconds(-1)
        }
      }
    }
    "Daily" {
      $requestStart = $startTime
      If ( $endTime -lt $requestStart.AddDays(1).addSeconds(-1) ) {
        $requestEnd = $endTime
      } else {
        $requestEnd = $requestStart.AddDays(1).addSeconds(-1)
      }
      While ( $requestStart -lt $endTime ) {
        Switch ($reportType)
        {
          "ExtSum" {
            $reportRequest = Get-ExtSum -accessToken $token.access_token -apiKey $apiKey -reportURL $reportURL -timeZone $reportTimeZone -startTime $requestStart -endTime $requestEnd -pbxId $pbxId
          }
          "Cdr" {
            $reportRequest = Get-Cdr -accessToken $token.access_token -apiKey $apiKey -reportURL $reportURL -timeZone $reportTimeZone -startTime $requestStart -endTime $requestEnd -pbxId $pbxId
          }
          Default {
            Write-Host "reportType: Current supported values: Cdr, ExtSum"
            Break
          }
        }
        & Save-to-$reportOutput -reportData $reportRequest -FileName "$($reportType)_output_$($requestStart.toString('yyyy-MM-dd_HHmmss'))-$($requestEnd.toString('yyyy-MM-dd_HHmmss')).csv" -emailSubject "$reportType report for $requestStart - $requestEnd" -emailBody "`n`n`n`n`n`n`n`n`n`n`nGUID" -Delimiter "|"
        $requestStart = $requestEnd.AddSeconds(1)
        If ( $endTime -lt $requestStart.AddDays(1).addSeconds(-1) ) {
          $requestEnd = $endTime
        } else {
          $requestEnd = $requestStart.AddDays(1).addSeconds(-1)
        }
        $report = $report + $reportRequest
      }
    }
    default {
      If (-Not $startTime) { 
        If ($reportDaysDuration) {
          $startTime = [DateTime]::Today.AddDays(-$reportDaysDuration)
        } else {
          $startTime = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
        }
      }
      If (-Not $endTime) {
        If ($reportDaysDuration) {
          $endTime = [DateTime]::Today.AddDays(-1).AddHours(23).AddMinutes(59).AddSeconds(59)
        } else {
          $endTime = [datetime]::Now.ToUniversalTime()
        }
      }
    }
  }
} else {
  write-host "Please upgrade your Powershell to version 5 or higher."
}
