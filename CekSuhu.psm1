# Modul pembaca suhu untuk Windows.
# Semua komentar dan pesan menggunakan Bahasa Indonesia.

function Convert-DeciKelvinKeCelsius {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double]$NilaiDeciKelvin
    )

    # WMI melaporkan suhu dalam persepuluh kelvin, bukan derajat Celsius.
    $celsius = ($NilaiDeciKelvin / 10.0) - 273.15

    # AwayFromZero dipakai supaya pembulatan angka seperti 45,05 menjadi 45,1.
    return [math]::Round($celsius, 1, [MidpointRounding]::AwayFromZero)
}

function Get-SensorLhm {
    param(
        [object[]]$Hardware
    )

    foreach ($perangkat in $Hardware) {
        if ($null -eq $perangkat) { continue }

        foreach ($sensor in $perangkat.Sensors) {
            if ($null -ne $sensor) { $sensor }
        }

        if ($perangkat.SubHardware) {
            Get-SensorLhm -Hardware @($perangkat.SubHardware)
        }
    }
}

function Get-SuhuWmi {
    [CmdletBinding()]
    param()

    $hasil = @()

    try {
        $zona = @(Get-CimInstance -Namespace 'root\wmi' -ClassName 'MSAcpi_ThermalZoneTemperature' -ErrorAction Stop)
    }
    catch {
        Write-Warning "WMI tidak dapat dibaca: $($_.Exception.Message)"
        return @()
    }

    foreach ($item in $zona) {
        if ($null -eq $item.CurrentTemperature) { continue }

        $celsius = Convert-DeciKelvinKeCelsius -NilaiDeciKelvin ([double]$item.CurrentTemperature)

        # Nilai di luar rentang ini hampir pasti bukan pembacaan suhu yang valid.
        if ($celsius -lt -50 -or $celsius -gt 150) { continue }

        $hasil += [pscustomobject]@{
            Sumber = 'WMI/ACPI'
            Sensor = [string]$item.InstanceName
            Celsius = $celsius
        }
    }

    return $hasil
}

function Get-SuhuLhm {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DllPath
    )

    if (-not (Test-Path -LiteralPath $DllPath)) {
        Write-Warning "File DLL tidak ditemukan: $DllPath"
        return @()
    }

    try {
        Unblock-File -LiteralPath $DllPath -ErrorAction SilentlyContinue
    }
    catch {
        # File mungkin sudah tidak diblokir; tidak perlu dihentikan.
    }

    if (-not ('LibreHardwareMonitor.Hardware.Computer' -as [type])) {
        try {
            Add-Type -LiteralPath $DllPath -ErrorAction Stop
        }
        catch {
            Write-Warning "Gagal memuat LibreHardwareMonitorLib.dll: $($_.Exception.Message)"
            return @()
        }
    }

    $computer = $null
    $semuaSensor = @()

    try {
        $computer = [LibreHardwareMonitor.Hardware.Computer]::new()
        $computer.IsCpuEnabled = $true
        $computer.Open()

        # Sensor butuh sedikit waktu untuk menghasilkan nilai pertama.
        Start-Sleep -Milliseconds 800

        $semuaSensor = @(Get-SensorLhm -Hardware $computer.Hardware)
    }
    catch {
        Write-Warning "Gagal membaca sensor LibreHardwareMonitor: $($_.Exception.Message)"
        return @()
    }
    finally {
        if ($null -ne $computer) {
            try { $computer.Close() } catch { }
        }
    }

    $data = @($semuaSensor | Where-Object {
        $_.SensorType.ToString() -eq 'Temperature' -and $null -ne $_.Value
    })

    if ($data.Count -eq 0) {
        Write-Warning 'LibreHardwareMonitor tidak mengembalikan sensor suhu. Coba jalankan PowerShell sebagai Administrator.'
        return @()
    }

    # Utamakan sensor paket/rata-rata CPU bila tersedia.
    $utama = @($data | Where-Object { $_.Name -like '*Package*' -or $_.Name -like '*Average*' })
    if ($utama.Count -gt 0) {
        $data = $utama
    }
    else {
        $data = @($data | Select-Object -First 4)
    }

    return @($data | ForEach-Object {
        [pscustomobject]@{
            Sumber = 'LibreHardwareMonitor'
            Sensor = [string]$_.Name
            Celsius = [math]::Round([double]$_.Value, 1, [MidpointRounding]::AwayFromZero)
        }
    })
}

function Get-SuhuSimulasi {
    [CmdletBinding()]
    param()

    # Data palsu untuk mencoba alur program tanpa perangkat keras.
    return @(
        [pscustomobject]@{ Sumber = 'Simulasi'; Sensor = 'CPU Package (contoh)'; Celsius = 52.3 },
        [pscustomobject]@{ Sumber = 'Simulasi'; Sensor = 'CPU Core 0 (contoh)'; Celsius = 55.1 },
        [pscustomobject]@{ Sumber = 'Simulasi'; Sensor = 'Thermal Zone 0 (contoh)'; Celsius = 48.9 }
    )
}

function Get-StatusSuhu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double]$Celsius,

        [double]$Ambang = 80
    )

    if ($Celsius -ge ($Ambang + 10)) { return 'PANAS' }
    if ($Celsius -ge $Ambang) { return 'WASPADA' }
    return 'NORMAL'
}

Export-ModuleMember -Function @(
    'Convert-DeciKelvinKeCelsius',
    'Get-SuhuWmi',
    'Get-SuhuLhm',
    'Get-SuhuSimulasi',
    'Get-StatusSuhu'
)
