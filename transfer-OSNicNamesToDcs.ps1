##################################################################################################################################
# IMPORTANT:
# The example scripts listed are just examples that have been tested against a very specific configuration 
# which does not guarantee they will perform in the same manner in all implementations.  
# DataCore advises that you test these scripts in a test configuration before implementing them in production. 
#
# THE EXAMPLE SCRIPTS ARE PROVIDED AND YOU ACCEPT THEM "AS IS" AND "WITH ALL FAULTS."  
# DATACORE EXPRESSLY DISCLAIMS ALL WARRANTIES AND CONDITIONS, WHETHER EXPRESS OR IMPLIED, 
# AND DATACORE EXPRESSLY DISCLAIMS ALL OTHER WARRANTIES AND CONDITIONS, INCLUDING ANY 
# IMPLIED WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT, FITNESS FOR A PARTICULAR PURPOSE, 
# AND AGAINST HIDDEN DEFECTS TO THE FULLEST EXTENT PERMITTED BY LAW.  
#
# NO ADVICE OR INFORMATION, WHETHER ORAL OR WRITTEN, OBTAINED FROM DATACORE OR ELSEWHERE 
# WILL CREATE ANY WARRANTY OR CONDITION.  DATACORE DOES NOT WARRANT THAT THE EXAMPLE SCRIPTS 
# WILL MEET YOUR REQUIREMENTS OR THAT THEIR USE WILL BE UNINTERRUPTED, ERROR FREE, OR FREE OF 
# VARIATIONS FROM ANY DOCUMENTATION. UNDER NO CIRCUMSTANCES WILL DATACORE BE LIABLE FOR ANY INCIDENTAL, 
# INDIRECT, SPECIAL, PUNITIVE OR CONSEQUENTIAL DAMAGES, INCLUDING WITHOUT LIMITATION LOSS OF PROFITS, 
# SAVINGS, BUSINESS, GOODWILL OR DATA, COST OF COVER, RELIANCE DAMAGES OR ANY OTHER SIMILAR DAMAGES OR LOSS, 
# EVEN IF DATACORE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES AND REGARDLESS OF WHETHER 
# ARISING UNDER CONTRACT, WARRANTY, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE. 
# EXCEPT AS LIMITED BY APPLICABLE LAW, DATACORE’S TOTAL LIABILITY SHALL IN NO EVENT EXCEED US$100.  
# THE LIABILITY LIMITATIONS SET FORTH HEREIN SHALL APPLY NOTWITHSTANDING ANY FAILURE OF ESSENTIAL PURPOSE 
# OF ANY LIMITED REMEDY PROVIDED OR THE INVALIDITY OF ANY OTHER PROVISION. SOME JURISDICTIONS DO NOT ALLOW 
# THE EXCLUSION OR LIMITATION OF INCIDENTAL OR CONSEQUENTIAL DAMAGES, SO THE ABOVE LIMITATION OR EXCLUSION MAY NOT APPLY TO YOU.
# 
##################################################################################################################################
# Initializing DataCore PowerShell Environment 
$bpKey = 'BaseProductKey'
$regKey = get-Item "HKLM:\Software\DataCore\Executive"
$strProductKey = $regKey.getValue($bpKey)
$regKey = get-Item "HKLM:\$strProductKey"
$installPath = $regKey.getValue('InstallPath')
Import-Module "$installPath\DataCore.Executive.Cmdlets.dll" -ErrorAction:Stop -Warningaction:SilentlyContinue
### Mirror the names of the OS into DataCore Software
try
{
    $connection = Connect-DcsServer
    if ( $connection )
    {
        $hostname = $(hostname)
        $dcsServerObj = Get-DcsServer -server $hostname
        $iSCSIPorts = Get-DcsPort -Type iSCSI -Machine $hostname
        foreach ( $port in $iSCSIPorts )
        {
            if ( -not $( $port.PhysicalName -imatch "MSFT-05-1991" ) )
            {
                $physicalMac = $port.PhysicalName -replace "MAC:",""
                write-host "MAC: $physicalMac"
                $osAdapter = get-netadapter | where { $_.MacAddress -ieq $physicalMac -and -not ( $_.InterfaceDescription -imatch "Microsoft Network Adapter Multiplexor Driver" ) }
                if ( $osAdapter.count -gt 1 )
                {
                    $osAdapter = $osAdapter | where { $_.InterfaceDescription -imatch "Hyper-V Virtual Ethernet Adapter" }
                }
                $osAdapterName = $osAdapter.Name
                Write-Host "OS NAME: $osAdapterName"
                $newAdapterName = "$hostname"+"__"+"$osAdapterName"
            }
            else
            {
                $newAdapterName = "$hostname"+"__"+"iSCSI-Initiator"
                write-host "iSCSI initiator"
            }
            Write-Host "NEW NAME: $newAdapterName"
            if ( -not ( $port.Caption -ieq "$newAdapterName" ) )
            {
                try
                {
                    $result = Set-DcsPortProperties -Port $port -NewName $newAdapterName
                    write-host "     successfully set name" -ForegroundColor green
                }
                catch
                { write-host "     failed to set name. This is the errormessage: '$($_.exception.message)'." -ForegroundColor red }
            }
            else
            { write-host "     already correct name" -ForegroundColor Green }
        }
        Disconnect-DcsServer -Connection $connection
    }
    else
    { write-host "no connection to server." -ForegroundColor red }
}
catch
{
    write-host "error occured. Error message: '$($_.exception.message)'" -ForegroundColor Red
}
