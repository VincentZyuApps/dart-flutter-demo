$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding = [Console]::OutputEncoding

$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$computer = Get-CimInstance Win32_ComputerSystem
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$ip = Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object {
    $_.IPAddress -notlike '127.*' -and
    $_.IPAddress -notlike '169.254.*' -and
    $_.InterfaceAlias -notmatch 'Loopback'
  } |
  Sort-Object @{ Expression = {
    if ($_.InterfaceAlias -match 'Wi-?Fi|WLAN') { 0 }
    elseif ($_.InterfaceAlias -match 'Ethernet') { 1 }
    else { 2 }
  }} |
  Select-Object -First 1

$totalMemory = [int64]$os.TotalVisibleMemorySize * 1024
$freeMemory = [int64]$os.FreePhysicalMemory * 1024
$uptime = [int64]((Get-Date) - $os.LastBootUpTime).TotalSeconds

[ordered]@{
  operatingSystem = "$($os.Caption) $($os.Version)"
  host = if ($computer.Model) { "$($computer.Manufacturer) $($computer.Model)".Trim() } else { $env:COMPUTERNAME }
  kernel = "WIN32_NT $($os.Version)"
  uptimeSeconds = $uptime
  cpuModel = [string]$cpu.Name
  logicalProcessors = [int]$computer.NumberOfLogicalProcessors
  memoryUsedBytes = $totalMemory - $freeMemory
  memoryTotalBytes = $totalMemory
  diskUsedBytes = if ($disk) { [int64]$disk.Size - [int64]$disk.FreeSpace } else { $null }
  diskTotalBytes = if ($disk) { [int64]$disk.Size } else { $null }
  localIp = if ($ip) { [string]$ip.IPAddress } else { $null }
  locale = [System.Globalization.CultureInfo]::CurrentCulture.Name
} | ConvertTo-Json -Compress
