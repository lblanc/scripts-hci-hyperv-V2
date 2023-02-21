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
### Adjust IQN to "match" the DCS Adapter name
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
                $currentFullIQN = $port.Portname
                Write-Host "currentFullIQN : $currentFullIQN"
                $currentIQNPart = $($currentFullIQN -split ":")[1]
                ## Preparing the new IQN
                write-host 
                $PortLabelIqnPart = $( $port.Caption -replace "$(hostname)__","" )
                $PortLabelIqnPart = ($PortLabelIqnPart -replace " ","-").trim()
                $newIQNPart = "$(hostname)" + "-$PortLabelIqnPart"
                # Full IQN (must be lower case)
                $newFullIQN = $( $currentFullIQN -replace "$currentIQNPart","$newIQNPart" ).toLower()
                # Remove illegal characters for the iqn
                $newFullIQN = $newFullIQN -replace "_","-"
                $newFullIQN = $newFullIQN -replace "\-+","-"
                $newFullIQN = $newFullIQN -replace '[^a-zA-Z0-9.:-]', ''
                
                Write-Host "newFullIQN : $newFullIQN"
                if ( $newFullIQN.length -gt 127 )
                {
                    write-host "iqn can´t be longer than 127 chars." -foregroundcolor Yellow
                    $newFullIQN = $newFullIQN.Substring(0,126) 
                }
                $skipConfig = $false
            }
            else
            { $skipConfig = $true }

            if ( $skipConfig -eq $false )
            {
                Write-Host "NEW IQN: $newFullIQN"
                if ( -not ( $port.Portname -ieq "$newFullIQN" ) )
                {
                    try
                    {
                        $result = Set-DcsServerPortProperties -Port $port -NodeName $newFullIQN
                        write-host "     successfully set iqn" -ForegroundColor green
                    }
                    catch
                    { write-host "     failed to set iqn. This is the errormessage: '$($_.exception.message)'." -ForegroundColor red }
                }
                else
                { write-host "     already correct iqn" -ForegroundColor Green }
            }
            sleep 1
        }
        Disconnect-DcsServer -Connection $connection
    }
    else
    { write-host "no connection to server." -ForegroundColor red }
}
catch
{ write-host "error occured. Error message: '$($_.exception.message)'" -ForegroundColor Red }
