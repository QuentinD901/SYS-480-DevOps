# Get all the virtual machines
$vms = Get-VM

# Store the virtual machine names and numbers in a dictionary for easier lookup
$vmdict = @{}
for ($i=0; $i -lt $vms.Count; $i++) {
    $vmdict[$i+1] = $vms[$i].Name
    $vmdict[$vms[$i].Name] = $i+1
}

# Display the virtual machines with a number prefix
for ($i=0; $i -lt $vms.Count; $i++) {
    Write-Host "$($i+1). $($vms[$i].Name)"
}

# Prompt for the virtual machine to clone
$vmInput = Read-Host -Prompt "Enter the virtual machine you would like to clone (number or name): "

# Check if the input is a number or a name
$key = $vmdict.Get_Item($vmInput)
if (!$key) {
    Write-Host "Invalid virtual machine. Please try again."
    continue
}

# Get the virtual machine to clone
$vm = $vms[$key - 1]

# Your cloning logic here
Write-Host "You selected to clone the virtual machine: $($vm.Name)"
