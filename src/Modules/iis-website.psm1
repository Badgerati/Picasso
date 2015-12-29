##########################################################################
# Picassio is a provisioning/deployment script which uses a single linear
# JSON file to determine what commands to execute.
#
# Copyright (c) 2015, Matthew Kelly (Badgerati)
# Company: Cadaeic Studios
# License: MIT (see LICENSE for details)
#########################################################################

# Add/removes a website on IIS
Import-Module $env:PicassioTools -DisableNameChecking
Import-Module WebAdministration
sleep 2

function Start-Module($colour) {
	Test-Module $colour

	$siteName = $colour.siteName.Trim()
	$ensure = $colour.ensure.ToLower().Trim()
	$state = $colour.state

	$siteExists = (Test-Path "IIS:\Sites\$siteName")

	switch ($ensure) {
		'updated'
			{
				if (!$siteExists) {
					throw "Site for IIS website updating does not exist: '$siteName'."
				}

				$state = $state.ToLower().Trim()
				Write-Message "`nEnsuring Website is $state."

				switch ($state) {
					'started'
						{
							$pool = (Get-Item "IIS:\Sites\$siteName" | Select-Object applicationPool).applicationPool
							if ($pool -ne $null) {
								Restart-WebAppPool -Name $pool
								if (!$?) {
									throw
								}
							}

							Start-Website -Name $siteName
							if (!$?) {
								throw
							}
						}

					'stopped'
						{							
							Stop-Website -Name $siteName
							if (!$?) {
								throw
							}
						}
				}
				
				Write-Message "Website has been $state."
			}

		'removed'
			{
				Write-Message "Removing website: '$siteName'."

				if ($siteExists) {
					Remove-Website -Name $siteName
					if (!$?) {
						throw
					}
				}
				else {
					Write-Warnings 'Website does not exist.'
				}
				
				Write-Message 'Website removed successfully.'
			}
	}
}

function Test-Module($colour) {
	if (!(Test-Win64)) {
		throw 'Shell needs to be running as a 64-bit host when setting up IIS websites.'
	}

	$siteName = $colour.siteName
	if ([string]::IsNullOrEmpty($siteName)) {
		throw 'No site name has been supplied for website.'
	}

	$siteName = $siteName.Trim()
	$siteExists = (Test-Path "IIS:\Sites\$siteName")

	$ensure = $colour.ensure
    if ([string]::IsNullOrWhiteSpace($ensure)) {
        throw 'No ensure parameter supplied for website.'
    }

    # check we have a valid ensure property
    $ensure = $ensure.ToLower().Trim()
    if ($ensure -ne 'added' -and $ensure -ne 'removed') {
        throw "Invalid ensure parameter supplied for website: '$ensure'."
    }

	$state = $colour.state
    if ([string]::IsNullOrWhiteSpace($state) -and $ensure -eq 'added') {
        throw 'No state parameter supplied for website.'
    }
	
    # check we have a valid state property
	if ($state -ne $null) {
		$state = $state.ToLower().Trim()
	}

    if ($state -ne 'started' -and $state -ne 'stopped' -and $ensure -eq 'added') {
        throw "Invalid state parameter supplied for website: '$state'."
    }
}