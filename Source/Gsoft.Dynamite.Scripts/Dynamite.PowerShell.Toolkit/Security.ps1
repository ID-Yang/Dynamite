#
# Module 'Dynamite.PowerShell.Toolkit'
# Generated by: GSoft, Team Dynamite.
# Generated on: 10/24/2013
# > GSoft & Dynamite : http://www.gsoft.com
# > Dynamite Github : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit
# > Documentation : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
#

<#
	.SYNOPSIS
		Method to break the RoleInheritance of a Web

	.DESCRIPTION
		Method to break the RoleInheritance of a Web

    --------------------------------------------------------------------------------------
    Module 'Dynamite.PowerShell.Toolkit'
    by: GSoft, Team Dynamite.
    > GSoft & Dynamite : http://www.gsoft.com
    > Dynamite Github : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit
    > Documentation : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
    --------------------------------------------------------------------------------------
    
	.PARAMETER  Web
		The SPWeb URL to break the RoleInheritance.

	.PARAMETER  Break
		Flag to mention to break the RoleInheritance

	.EXAMPLE
		PS C:\> Set-DSPWebPermissionInheritance -Web http://myWeb -Break

	.INPUTS
		Microsoft.SharePoint.PowerShell.SPWebPipeBind,switch
        
  .LINK
    GSoft, Team Dynamite on Github
    > https://github.com/GSoft-SharePoint
    
    Dynamite PowerShell Toolkit on Github
    > https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit
    
    Documentation
    > https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
    
#>
function Set-DSPWebPermissionInheritance() {
	
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[Microsoft.SharePoint.PowerShell.SPWebPipeBind]$Web,
		[switch]$Break
	)
	
	if ($Break)
	{	
		$SPWeb = $Web.Read()
		$SPWeb.BreakRoleInheritance($true)
		Write-Verbose ([string]::Format("Role Inheritance was broken for {0}", $SPWeb.Url))
		$SPWeb.Update()
		$SPWeb.Dispose()
	}
}

<#
	.SYNOPSIS
		Method to add a Group to a Web based on XML definition of the group

	.DESCRIPTION
		Method to add a Group to a Web based on XML definition of the group

    --------------------------------------------------------------------------------------
    Module 'Dynamite.PowerShell.Toolkit'
    by: GSoft, Team Dynamite.
    > GSoft & Dynamite : http://www.gsoft.com
    > Dynamite Github : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit
    > Documentation : https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
    --------------------------------------------------------------------------------------
    
	.PARAMETER  Group
		The description of the group to add in XML

	.PARAMETER  Web
		The URL of the Web to add the group to.

	.EXAMPLE
		PS C:\> Add-DSPGroupByXml

  .INPUTS
		System.Xml.XmlElement,System.String
        
  .LINK
    GSoft, Team Dynamite on Github
    > https://github.com/GSoft-SharePoint
    
    Dynamite PowerShell Toolkit on Github
    > https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit
    
    Documentation
    > https://github.com/GSoft-SharePoint/Dynamite-PowerShell-Toolkit/wiki
    
#>

function Add-DSPGroupByXml() {
	
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$true, Position=0)]
		[System.Xml.XmlElement]$Group,
		
		[Parameter(Mandatory=$true, Position=1)]
		[string]$Web
	)	
	Write-Verbose "Entering Add-DSPGroupByXml with $Web"
	
	if ($Group -ne $null)
	{	
		foreach ($xmlGroup in $Group.Group)
		{
			$currentGroup = Get-DSPGroup -Web $Web -Group $xmlGroup.Name
			if ($currentGroup -eq $null)
			{
				$currentGroup = New-DSPGroup -Web $Web -GroupName $xmlGroup.Name -OwnerName $xmlGroup.OwnerName -Description $xmlGroup.Description
        		Write-Verbose ([string]::Format("The group {0} was added to the web {1}", $xmlGroup.Name, $Web))
			}
			else
			{
				Write-Verbose ([string]::Format("The group {0} already exist in web {1}", $xmlGroup.Name, $Web))
			}
			
			# Set Permission Levels
			if ($xmlGroup.PermissionLevels -ne $null)
			{
				foreach ($permissionLevel in $xmlGroup.PermissionLevels.PermissionLevel) 
				{
					Set-DSPPermission -Web $Web -PermissionLevel $permissionLevel.Name -GroupName $xmlGroup.Name -Verbose:$Verbose			
				}
			}
			
			$SPWeb = Get-SPWeb -Identity $Web
			
			# Set Associated Group
			if (($xmlGroup.IsAssociatedOwnerGroup -eq "true") -and ($currentGroup.Name -ne $SPWeb.AssociatedOwnerGroup.Name))
			{
				Write-Verbose "Associating group '$($currentGroup.Name)' as owners to web '$SPWeb'"
				$SPWeb.AssociatedOwnerGroup = $currentGroup
				$SPWeb.Update()
			}
			
			if (($xmlGroup.IsAssociatedVisitorGroup -eq "true") -and ($currentGroup.Name -ne $SPWeb.AssociatedVisitorGroup.Name))
			{
				Write-Verbose "Associating group '$($currentGroup.Name)' as visitors to web '$SPWeb'"
				$SPWeb.AssociatedVisitorGroup = $currentGroup
				$SPWeb.Update()
			}
			
      		# AssociatedMemberGroup can't be set.
	  
	  		# Add users to group
			if ($xmlGroup.Users -ne $null)
			{
				foreach ($user in $xmlGroup.Users.User)
				{
					Write-Verbose "Adding user '$user' to group '$($xmlGroup.Name)' in web '$($SPWeb.Name)'"
					$spUser = $SPWeb.EnsureUser($user)
					Set-SPUser -Identity $spUser -Web $SPWeb -Group $xmlGroup.Name -Verbose:$Verbose
				}
			}
		}
	}
	else
	{
		Write-Verbose "There is no group to add."
	}
}

function Set-DSPWebPermissions()
{
	[CmdletBinding()] 
	Param
	(
		[Parameter(ParameterSetName="Default", Mandatory=$true, Position=0)]
		[string]$XmlPath
	)
	
	$Config = [xml](Get-Content $XmlPath)
	
	# Process all Term Groups
	$Config.Configuration.Web | ForEach-Object {

		$web = $_.Name

		# Groups
		if ($_.Groups -ne $null)
		{
			Set-DSPWebPermissionInheritance -Web $web -Break
			Add-DSPGroupByXml -Web $web -Group $_.Groups
		}
	}
}