# Get all the virtual machines
$vms = Get-VM

# Store the virtual machine names and numbers in a dictionary for easier lookup
$vmdict = @{}
for ($i=0; $i -lt $vms.Count; $i++) {
    $vmdict[$i+1] = $vms[$i].Name
    $vmdict[$vms[$i].Name] = $i+1
}

# Test vCenter Connection
function testConnect() {
if (Get-Command '$global:defaultviserver' -errorAction SilentlyContinue)
{
#Write-Output "Connected to vCenter."
listVMsToClone
}
else
{
loginToVCenter
}
}

# Login to vCenter
function loginToVCenter() {
$vcServer = "vcenter.quentin.local"
$vcUsr = "q-adm@quentin.local"
$vcPwd = "BabaBooey1"
Connect-VIServer -Server $vcServer -User $vcUsr -Password $vcPwd | Out-Null
Write-Host ""
listVMsToClone
}

# Store the virtual machines in an array
$vms = @(Get-VM)

# List VMs to Clone
function listVMsToClone() {
  cls
  # Display the virtual machines with a number prefix
  Write-Host "Virtual Machines"
  Write-Host "----------------"
  for ($i=0; $i -lt $vms.Count; $i++) {
      Write-Host "$($i+1). $($vms[$i].Name)"
  }
  Write-Host ""
  selVM
}

# Select VM to Clone
function selVM() {
  # Prompt for the virtual machine to clone
  $vmInput = Read-Host -Prompt "Enter the virtual machine you would like to clone (number or name)"

  # Check if the input is a number
  if ($vmInput -match '^\d+$') {
    $key = [int]$vmInput - 1
    if ($key -lt 0 -or $key -ge $vms.Count) {
      Write-Host "Invalid virtual machine number. Please try again."
      selVM
    }
  } else {
    # Check if the input is a name
    $vm = $vms | Where-Object { $_.Name -eq $vmInput } | Select-Object -First 1
    if (!$vm) {
      Write-Host "Invalid virtual machine name. Please try again."
      selVM
    }
  }

  # Get the virtual machine to clone
  if (!$vm) {
    $vm = $vms[$key]
  }

  # Your cloning logic here
  Write-Host "You selected to clone the virtual machine: $($vm.Name)"
  $confirm = Read-Host -Prompt "Are you sure you want to clone the selected virtual machine (Y/N)? "
  if ($confirm -eq "Y" -or $confirm -eq "y") {
    createLinkedClone
  } else {
    Write-Host "Cloning cancelled."
    listVMsToClone
  }
}

# Create Linked Clone
function createLinkedClone() {
  $vmhost = Get-VMHost -Name "192.168.7.39"
  $ds = Get-Datastore -Name "datastore1-super29"
  $snapshot = Get-Snapshot -VM $vm -Name "Base"
  $linkedClone = "{0}.linked" -f $vm.Name
  $linkedVM = New-VM -LinkedClone -Name $linkedClone -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds
  assignNetworkAdapter
}

# Assign Network Adapter
function assignNetworkAdapter() {
$netInput = Read-Host -Prompt "Enter the Network Adapter you want to assign"
$net = $linkedVM | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $netInput
nameNewVM
}
# Assign New VM name
function nameNewVM() {
$nvmInput = Read-Host -Prompt "Enter the name of the new VM"
$newVM = New-VM -Name $nvmInput -VM $linkedVM -VMHost $vmhost -Datastore $ds
createSnapshot
}

# Create Snapshot
function createSnapshot() {
$newVM | New-Snapshot -Name "Base"
cleanUp
}

# Clean Up linked VM
function cleanUp() {
$linkedVM | Remove-VM
finalCheck
}

# Prints all VMs one last time

testConnect
function finalCheck() {
Get-VM
}
