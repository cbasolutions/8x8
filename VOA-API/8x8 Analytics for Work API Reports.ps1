<#
.SYNOPSIS
    8x8 Analytics for Work
.DESCRIPTION
    This script will pull reports via the API and place in a CSV file in a subdirectory call reports.
.PARAMETER reportType
    Current supported values: Cdr, ExtSum
.NOTES
    Author: Brandon Jenkins, CBA Solutions
    Date:   July 2, 2021
.VERSION
    .3 
#>

param (
  [Parameter(Mandatory=$true)]
  $apiKey,
  [Parameter(Mandatory=$true)]
  $userName,
  [Parameter(Mandatory=$true)]
  $userPassword,
  [Parameter()]
  $pbxId= "allpbxes",
  [Parameter()]
  $apiVersion = "v1", 
  [Parameter()]
  $reportTimeZone = "UTC", 
  [Parameter()]
  [DateTime] $startTime,
  [Parameter()]
  [DateTime] $endTime,
  [Parameter()]
  [int] $reportDaysDuration,
  [Parameter(HelpMessage="Supported valeus: Daily, Hourly")]
  [String] $reportInterval = "Daily",
  [Parameter(Mandatory=$true,HelpMessage="Supported valeus: Cdr, ExtSum")]
  [String] $reportType,
  [Parameter(Mandatory=$false,HelpMessage="Supported valeus: Csv, Email")]
  [String] $reportOutput = "Csv"
)

$reportURL = "https://8x8gateway-prod.apigee.net/analytics/" + $apiVersion + "/" + $reportType.ToLower()

$authURL = "https://8x8gateway-prod.apigee.net/analytics/" + $apiVersion + "/oauth/token"

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
    $Uri = $reportURL + "?pbxId=" + $pbxId + "&endTime=" + $endTime.ToString("yyyy-MM-dd HH:mm:ss") + "&startTime=" + $startTime.ToString("yyyy-MM-dd HH:mm:ss") + "&timeZone=" + $timeZone + "&pageSize=" + $pageSize + "&isCallRecord=" + $isCallRecord + "&isSimplified=" + $isSimplified
    if ($scrollId -ne "") { 
      $Uri = $Uri + "&scrollId=" + "$scrollId"
    }
    $params = @{
      Uri = $Uri
      Headers = @{
        'Authorization' = "Bearer " + $accessToken
        '8x8-apikey' = $apiKey
      }
      Method = 'GET'
    }

    Invoke-RestMethod @params
}

function Save-to-CSV {
  [CmdletBinding()]
    param(
      [Parameter(Mandatory)]
      [Object]$reportData
      )
    $reportPath = "$PSScriptRoot\Reports"
    $reportName = "$reportPath\" + $reportType + "_output_$($currentTime.toString('yyyy-MM-dd_HHmmss')).csv"
    $reportName
    If ( -Not $(Test-Path $reportPath -PathType Container)) { New-Item -ItemType Directory -Path $reportPath }  
    $reportData | % {
      $result = $_ | Select-Object * -ExcludeProperty Branches, Departments
      $result | Add-Member -Name "Branches" -Value $($_.Branches -join "; " ) -MemberType NoteProperty
      $result | Add-Member -Name "Departments" -Value $( $_.Departments -join "; " ) -MemberType NoteProperty
      return $result
    } | Export-Csv -Path $ReportName -Encoding UTF8 -NoTypeInformation
}

## Stackoverflow example on sending CSV inline https://stackoverflow.com/questions/13648761/how-can-i-chain-export-csv-to-send-mailmessage-without-having-to-save-the-csv-to/62535823#62535823
function ConvertTo-CSVEmailAttachment {
Param(
    [Parameter(Mandatory=$true)]
    [String]$FileName,
    [Parameter(Mandatory=$true)]
    [Object]$PSObject,
    $Delimiter
    )
    If ($Delimiter -eq $null){$Delimiter = ","}
    $MS = [System.IO.MemoryStream]::new()
    $SW = [System.IO.StreamWriter]::new($MS)
    $PSObject = $PSObject | % {
      $result = $_ | Select-Object * -ExcludeProperty Branches, Departments
      $result | Add-Member -Name "Branches" -Value $($_.Branches -join "; " ) -MemberType NoteProperty
      $result | Add-Member -Name "Departments" -Value $( $_.Departments -join "; " ) -MemberType NoteProperty
      return $result
    }
    $SW.Write([String]($PSObject | convertto-csv -NoTypeInformation -Delimiter $Delimiter | % {($_).replace('"','') + [System.Environment]::NewLine}))
    $SW.Flush()
    $MS.Seek(0,"Begin") | Out-Null
    $CT = [System.Net.Mime.ContentType]::new()
    $CT.MediaType = "text/csv"
    Return [System.Net.Mail.Attachment]::new($MS,$FileName,$CT)
}

if ($PSVersionTable.PSVersion.Major -ge 5) {
  
  ## Get Token
  $token = Get-Token -userName $userName -userPassword $userPassword -apiKey $apiKey -authURL $authURL
  
  ## Get Report
  $currentTime = Get-Date
  Switch ($reportInterval)
  {
    "Hourly" {
      $startTime = (New-Object -Type DateTime -ArgumentList $currentTime.Year, $currentTime.Month, $currentTime.Day, $currentTime.Hour, 0, 0, 0).AddHours(-1)
      $endTime = New-Object -Type DateTime -ArgumentList $currentTime.Year, $currentTime.Month, $currentTime.Day, $currentTime.Hour, 0, 0, 0
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
  
  Switch ($reportType)
  {
    "ExtSum" {
      $reportJSON = Get-ExtSum -accessToken $token.access_token -apiKey $apiKey -reportURL $reportURL -timeZone $reportTimeZone -startTime $startTime -endTime $endTime -pbxId $pbxId
      $reportData = $reportJSON
      $reportData
    }
    "Cdr" {
      $reportJSON = Get-Cdr -accessToken $token.access_token -apiKey $apiKey -reportURL $reportURL -timeZone $reportTimeZone -startTime $startTime -endTime $endTime -pbxId $pbxId
      $reportData = $reportJSON.data
      While ($reportJSON.meta.scrollId -ne "No Data") {
        $reportJSON = Get-Cdr -accessToken $token.access_token -apiKey $apiKey -reportURL $reportURL -timeZone $reportTimeZone -startTime $startTime -endTime $endTime -pbxId $pbxId -scrollId $reportJSON.meta.scrollId
        $reportData = $reportData + $reportJSON.data
      }
    }
    Default {
      Write-Host "reportType: Current supported values: Cdr, ExtSum"
      Break
    }
  }
  
  Switch ($reportOutput) {
    "Csv" {
      Save-to-CSV -reportData $reportData
    }
    "Email" {
      $EmailAttachment = ConvertTo-CSVEmailAttachment -FileName $($reportType + "_output_$($currentTime.toString('yyyy-MM-dd_HHmmss')).csv") -PSObject $reportData -Delimiter "|"
      $SMTPserver = ""
      $from = ""
      $to = ""
      $subject = "Emailing the " + $reportType + " report"
      $emailbody = "Please see the attached"
  
      $mailer = new-object Net.Mail.SMTPclient($SMTPserver)
      $msg = new-object Net.Mail.MailMessage($from, $to, $subject, $emailbody)
      $msg.Attachments.Add($EmailAttachment) #### This uses the attachment made using the function above. 
      $msg.IsBodyHTML = $false
      $mailer.send($msg)
    }
  }
} else {
  write-host "Please upgrade your Powershell to version 5 or higher."
}
