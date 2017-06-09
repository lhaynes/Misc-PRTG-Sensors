#Sensors -> Settings -> Parameters, ex. '%host'
Param ($Device)

#Build the necessary URL structure from '%host'
$Base_URL = "https://$($Device)"
$Form_URL = $Base_URL + '/admin/main.html'
$JSON_URL = $Base_URL + '/json'

#Supply username and password credentials for the device
$Username = '%YourUsername%'
$Password = '%YourPassword'

$JSON_Post = '{"request":{"method":"statistics.list"}}'

try {
  $Request  = Invoke-WebRequest $Form_URL -SessionVariable dg

  $Form = $Request.Forms[0]
  $Form.Fields['act'] = 'login'
  $Form.Fields['admin_uid'] = $Username
  $Form.Fields['admin_password'] = $Password

  $Request = Invoke-WebRequest -Uri ($Base_URL + $Form.Action) -WebSession $dg -Method Post -Body $Form.Fields
  $Request = Invoke-RestMethod $JSON_URL -Method Post -Body $JSON_Post -WebSession $dg

  If ($Request.response.result) {
    Write-Host '<prtg>'
    Write-Host "<result>`n<channel>Active Calls</channel>"
    Write-Host "<value>$(($Request.response.result | ConvertFrom-Json).statistics.Active)</value>`n</result>"
    Write-Host '</prtg>'
  } Else {
    Throw "The JSON result is null. Verify authentication credentials."
  }
} catch {
@"
<prtg>
<error>1</error>
<text>$($_.Exception.Message)</text>
</prtg>
"@
}
