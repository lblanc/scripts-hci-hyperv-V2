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

#### SCRIPT START #####

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

$adapters = get-NetAdapter | where {$_.Name -imatch "vEthernet "}
$mask =24
$IPType = "IPv4"

function Select-Folder($message='Select a folder', $path = 0) { 
    $object = New-Object -comObject Shell.Application  
     
    $folder = $object.BrowseForFolder(0, $message, 0, $path) 
    if ($folder -ne $null) { 
        $folder.self.Path 
    } 
} 
$exportpath = Select-Folder 'Select the folder to export ip dump files' 

Get-NetIPAddress -AddressFamily IPv4 | where {$_.InterfaceAlias -imatch "vEthernet "}  | Export-Csv -Path $exportpath"\Old_iSCSI_IP.csv"

foreach ($adapter in $adapters)
{
# Remove any existing IP, gateway from our ipv4 adapter
If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
    $adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false
}

If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
    $adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false
}
$ip = [Microsoft.VisualBasic.Interaction]::InputBox("Enter IP for this adapter", $adapter.name, $ip)
$mask  = [Microsoft.VisualBasic.Interaction]::InputBox("Enter mask for this adapter", $adapter.name, $mask)


# Configure the IP address and default gateway
$adapter | New-NetIPAddress `
    -AddressFamily $IPType `
    -IPAddress $ip `
    -PrefixLength $mask `
}

Get-NetIPAddress -AddressFamily IPv4 | where {$_.InterfaceAlias -imatch "vEthernet "}  | Export-Csv -Path $exportpath"\New_iSCSI_IP.csv"


#### SCRIPT END #####
