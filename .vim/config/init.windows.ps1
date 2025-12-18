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

# fd (fast find alternative, for fzf directory search)
if (!(Get-Command fd -ErrorAction SilentlyContinue)) {
    Write-Host "Installing fd..." -ForegroundColor Yellow
    choco install fd -y
} else {
    Write-Host "fd already installed" -ForegroundColor Green
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

# GlazeWM (tiling window manager)
if (!(Get-Command glazewm -ErrorAction SilentlyContinue)) {
    Write-Host "Installing GlazeWM..." -ForegroundColor Yellow
    choco install glazewm -y
} else {
    Write-Host "GlazeWM already installed" -ForegroundColor Green
}

# Zebar (status bar for GlazeWM)
if (!(Get-Command zebar -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Zebar..." -ForegroundColor Yellow
    choco install zebar -y
} else {
    Write-Host "Zebar already installed" -ForegroundColor Green
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
# GlazeWM Configuration Symlink
# =============================================================================

Write-Host ""
Write-Host "Setting up GlazeWM configuration..." -ForegroundColor Cyan

$glzrTarget = "$env:USERPROFILE\repo\dotfiles\.glzr"
$glzrLink = "$env:USERPROFILE\.glzr"

# Handle existing .glzr directory
if (Test-Path $glzrLink) {
    if (Test-Symlink $glzrLink) {
        Write-Host ".glzr is already a symlink, removing..." -ForegroundColor Yellow
        (Get-Item $glzrLink).Delete()
    } else {
        Write-Host "Backing up existing .glzr directory..." -ForegroundColor Yellow
        $backupPath = "$env:USERPROFILE\.glzr.backup"
        if (Test-Path $backupPath) {
            Remove-Item $backupPath -Recurse -Force
        }
        Move-Item $glzrLink $backupPath
        Write-Host "  Backed up to $backupPath" -ForegroundColor Gray
    }
}

# Create symlink for .glzr
New-Item -ItemType SymbolicLink -Path $glzrLink -Target $glzrTarget
Write-Host "GlazeWM config symlink created!" -ForegroundColor Green

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

# Create cdf.bat wrapper for fuzzy directory navigation
# Use "cdf ." to include hidden files/directories
$cdfBatPath = "$toolsDir\cdf.bat"
$cdfBatContent = @'
@echo off
set "tmpfile=%USERPROFILE%\.vim\.lastcdf"
set "fdArgs=-a --type d"
if "%1"=="." set "fdArgs=%fdArgs% --hidden"
fd %fdArgs% . 2>nul | fzf > "%tmpfile%"
if exist "%tmpfile%" (
    for /f "usebackq delims=" %%d in (`powershell -NoProfile -Command "Get-Content '%tmpfile%' -First 1"`) do (
        cd /d "%%d"
    )
    del "%tmpfile%"
)
'@

Set-Content -Path $cdfBatPath -Value $cdfBatContent -Encoding ASCII
Write-Host "Created cdf.bat wrapper: $cdfBatPath" -ForegroundColor Green

# Create cdff.bat wrapper for fuzzy file search, cd to file's directory
# Use "cdff ." to include hidden files/directories
$cdffBatPath = "$toolsDir\cdff.bat"
$cdffBatContent = @'
@echo off
set "tmpfile=%USERPROFILE%\.vim\.lastcdff"
set "fdArgs=-a"
if "%1"=="." set "fdArgs=%fdArgs% --hidden"
fd %fdArgs% . 2>nul | fzf > "%tmpfile%"
if exist "%tmpfile%" (
    for /f "usebackq delims=" %%f in (`powershell -NoProfile -Command "Get-Content '%tmpfile%' -First 1"`) do (
        cd /d "%%~dpf"
    )
    del "%tmpfile%"
)
'@

Set-Content -Path $cdffBatPath -Value $cdffBatContent -Encoding ASCII
Write-Host "Created cdff.bat wrapper: $cdffBatPath" -ForegroundColor Green

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
# FZF Default Options (Ctrl+Y to copy to clipboard)
# =============================================================================

Write-Host ""
Write-Host "Setting up FZF default options..." -ForegroundColor Cyan

$fzfOpts = "--bind 'ctrl-y:execute-silent(echo {} | clip)'"
[Environment]::SetEnvironmentVariable("FZF_DEFAULT_OPTS", $fzfOpts, "User")
Write-Host "Set FZF_DEFAULT_OPTS environment variable (Ctrl+Y copies to clipboard)" -ForegroundColor Green

# =============================================================================
# PowerShell Profile Setup (cdf/cdff functions)
# =============================================================================

Write-Host ""
Write-Host "Setting up PowerShell profile functions..." -ForegroundColor Cyan

$profileDir = Split-Path $PROFILE -Parent
if (!(Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

$fzfFunctions = @'

# FZF default options (added by init.windows.ps1)
# Ctrl+Y copies current selection to clipboard
$env:FZF_DEFAULT_OPTS = "--bind 'ctrl-y:execute-silent(echo {} | clip)'"

# FZF directory navigation (added by init.windows.ps1)
# Use "cdf ." or "cdff ." to include hidden files/directories
function cdf {
    param([string]$opt)
    if ($opt -eq ".") {
        $selection = fd -a --hidden --type d | fzf
    } else {
        $selection = fd -a --type d | fzf
    }
    if ($selection) { Set-Location $selection }
}

function cdff {
    param([string]$opt)
    if ($opt -eq ".") {
        $selection = fd -a --hidden | fzf
    } else {
        $selection = fd -a | fzf
    }
    if ($selection) { Set-Location (Split-Path $selection -Parent) }
}
'@

if (!(Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    Add-Content -Path $PROFILE -Value $fzfFunctions
    Write-Host "Created PowerShell profile with cdf/cdff functions" -ForegroundColor Green
} else {
    # Remove existing fzf functions if present
    $profileContent = Get-Content $PROFILE -Raw
    if ($profileContent -match "# FZF (default options|directory navigation)") {
        # Remove old function block (from marker comment to end of cdff function)
        $profileContent = $profileContent -replace "(?s)# FZF default options.*?function cdff \{.*?\n\}", ""
        $profileContent = $profileContent -replace "(?s)# FZF directory navigation.*?function cdff \{.*?\n\}", ""
        $profileContent = $profileContent.Trim()
        Set-Content -Path $PROFILE -Value $profileContent -NoNewline
        Write-Host "Removed old fzf functions from PowerShell profile" -ForegroundColor Yellow
    }
    Add-Content -Path $PROFILE -Value $fzfFunctions
    Write-Host "Added fzf functions to PowerShell profile" -ForegroundColor Green
}

# =============================================================================
# Git Bash Setup (cdf/cdff functions in .bashrc)
# =============================================================================

Write-Host ""
Write-Host "Setting up Git Bash functions..." -ForegroundColor Cyan

$bashrcPath = "$env:USERPROFILE\.bashrc"

$bashFunctions = @'

# FZF default options (added by init.windows.ps1)
# Ctrl+Y copies current selection to clipboard
export FZF_DEFAULT_OPTS="--bind 'ctrl-y:execute-silent(echo {} | clip)'"

# FZF directory navigation (added by init.windows.ps1)
# Use "cdf ." or "cdff ." to include hidden files/directories
cdf() {
    local selection
    if [ "$1" = "." ]; then
        selection=$(fd -a --hidden --type d | fzf)
    else
        selection=$(fd -a --type d | fzf)
    fi
    [ -n "$selection" ] && cd "$selection"
}

cdff() {
    local selection
    if [ "$1" = "." ]; then
        selection=$(fd -a --hidden | fzf)
    else
        selection=$(fd -a | fzf)
    fi
    [ -n "$selection" ] && cd "$(dirname "$selection")"
}
'@

if (!(Test-Path $bashrcPath)) {
    New-Item -ItemType File -Path $bashrcPath -Force | Out-Null
    Add-Content -Path $bashrcPath -Value $bashFunctions
    Write-Host "Created .bashrc with cdf/cdff functions" -ForegroundColor Green
} else {
    # Remove existing fzf functions if present
    $bashContent = Get-Content $bashrcPath -Raw
    if ($bashContent -match "# FZF (default options|directory navigation)") {
        # Remove old function block (from marker comment to end of cdff function)
        $bashContent = $bashContent -replace "(?s)# FZF default options.*?cdff\(\) \{.*?\n\}", ""
        $bashContent = $bashContent -replace "(?s)# FZF directory navigation.*?cdff\(\) \{.*?\n\}", ""
        $bashContent = $bashContent.Trim()
        Set-Content -Path $bashrcPath -Value $bashContent -NoNewline
        Write-Host "Removed old fzf functions from .bashrc" -ForegroundColor Yellow
    }
    Add-Content -Path $bashrcPath -Value $bashFunctions
    Write-Host "Added fzf functions to .bashrc" -ForegroundColor Green
}

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
Write-Host "  - fd: $(fd --version 2>$null)" -ForegroundColor White
Write-Host "  - bat: $(bat --version 2>$null | Select-Object -First 1)" -ForegroundColor White
Write-Host "  - dotnet: $(dotnet --version 2>$null)" -ForegroundColor White
Write-Host "  - sqlcmd: $(if (Get-Command sqlcmd -ErrorAction SilentlyContinue) { 'installed' } else { 'not found' })" -ForegroundColor White
Write-Host "  - mysql: $(if (Get-Command mysql -ErrorAction SilentlyContinue) { 'installed' } else { 'not found' })" -ForegroundColor White
Write-Host "  - netcoredbg: $(if (Test-Path $netcoredbgExe) { 'installed' } else { 'not found' })" -ForegroundColor White
Write-Host "  - glazewm: $(if (Get-Command glazewm -ErrorAction SilentlyContinue) { 'installed' } else { 'not found' })" -ForegroundColor White
Write-Host "  - zebar: $(if (Get-Command zebar -ErrorAction SilentlyContinue) { 'installed' } else { 'not found' })" -ForegroundColor White
Write-Host "Shell wrappers:" -ForegroundColor Cyan
Write-Host "  - vim.bat: $vimBatPath" -ForegroundColor White
Write-Host "  - cdf.bat: $cdfBatPath" -ForegroundColor White
Write-Host "  - cdff.bat: $cdffBatPath" -ForegroundColor White
Write-Host "  - tools in PATH: $(if ($userPath -like "*$toolsDir*") { 'yes' } else { 'added (restart terminal)' })" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Restart your terminal (for PATH changes)" -ForegroundColor White
Write-Host "  2. Open Vim and run :PlugInstall" -ForegroundColor White
Write-Host "  3. Run :CocInstall coc-json coc-sql" -ForegroundColor White
Write-Host "  4. Run 'glazewm start' to launch the window manager" -ForegroundColor White
Write-Host ""
Write-Host "Note: Use :Q to quit vim and cd to current directory" -ForegroundColor Cyan
Write-Host "      Use :q to quit vim without changing directory" -ForegroundColor Cyan
Write-Host ""
Write-Host "GlazeWM keybindings:" -ForegroundColor Cyan
Write-Host "  Alt+H/J/K/L     - Focus window left/down/up/right" -ForegroundColor White
Write-Host "  Alt+Shift+H/J/K/L - Move window" -ForegroundColor White
Write-Host "  Alt+1-9         - Switch workspace" -ForegroundColor White
Write-Host "  Alt+Shift+1-9   - Move window to workspace" -ForegroundColor White
Write-Host "  Alt+Enter       - Open terminal" -ForegroundColor White
Write-Host "  Alt+Q           - Close window" -ForegroundColor White
Write-Host "  Alt+R           - Resize mode (HJKL to resize, Esc to exit)" -ForegroundColor White
Write-Host "  Alt+Shift+R     - Reload config" -ForegroundColor White
