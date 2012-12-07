[CmdletBinding(
	SupportsShouldProcess=$true,
	ConfirmImpact="Medium"
)]
param (
	# номер @втосекретаря
	[Parameter()]
    [string]
	[ValidatePattern( '^\d{10}$' )]
	$Phone = '9116007727'
)

Import-Module `
    (Join-Path `
		-Path ( Split-Path -Path ( $MyInvocation.MyCommand.Path ) -Parent ) `
        -ChildPath 'ITG.MTS.AA' `
    ) `
	-Force `
	-PassThru `
| Get-Readme -OutDefaultFile `
;
