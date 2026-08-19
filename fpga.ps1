[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $FpgaArguments
)

$ErrorActionPreference = 'Stop'
$cli = Join-Path $PSScriptRoot 'tools\fpga.py'

if (Get-Command python -ErrorAction SilentlyContinue) {
    & python $cli @FpgaArguments
} elseif (Get-Command py -ErrorAction SilentlyContinue) {
    & py -3 $cli @FpgaArguments
} else {
    Write-Error 'Python 3.11 or newer was not found. Install Python and retry.'
}

exit $LASTEXITCODE
