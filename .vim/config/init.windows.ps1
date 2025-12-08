# Windows Vim Setup Script
# Run from PowerShell as Administrator

Write-Host "Setting up Vim configuration..." -ForegroundColor Cyan

# =============================================================================
# Chocolatey Package Installation
# =============================================================================

# Check if Chocolatey is installed
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey not found. Please install it first:" -ForegroundColor Red
    Write-Host "  https://chocolatey.org/install" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Checking required packages..." -ForegroundColor Cyan

# Node.js (required for coc.nvim)
if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Node.js..." -ForegroundColor Yellow
    choco install nodejs-lts -y
} else {
    Write-Host "Node.js already installed: $(node -v)" -ForegroundColor Green
}

# fzf (fuzzy finder)
if (!(Get-Command fzf -ErrorAction SilentlyContinue)) {
    Write-Host "Installing fzf..." -ForegroundColor Yellow
    choco install fzf -y
} else {
    Write-Host "fzf already installed" -ForegroundColor Green
}

# ripgrep (fast search)
if (!(Get-Command rg -ErrorAction SilentlyContinue)) {
    Write-Host "Installing ripgrep..." -ForegroundColor Yellow
    choco install ripgrep -y
} else {
    Write-Host "ripgrep already installed" -ForegroundColor Green
}

# bat (syntax highlighting for fzf preview)
if (!(Get-Command bat -ErrorAction SilentlyContinue)) {
    Write-Host "Installing bat..." -ForegroundColor Yellow
    choco install bat -y
} else {
    Write-Host "bat already installed" -ForegroundColor Green
}

# code-minimap (for minimap.vim plugin)
if (!(Get-Command code-minimap -ErrorAction SilentlyContinue)) {
    Write-Host "Installing code-minimap..." -ForegroundColor Yellow
    choco install code-minimap -y
} else {
    Write-Host "code-minimap already installed" -ForegroundColor Green
}

# .NET SDK (for OmniSharp C# support)
if (!(Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Host "Installing .NET SDK..." -ForegroundColor Yellow
    choco install dotnet-sdk -y
} else {
    Write-Host ".NET SDK already installed: $(dotnet --version)" -ForegroundColor Green
}

# sqlcmd (for SQL Server connections via vim-dadbod)
if (!(Get-Command sqlcmd -ErrorAction SilentlyContinue)) {
    Write-Host "Installing sqlcmd..." -ForegroundColor Yellow
    choco install sqlserver-cmdlineutils -y
} else {
    Write-Host "sqlcmd already installed" -ForegroundColor Green
}

# MySQL client (for MySQL connections via vim-dadbod)
if (!(Get-Command mysql -ErrorAction SilentlyContinue)) {
    Write-Host "Installing MySQL client..." -ForegroundColor Yellow
    choco install mysql-cli -y
} else {
    Write-Host "MySQL client already installed" -ForegroundColor Green
}

# vifm (vim-like file manager)
if (!(Get-Command vifm -ErrorAction SilentlyContinue)) {
    Write-Host "Installing vifm..." -ForegroundColor Yellow
    choco install vifm -y
} else {
    Write-Host "vifm already installed" -ForegroundColor Green
}

# =============================================================================
# Vimspector netcoredbg Installation (for .NET debugging)
# =============================================================================

Write-Host ""
Write-Host "Checking netcoredbg for Vimspector..." -ForegroundColor Cyan

$vimspectorGadgetsDir = "$env:USERPROFILE\.vim\plugged\vimspector\gadgets\windows"
$netcoredbgVersion = "3.1.2-1054"
$netcoredbgDir = "$vimspectorGadgetsDir\netcoredbg"
$netcoredbgExe = "$netcoredbgDir\netcoredbg.exe"

if (!(Test-Path $netcoredbgExe)) {
    Write-Host "Installing netcoredbg..." -ForegroundColor Yellow

    # Create directories
    New-Item -ItemType Directory -Path $netcoredbgDir -Force | Out-Null

    # Download netcoredbg
    $downloadUrl = "https://github.com/Samsung/netcoredbg/releases/download/$netcoredbgVersion/netcoredbg-win64.zip"
    $zipPath = "$env:TEMP\netcoredbg-win64.zip"

    Write-Host "  Downloading from $downloadUrl..." -ForegroundColor Gray
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

    # Extract using PowerShell (not tar, which fails on .zip)
    Write-Host "  Extracting..." -ForegroundColor Gray
    Expand-Archive -Path $zipPath -DestinationPath $netcoredbgDir -Force

    # netcoredbg extracts to a subfolder, move contents up if needed
    $extractedSubdir = "$netcoredbgDir\netcoredbg"
    if (Test-Path $extractedSubdir) {
        Get-ChildItem -Path $extractedSubdir | Move-Item -Destination $netcoredbgDir -Force
        Remove-Item $extractedSubdir -Force
    }

    # Cleanup
    Remove-Item $zipPath -Force

    Write-Host "  netcoredbg installed!" -ForegroundColor Green
} else {
    Write-Host "netcoredbg already installed" -ForegroundColor Green
}

# Create/update Vimspector gadgets configuration
$gadgetsJsonPath = "$vimspectorGadgetsDir\.gadgets.json"

# Ensure gadgets directory exists
New-Item -ItemType Directory -Path $vimspectorGadgetsDir -Force | Out-Null

# Write JSON manually to avoid BOM and control formatting
$netcoredbgPath = $netcoredbgDir.Replace('\', '/')
$gadgetsContent = @"
{
  "adapters": {
    "multi-session": {
      "host": "`${host}",
      "port": "`${port}"
    },
    "netcoredbg": {
      "command": [
        "$netcoredbgPath/netcoredbg.exe",
        "--interpreter=vscode"
      ]
    }
  }
}
"@

# Write without BOM (Set-Content -Encoding UTF8 adds BOM which breaks Vimspector)
[System.IO.File]::WriteAllText($gadgetsJsonPath, $gadgetsContent)
Write-Host "  Vimspector gadgets.json configured" -ForegroundColor Green

# =============================================================================
# Symlink Setup
# =============================================================================

Write-Host ""
Write-Host "Setting up symlinks..." -ForegroundColor Cyan

# Paths
$vimrcTarget = "$env:USERPROFILE\repo\dotfiles\.vimrc"
$vimrcLink = "$env:USERPROFILE\.vimrc"
$vimdirTarget = "$env:USERPROFILE\repo\dotfiles\.vim"
$vimdirLink = "$env:USERPROFILE\.vim"
$vimfilesDir = "$env:USERPROFILE\vimfiles"

# Helper function to check if path is a symlink
function Test-Symlink {
    param([string]$Path)
    if (Test-Path $Path) {
        $item = Get-Item $Path -Force
        return ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
    }
    return $false
}

# Handle .vimrc
if (Test-Path $vimrcLink) {
    if (Test-Symlink $vimrcLink) {
        Write-Host ".vimrc is already a symlink, removing..." -ForegroundColor Yellow
        (Get-Item $vimrcLink).Delete()
    } else {
        Write-Host "Removing existing .vimrc file..." -ForegroundColor Yellow
        Remove-Item $vimrcLink -Force
    }
}

# Handle .vim directory
if (Test-Path $vimdirLink) {
    if (Test-Symlink $vimdirLink) {
        Write-Host ".vim is already a symlink, removing..." -ForegroundColor Yellow
        (Get-Item $vimdirLink).Delete()
    } else {
        Write-Host "Removing existing .vim directory..." -ForegroundColor Yellow
        Remove-Item $vimdirLink -Recurse -Force
    }
}

# Remove vimfiles directory to avoid plugin conflicts
if (Test-Path $vimfilesDir) {
    if (Test-Symlink $vimfilesDir) {
        Write-Host "vimfiles is a symlink, removing..." -ForegroundColor Yellow
        (Get-Item $vimfilesDir).Delete()
    } else {
        Write-Host "Removing vimfiles directory..." -ForegroundColor Yellow
        Remove-Item $vimfilesDir -Recurse -Force
    }
}

# Create symbolic links
New-Item -ItemType SymbolicLink -Path $vimrcLink -Target $vimrcTarget
New-Item -ItemType SymbolicLink -Path $vimdirLink -Target $vimdirTarget

Write-Host "Symlinks created!" -ForegroundColor Green

# =============================================================================
# vim-plug Installation
# =============================================================================

Write-Host ""
Write-Host "Checking vim-plug..." -ForegroundColor Cyan

$plugPath = "$vimdirTarget\autoload\plug.vim"
if (!(Test-Path $plugPath)) {
    Write-Host "Installing vim-plug..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" `
        -OutFile $plugPath
    Write-Host "vim-plug installed!" -ForegroundColor Green
} else {
    Write-Host "vim-plug already installed" -ForegroundColor Green
}

# =============================================================================
# Shell Wrapper Setup (for :Q cd-on-exit feature)
# =============================================================================

Write-Host ""
Write-Host "Setting up shell wrappers..." -ForegroundColor Cyan

$toolsDir = "$env:USERPROFILE\tools"

# Create tools directory if it doesn't exist
if (!(Test-Path $toolsDir)) {
    New-Item -ItemType Directory -Path $toolsDir | Out-Null
    Write-Host "Created tools directory: $toolsDir" -ForegroundColor Green
} else {
    Write-Host "tools directory exists: $toolsDir" -ForegroundColor Green
}

# Create vim.bat wrapper for CMD (enables :Q cd-on-exit)
$vimBatPath = "$toolsDir\vim.bat"
$vimBatContent = @'
@echo off
"C:\Program Files\Vim\vim91\vim.exe" %*

REM After vim exits, check if :Q created the lastdir file
if exist "%USERPROFILE%\.vim\lastdir" (
    for /f "usebackq delims=" %%i in (`powershell -Command "(Get-Content '%USERPROFILE%\.vim\lastdir' -First 1).Replace('/', '\')"`) do (
        cd /d "%%i"
    )
    del "%USERPROFILE%\.vim\lastdir"
)
'@

Set-Content -Path $vimBatPath -Value $vimBatContent -Encoding ASCII
Write-Host "Created vim.bat wrapper: $vimBatPath" -ForegroundColor Green

# Check if tools directory is in PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$toolsDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$toolsDir", "User")
    Write-Host "Added $toolsDir to user PATH" -ForegroundColor Green
    Write-Host "  (Restart your terminal for PATH changes to take effect)" -ForegroundColor Yellow
} else {
    Write-Host "tools directory already in PATH" -ForegroundColor Green
}

# =============================================================================
# vifm Configuration
# =============================================================================

Write-Host ""
Write-Host "Setting up vifm configuration..." -ForegroundColor Cyan

$vifmConfigDir = "$env:USERPROFILE\.config\vifm"
$vifmrcPath = "$vifmConfigDir\vifmrc"

if (!(Test-Path $vifmConfigDir)) {
    New-Item -ItemType Directory -Path $vifmConfigDir -Force | Out-Null
    Write-Host "Created vifm config directory: $vifmConfigDir" -ForegroundColor Green
}

$vifmrcContent = @'
" Use vim as editor
set vicmd="C:\Program Files\Vim\vim91\vim.exe"

" Show line numbers
set number

" Use Windows default associations for files
filetype * start
'@

Set-Content -Path $vifmrcPath -Value $vifmrcContent -Encoding ASCII
Write-Host "Created vifm config: $vifmrcPath" -ForegroundColor Green

# =============================================================================
# Summary
# =============================================================================

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Installed tools:" -ForegroundColor Cyan
Write-Host "  - Node.js: $(node -v 2>$null)" -ForegroundColor White
Write-Host "  - fzf: $(fzf --version 2>$null)" -ForegroundColor White
Write-Host "  - ripgrep: $(rg --version 2>$null | Select-Object -First 1)" -ForegroundColor White
Write-Host "  - bat: $(bat --version 2>$null | Select-Object -First 1)" -ForegroundColor White
Write-Host "  - dotnet: $(dotnet --version 2>$null)" -ForegroundColor White
Write-Host "  - sqlcmd: $(if (Get-Command sqlcmd -ErrorAction SilentlyContinue) { 'installed' } else { 'not found' })" -ForegroundColor White
Write-Host "  - mysql: $(if (Get-Command mysql -ErrorAction SilentlyContinue) { 'installed' } else { 'not found' })" -ForegroundColor White
Write-Host "  - netcoredbg: $(if (Test-Path $netcoredbgExe) { 'installed' } else { 'not found' })" -ForegroundColor White
Write-Host "Shell wrappers:" -ForegroundColor Cyan
Write-Host "  - vim.bat: $vimBatPath" -ForegroundColor White
Write-Host "  - tools in PATH: $(if ($userPath -like "*$toolsDir*") { 'yes' } else { 'added (restart terminal)' })" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Restart your terminal (for PATH changes)" -ForegroundColor White
Write-Host "  2. Open Vim and run :PlugInstall" -ForegroundColor White
Write-Host "  3. Run :CocInstall coc-json coc-sql" -ForegroundColor White
Write-Host ""
Write-Host "Note: Use :Q to quit vim and cd to current directory" -ForegroundColor Cyan
Write-Host "      Use :q to quit vim without changing directory" -ForegroundColor Cyan
