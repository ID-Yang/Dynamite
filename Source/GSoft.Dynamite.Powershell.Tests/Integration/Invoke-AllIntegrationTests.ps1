﻿# GSoft.Dynamite.Powershell integration tests runner

# You must add Pester to your Modules folder and init script (see https://github.com/pester/Pester)
Import-Module Pester

# Re-import Dynamite toolkit to get the lastest changes
Import-Module Dynamite.PowerShell.Toolkit

# Make sure the current directory is the current file's parent folder
$path = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $path

# Tokenize 
Update-DSPTokens

# Invoke tests
Invoke-Pester -OutputFile slow-results.xml -OutputFormat LegacyNUnitXml