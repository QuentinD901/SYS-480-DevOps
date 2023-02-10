# Import utils
Import-Module '480-utils' -Force

# Call Banner
480Banner

$conf = get480Config -config_path = "/home/q/Documents/techJournal/SYS-480-DevOps/480.json"
480Connect -server $conf.vcenter_server

Write-Host "Select your VM"
selectVM -folder "BASE-VM"