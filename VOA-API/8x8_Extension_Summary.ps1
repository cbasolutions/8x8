## 8x8 Extension Summary Report
## Version .1
## Author: Brandon Jenkins
## CBA Solutions, LLC

## Define Paramaters

param (
  [Parameter(Mandatory=$true)]
  $apiKey,
  [Parameter(Mandatory=$true)]
  $userName,
  [Parameter(Mandatory=$true)]
  $userPassword,
  $pbxId= "allpbxes",
  $apiVersion = "v1", 
  $reportTimeZone = "UTC", 
  [DateTime] $startTime,
  [DateTime] $endTime,
  [int] $reportDaysDuration
)

$reportURL = "https://api.8x8.com/analytics/work/" + $apiVersion + "/extsum"
$authURL = "https://api.8x8.com/analytics/work/" + $apiVersion + "/oauth/token"

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
## Get Token
$token = Get-Token -userName $userName -userPassword $userPassword -apiKey $apiKey -authURL $authURL

## Get Report
If (-Not $startTime) { 
  if ($reportDaysDuration) {
    $startTime = [DateTime]::Today.AddDays(-$reportDaysDuration)
  } else {
    $startTime = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
  }
}
If (-Not $endTime) {
  if ($reportDaysDuration) {
    $endTime = [DateTime]::Today.AddDays(-1).AddHours(23).AddMinutes(59).AddSeconds(59)
  } else {
    $endTime = [datetime]::Now.ToUniversalTime()
  }
}

$extSumJSON = Get-ExtSum -accessToken $token.access_token -apiKey $apiKey -reportURL $reportURL -timeZone $reportTimeZone -startTime $startTime -endTime $endTime -pbxId $pbxId

## Save the report locally
$reportPath = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)\Reports"
$reportName = "$reportPath\$($MyInvocation.MyCommand.Name.Substring(0,$($MyInvocation.MyCommand.Name).Length-4))_output_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').csv"
If ( -Not $(Test-Path $reportPath -PathType Container)) { New-Item -ItemType Directory -Path $reportPath }  
$extSumJSON | Export-Csv -NoTypeInformation -Path $reportName
