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
# The NICs facing the customer network
$prodNicName1 = "Prod1"
$prodNicName2 = "Prod2"
# The NICs used for the iSCSI traffic
$iSCSINicName1 = "iSCSI1"
$iSCSINicName2 = "iSCSI2"

## No need to change these variables
$productionTeamName = "Production"
$productionvSwitchName = "Production_vSwitch"
$liveMigrationVlan=200
$csvVlan=300
$heartbeatVlan=400
$iSCSI01vSwitchName = "iSCSI-01_vSwitch"
$iSCSI02vSwitchName = "iSCSI-02_vSwitch"



### Create the necessary teams
## The Production vSwitch & Teaming (Active / Active, but switch independent)

New-VMSwitch -Name "$productionvSwitchName" -NetAdapterName "$prodNicName1","$prodNicName2" -EnableEmbeddedTeaming $true -AllowManagementOS $false -MinimumBandwidthMode Weight

## iSCSI vSwitch 1
New-VMSwitch -Name "$iSCSI01vSwitchName" -NetAdapterName "$iSCSINicName1" -AllowManagementOS $false -MinimumBandwidthMode weight -notes "via Ethernet Adapter '$iSCSINicName1'"
## iSCSI vSwitch 2
New-VMSwitch -Name "$iSCSI02vSwitchName" -NetAdapterName "$iSCSINicName2" -AllowManagementOS $false -MinimumBandwidthMode weight -notes "via Ethernet Adapter '$iSCSINicName2'"


### Create virtual NICs
## on the production vSwitch
Add-VMNetworkAdapter -Name "CSV" -ManagementOS -SwitchName "$productionvSwitchName"
Add-VMNetworkAdapter -Name "Heartbeat" -ManagementOS -SwitchName "$productionvSwitchName"
Add-VMNetworkAdapter -Name "LiveMigration" -ManagementOS -SwitchName "$productionvSwitchName"
## on iSCSI vSwitch 01
Add-VMNetworkAdapter -Name "iSCSI-FE-01" -ManagementOS -SwitchName "$iSCSI01vSwitchName"
Add-VMNetworkAdapter -Name "iSCSI-MR-01" -ManagementOS -SwitchName "$iSCSI01vSwitchName"
## on iSCSI vSwitch 02
Add-VMNetworkAdapter -Name "iSCSI-FE-02" -ManagementOS -SwitchName "$iSCSI02vSwitchName"
Add-VMNetworkAdapter -Name "iSCSI-MR-02" -ManagementOS -SwitchName "$iSCSI02vSwitchName"


### Assign VLANs to the cross connected port, to segregate networks (VLANs are chosen "at will")
## Networks on Cluster Switch
#Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "Heartbeat" -vlanid $heartbeatVlan -access
#Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "CSV" -vlanid $csvVlan -access
#Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "LiveMigration" -vlanid $liveMigrationVlan -access
## Networks on iSCSI 01 - direct connected - VLAN IDs chosen randomly
#Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "iSCSI-FE-01" -vlanid 201 -access
#Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "iSCSI-MR-01" -vlanid 101 –access

## Networks on iSCSI 02 - direct connected - VLAN IDs chosen randomly
#Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "iSCSI-FE-02" -vlanid 202 -access
#Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "iSCSI-MR-02" -vlanid 102 -access


### Assign the bandwidth settings
## Ensure that the Management Network has always priority to keep control over the cluster
Set-VMNetworkAdapter -ManagementOS -Name "Heartbeat" -MinimumBandwidthWeight 100
Set-VMNetworkAdapter -ManagementOS -Name "CSV" -MinimumBandwidthWeight 90
Set-VMNetworkAdapter -ManagementOS -Name "LiveMigration" -MinimumBandwidthWeight 20
## iSCSI vSwitch 1
Set-VMNetworkAdapter -ManagementOS -Name "iSCSI-MR-01" -MinimumBandwidthWeight 100
Set-VMNetworkAdapter -ManagementOS -Name "iSCSI-FE-01" -MinimumBandwidthWeight 80
## iSCSI vSwitch 2
Set-VMNetworkAdapter -ManagementOS -Name "iSCSI-MR-02" -MinimumBandwidthWeight 100
Set-VMNetworkAdapter -ManagementOS -Name "iSCSI-FE-02" -MinimumBandwidthWeight 80

