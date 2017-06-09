#Sensors -> Settings -> Parameters, ex. '%host' '%name'
Param ($Device, $Sensor)

#Fast Ethernet, Gigabit Ethernet, and 10 Gigabit Ethernet interfaces are supported by the expression
$Interface = ($Sensor | Select-string -Pattern '(fe|ge|xe)-\d/\d/\d' | ForEach {$_.matches} | Select $_).Value

#Supply username and password credentials for the device
$Username = '%YourUsername%'
$Password = ConvertTo-SecureString '%YourPassword%' -AsPlainText -Force
$Authentication = New-Object System.Management.Automation.PSCredential($Username, $Password)

try {
    $Connection = New-SSHSession $Device -Credential $Authentication -AcceptKey 
    [xml] $Result = (Invoke-SSHCommand "show interfaces queue $($Interface) | display xml" -SSHSession $Connection).Output
    
    $Result.'rpc-reply'.'interface-information'.'physical-interface'.'queue-counters'.ChildNodes | ForEach {
    Write-Host '<prtg>'
        If ($_.'queue-number' -match '^\d+$') {
            Write-Host "<result>`n<channel>$($_.'forwarding-class-name')-tail-drops</channel>"
            Write-Host "<value>$($_.'queue-counters-tail-drop-packets')</value>`n</result>"

            Write-Host "<result>`n<channel>$($_.'forwarding-class-name')-packets</channel>"
            Write-Host "<value>$($_.'queue-counters-trans-packets')</value>`n</result>"
         
            Write-Host "<result>`n<channel>$($_.'forwarding-class-name')-bytes</channel>"
            Write-Host "<value>$($_.'queue-counters-trans-bytes')</value>`n</result>"
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
