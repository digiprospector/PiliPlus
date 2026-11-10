# Windows 专属补丁脚本：针对当前项目实际依赖的 material_ui 打补丁
$WorkspaceDir = (Get-Item .).FullName

# 优先精准定位当前项目生效的 material_ui 目录
$MaterialUiPath = $null
if (Test-Path ".dart_tool/package_config.json") {
    $pkgConfig = Get-Content ".dart_tool/package_config.json" -Raw | ConvertFrom-Json
    $pkg = $pkgConfig.packages | Where-Object { $_.Name -eq "material_ui" }
    if ($pkg) {
        $MaterialUiPath = [System.Uri]::new($pkg.rootUri).LocalPath
    }
}

if (-not $MaterialUiPath -or -not (Test-Path $MaterialUiPath)) {
    $PubCacheDir = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { "$env:LOCALAPPDATA/Pub/Cache" }
    $MaterialUiDir = Get-ChildItem "$PubCacheDir/hosted/*" -Directory -ErrorAction SilentlyContinue |
        Get-ChildItem -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "material_ui-1.10*" } |
        Select-Object -First 1
    if ($MaterialUiDir) {
        $MaterialUiPath = $MaterialUiDir.FullName
    }
}

if (-not $MaterialUiPath -or -not (Test-Path $MaterialUiPath)) {
    Write-Error "未找到 material_ui-1.10.0 依赖目录，请先执行 flutter pub get"
    exit 1
}

Write-Host "精准定位到当前项目依赖目录: $MaterialUiPath"

$patches = @(
    "lib/scripts/material/modal_barrier_material.patch",
    "lib/scripts/material/navigation_drawer.patch",
    "lib/scripts/material/popup_menu.patch",
    "lib/scripts/material/fab.patch",
    "lib/scripts/material/text_field.patch",
    "lib/scripts/material/scaffold.patch",
    "lib/scripts/material/refresh_indicator.patch",
    "lib/scripts/material/tabs.patch"
)

Push-Location $MaterialUiPath
try {
    # 临时初始化 git 以便执行 git apply
    $hasGit = Test-Path ".git"
    if (-not $hasGit) {
        git init 2>$null
    }

    foreach ($patch in $patches) {
        $patchFile = "$WorkspaceDir/$patch"

        # 检查是否已打过补丁
        git apply --reverse --check --ignore-whitespace $patchFile 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$patch 已经打过，跳过。"
            continue
        }

        git apply --ignore-whitespace $patchFile
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$patch 应用成功！"
        } else {
            Write-Error "$patch 应用失败！"
        }
    }
}
finally {
    if (-not $hasGit -and (Test-Path ".git")) {
        Remove-Item -Path ".git" -Recurse -Force -ErrorAction SilentlyContinue
    }
    Pop-Location
}

Write-Host "`nWindows 所需的所有补丁已就绪！"
