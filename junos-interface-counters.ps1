#Sensors -> Settings -> Parameters, ex. '%host' '%name'
Param ($Device, $Sensor)

#Fast Ethernet, Gigabit Ethernet, and 10 Gigabit Ethernet interfaces are supported by the expression
$Interface = ($Sensor | Select-string -Pattern '(fe|ge|xe)-\d/\d/\d' | ForEach {$_.matches} | Select $_).Value

#Supply username and password credentials for the device
$Username = '%YourUsername%'
$Password = ConvertTo-SecureString '%YourPassword%' -AsPlainText -Force
$Authentication = New-Object System.Management.Automation.PSCredential($Username, $Password)

#A list of interface counters to exclude
$Exclusions = @('carrier-transitions')

try {
    $Connection = New-SSHSession $Device -Credential $Authentication -AcceptKey 
    [xml] $Result = (Invoke-SSHCommand "show interfaces $($Interface) extensive | display xml" -SSHSession $Connection).Output
    Write-Host '<prtg>'

    $Result.'rpc-reply'.'interface-information'.'physical-interface'.'input-error-list'.ChildNodes | ForEach { 
        If ($Exclusions -notcontains $_.Name) {
            Write-Host "<result>`n<channel>$($_.Name)</channel>"
            Write-Host "<value>$($_.'#text')</value>`n</result>"
        }
    }
    $Result.'rpc-reply'.'interface-information'.'physical-interface'.'output-error-list'.ChildNodes | ForEach { 
        If ($Exclusions -notcontains $_.Name) {
            Write-Host "<result>`n<channel>$($_.Name)</channel>"
            Write-Host "<value>$($_.'#text')</value>`n</result>"
        }
    }
    Write-Host "</prtg>"
} catch {
@"
<prtg>
<error>1</error>
<text>$($_.Exception.Message)</text>
</prtg>
"@
}
