<#
Storyline: This PowerShell script works is the main driver file behind running the menu interface that is controlled by 480-utils.psm1
Author: Quentin DeGiorgio
#>

# Import utils
Import-Module './modules/480-utils' -Force

# Call Banner
480Banner

# Connect to vCenter
$conf = get480Config -config_path = "/home/q/Documents/techJournal/SYS-480-DevOps/480.json"
480Connect #-server $conf.vcenter_server

# Call Select VM 
intMenu