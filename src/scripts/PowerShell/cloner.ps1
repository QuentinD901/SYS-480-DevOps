# Lists options to clone from
Get-VM
echo ""
# Prompts user for VM to clone
$vmInput = Read-Host -Prompt "Enter the VM you would like to clone: "

# Assign VM variable
$vm = Get-VM -Name $vmInput

# Prompts user for VM to clone
$ssInput = Read-Host -Prompt "Enter the Snapshot name for $vmInput here: "
# Snapshot
$snapshot=Get-Snapshot -Vm $vm -Name $ssInput

# Assigns Vmhost variable
$vmhost=Get-VMHost -Name "192.168.7.39"

# Assigns Datastore variable
$ds=Get-Datastore -Name "datastore1-super29"

# Assigns Linked Clone variable
$linkedClone= "{0}.linked" -f $vm.name

# Assigns Linked VM variable
$linkedVM = New-VM -LinkedClone -Name $linkedClone -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds


# Prompts user for Network Adapter
$netInput = Read-Host -Prompt "Enter the Network Adapter you want to assign: "

# Assigns Network Adapter
$net = $linkedVM | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $netInput

# Prompts user for New VM to name
$nvmInput = Read-Host -Prompt "Enter a name for your New Clone: "

# Assigns New VM variable 
$newVM = New-VM -Name $nvmInput -VM $linkedVM -VMHost $vmhost -Datastore $ds

# Snapshot the new VM
$newVM | New-Snapshot -Name "Base"

# Clean-up - Press 'Y' when prompted 
$linkedVM | Remove-VM

# Confirm 
Get-VM
