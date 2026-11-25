[CmdletBinding()]
param(
    [switch]$Simulasi,

    [string]$DllPath,

    [ValidateRange(0, 200)]
    [double]$Ambang = 80,

    [ValidateRange(0, 3600)]
    [int]$Interval = 0,

    [ValidateRange(0, 1000)]
    [int]$Count = 0
)

$ErrorActionPreference = 'Stop'

$modul = Join-Path $PSScriptRoot 'CekSuhu.psm1'
if (-not (Test-Path -LiteralPath $modul)) {
    Write-Error "Modul tidak ditemukan: $modul"
    exit 1
}
Import-Module -Name $modul -Force

function Tampilkan-Pengukuran {
    param(
        [object[]]$Data,
        [double]$Ambang
    )

    $baris = @($Data | ForEach-Object {
        [pscustomobject]@{
            Waktu = Get-Date -Format 'HH:mm:ss'
            Sumber = $_.Sumber
            Sensor = $_.Sensor
            Celsius = $_.Celsius
            Fahrenheit = [math]::Round(($_.Celsius * 9.0 / 5.0) + 32, 1, [MidpointRounding]::AwayFromZero)
            Status = Get-StatusSuhu -Celsius $_.Celsius -Ambang $Ambang
        }
    })

    $baris | Format-Table -AutoSize | Out-String | Write-Host
}

$putaran = 0

do {
    $putaran++

    if ($Simulasi) {
        $data = @(Get-SuhuSimulasi)
    }
    elseif ($PSBoundParameters.ContainsKey('DllPath')) {
        $data = @(Get-SuhuLhm -DllPath $DllPath)
    }
    else {
        $data = @(Get-SuhuWmi)
    }

    if ($data.Count -eq 0) {
        Write-Host 'Tidak ada pembacaan suhu yang valid.' -ForegroundColor Yellow
        Write-Host 'Coba jalankan PowerShell sebagai Administrator, atau gunakan -DllPath untuk LibreHardwareMonitor.' -ForegroundColor Yellow
        Write-Host 'Untuk mencoba alur program tanpa sensor, gunakan -Simulasi.' -ForegroundColor Yellow
        exit 1
    }

    Tampilkan-Pengukuran -Data $data -Ambang $Ambang

    $suhuTertinggi = ($data | Measure-Object -Property Celsius -Maximum).Maximum

    if ($suhuTertinggi -ge ($Ambang + 10)) {
        Write-Host "Status: PANAS ($suhuTertinggi C melebihi batas $($Ambang + 10) C)" -ForegroundColor Red
    }
    elseif ($suhuTertinggi -ge $Ambang) {
        Write-Host "Status: WASPADA ($suhuTertinggi C mencapai batas $Ambang C)" -ForegroundColor Yellow
    }
    else {
        Write-Host "Status: NORMAL ($suhuTertinggi C, batas $Ambang C)" -ForegroundColor Green
    }

    if ($Interval -le 0) { break }
    if ($Count -gt 0 -and $putaran -ge $Count) { break }

    Write-Host "Menunggu $Interval detik... (Ctrl+C untuk berhenti)"
    Start-Sleep -Seconds $Interval

} while ($true)
