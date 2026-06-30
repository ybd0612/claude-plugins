# Claude Code 任务完成通知脚本
# 功能：屏幕边缘 RGB 跑马灯特效 + 任务栏闪烁 + 声音提示

param(
    [int]$GlowDuration = 10,     # 发光持续秒数
    [int]$GlowThickness = 40,    # 发光边缘厚度（像素）
    [switch]$Glow                # 内部参数：子进程模式标记
)

# ── HSV 转 RGB 辅助函数 ─────────────────────────────────────────
function Convert-HsvToRgb([double]$h, [double]$s, [double]$v) {
    # h: 0~360, s: 0~1, v: 0~1
    $c = $v * $s
    $x = $c * (1 - [Math]::Abs(($h / 60) % 2 - 1))
    $m = $v - $c
    $r = $g = $b = 0.0
    switch ([Math]::Floor($h / 60) % 6) {
        0 { $r = $c; $g = $x; $b = 0 }
        1 { $r = $x; $g = $c; $b = 0 }
        2 { $r = 0;  $g = $c; $b = $x }
        3 { $r = 0;  $g = $x; $b = $c }
        4 { $r = $x; $g = 0;  $b = $c }
        5 { $r = $c; $g = 0;  $b = $x }
    }
    return [System.Windows.Media.Color]::FromRgb(
        [byte][Math]::Round(($r + $m) * 255),
        [byte][Math]::Round(($g + $m) * 255),
        [byte][Math]::Round(($b + $m) * 255))
}

# ── 生成渐变画刷（带跑马灯偏移）──────────────────────────────────
function New-MarqueeBrush([int]$startHue, [int]$endHue, [double]$offset,
                          [string]$dir) {
    $bright = Convert-HsvToRgb (($startHue + $offset * ($endHue - $startHue)) % 360) 1.0 1.0
    $tail   = Convert-HsvToRgb ($startHue % 360) 1.0 0.6
    $head   = Convert-HsvToRgb ($endHue % 360)   1.0 0.6
    $trans  = [System.Windows.Media.Color]::FromArgb(0, 0, 0, 0)

    $brush = [System.Windows.Media.LinearGradientBrush]::new()
    $brush.MappingMode = [System.Windows.Media.BrushMappingMode]::RelativeToBoundingBox

    if ($dir -eq 'Horizontal') {
        $brush.StartPoint = '0,0.5'; $brush.EndPoint = '1,0.5'
    } else {
        $brush.StartPoint = '0.5,0'; $brush.EndPoint = '0.5,1'
    }

    $s0 = [System.Windows.Media.GradientStop]::new($trans, 0.0)
    $s1 = [System.Windows.Media.GradientStop]::new($tail,   0.25)
    $s2 = [System.Windows.Media.GradientStop]::new($bright, 0.5)
    $s3 = [System.Windows.Media.GradientStop]::new($head,   0.75)
    $s4 = [System.Windows.Media.GradientStop]::new($trans, 1.0)
    $brush.GradientStops.Add($s0) | Out-Null
    $brush.GradientStops.Add($s1) | Out-Null
    $brush.GradientStops.Add($s2) | Out-Null
    $brush.GradientStops.Add($s3) | Out-Null
    $brush.GradientStops.Add($s4) | Out-Null
    return $brush
}

# ── 如果带 -Glow 参数，执行 WPF 跑马灯特效（子进程模式）────────
if ($Glow) {
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    # Win32 API：防止窗口抢焦点 + 鼠标穿透
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class NoFocus {
    public const int GWL_EXSTYLE = -20;
    public const int WS_EX_NOACTIVATE  = 0x08000000;
    public const int WS_EX_TOPMOST     = 0x00000008;
    public const int WS_EX_TOOLWINDOW  = 0x00000080;
    public const int WS_EX_TRANSPARENT = 0x00000020;

    [DllImport("user32.dll")]
    public static extern int GetWindowLong(IntPtr hWnd, int nIndex);
    [DllImport("user32.dll")]
    public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);
}
"@

    try {
        $xaml = @"
<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
        WindowStyle='None'
        AllowsTransparency='True'
        Background='Transparent'
        Topmost='True'
        ShowInTaskbar='False'
        Focusable='False'
        IsHitTestVisible='False'>
    <Grid x:Name='Root'>
        <Rectangle x:Name='EdgeTop' VerticalAlignment='Top' Height='$GlowThickness'>
            <Rectangle.OpacityMask>
                <LinearGradientBrush StartPoint='0.5,0' EndPoint='0.5,1'>
                    <GradientStop Color='White' Offset='0'/>
                    <GradientStop Color='Transparent' Offset='1'/>
                </LinearGradientBrush>
            </Rectangle.OpacityMask>
        </Rectangle>
        <Rectangle x:Name='EdgeBottom' VerticalAlignment='Bottom' Height='$GlowThickness'>
            <Rectangle.OpacityMask>
                <LinearGradientBrush StartPoint='0.5,1' EndPoint='0.5,0'>
                    <GradientStop Color='White' Offset='0'/>
                    <GradientStop Color='Transparent' Offset='1'/>
                </LinearGradientBrush>
            </Rectangle.OpacityMask>
        </Rectangle>
        <Rectangle x:Name='EdgeLeft' HorizontalAlignment='Left' Width='$GlowThickness'>
            <Rectangle.OpacityMask>
                <LinearGradientBrush StartPoint='0,0.5' EndPoint='1,0.5'>
                    <GradientStop Color='White' Offset='0'/>
                    <GradientStop Color='Transparent' Offset='1'/>
                </LinearGradientBrush>
            </Rectangle.OpacityMask>
        </Rectangle>
        <Rectangle x:Name='EdgeRight' HorizontalAlignment='Right' Width='$GlowThickness'>
            <Rectangle.OpacityMask>
                <LinearGradientBrush StartPoint='1,0.5' EndPoint='0,0.5'>
                    <GradientStop Color='White' Offset='0'/>
                    <GradientStop Color='Transparent' Offset='1'/>
                </LinearGradientBrush>
            </Rectangle.OpacityMask>
        </Rectangle>
    </Grid>
</Window>
"@

        $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
        $window = [System.Windows.Markup.XamlReader]::Load($reader)

        # 获取命名元素
        $edgeTop    = $window.FindName('EdgeTop')
        $edgeBottom = $window.FindName('EdgeBottom')
        $edgeLeft   = $window.FindName('EdgeLeft')
        $edgeRight  = $window.FindName('EdgeRight')

        # 全屏覆盖
        $window.Left   = 0
        $window.Top    = 0
        $window.Width  = [System.Windows.SystemParameters]::PrimaryScreenWidth
        $window.Height = [System.Windows.SystemParameters]::PrimaryScreenHeight

        # ── 跑马灯动画状态 ───────────────────────────────────
        $script:hueOffset  = 0.0     # 色相偏移（持续递增）
        $script:marqueePos = 0.0     # 光带位置（0~1 循环）
        $script:glowTicks  = 0
        $maxTicks = $GlowDuration

        # 帧率：~60fps，每帧间隔 16ms
        $frameInterval = [TimeSpan]::FromMilliseconds(16)

        # 跑马灯动画定时器（高频）
        $animTimer = New-Object System.Windows.Threading.DispatcherTimer
        $animTimer.Interval = $frameInterval

        $animTimer.Add_Tick({
            # 色相每秒约 120 度，约 3 秒完成一圈彩虹
            $script:hueOffset = ($script:hueOffset + 2.0) % 360
            # 光带位置每秒约移 0.3（约 3.3 秒跑完一圈）
            $script:marqueePos = ($script:marqueePos + 0.005) % 1.0

            $hp = $script:marqueePos

            # 四条边各自的色相范围（各占周长的 1/4，形成彩虹过渡）
            $hueStart = [int]$script:hueOffset
            $edgeTop.Fill    = New-MarqueeBrush ($hueStart)       ($hueStart + 60)  $hp 'Horizontal'
            $edgeRight.Fill  = New-MarqueeBrush ($hueStart + 90)  ($hueStart + 150) $hp 'Vertical'
            $edgeBottom.Fill = New-MarqueeBrush ($hueStart + 180) ($hueStart + 240) $hp 'Horizontal'
            $edgeLeft.Fill   = New-MarqueeBrush ($hueStart + 270) ($hueStart + 330) $hp 'Vertical'
        })

        # 呼吸效果（整体透明度脉动）
        $opacityAnim = [System.Windows.Media.Animation.DoubleAnimation]::new()
        $opacityAnim.From     = 0.2
        $opacityAnim.To       = 0.85
        $opacityAnim.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(800))
        $opacityAnim.AutoReverse = $true
        $opacityAnim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever

        # 淡出动画
        $fadeOut = [System.Windows.Media.Animation.DoubleAnimation]::new()
        $fadeOut.To       = 0.0
        $fadeOut.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(500))

        # 持续时间计时器（每秒检查一次，到期后淡出关闭）
        $durationTimer = New-Object System.Windows.Threading.DispatcherTimer
        $durationTimer.Interval = [TimeSpan]::FromSeconds(1)
        $durationTimer.Add_Tick({
            $script:glowTicks++
            if ($script:glowTicks -ge $maxTicks) {
                $durationTimer.Stop()
                $animTimer.Stop()
                $fadeOut.Add_Completed({ $window.Close() })
                $window.BeginAnimation([System.Windows.Window]::OpacityProperty, $fadeOut)
            }
        })

        $window.Add_SourceInitialized({
            # 设置 WS_EX_NOACTIVATE + WS_EX_TRANSPARENT：置顶、不抢焦点、鼠标穿透
            $helper = New-Object System.Windows.Interop.WindowInteropHelper($window)
            $hwnd = $helper.Handle
            $exStyle = [NoFocus]::GetWindowLong($hwnd, [NoFocus]::GWL_EXSTYLE)
            [NoFocus]::SetWindowLong($hwnd, [NoFocus]::GWL_EXSTYLE,
                $exStyle -bor [NoFocus]::WS_EX_NOACTIVATE -bor [NoFocus]::WS_EX_TOOLWINDOW -bor [NoFocus]::WS_EX_TRANSPARENT) | Out-Null

            $window.BeginAnimation([System.Windows.Window]::OpacityProperty, $opacityAnim)
            $animTimer.Start()
            $durationTimer.Start()
        })

        $window.ShowDialog() | Out-Null
    }
    catch {
        Write-Error "WPF 跑马灯特效失败: $_"
    }
    exit
}

# ── 主进程逻辑（从 Claude Code hook 调用时执行）─────────────────

# 1. 用 Start-Process 启动独立进程运行 WPF 发光特效
#    关键修复：Start-Job 无法创建 WPF 窗口，必须用 Start-Process 启动新进程
$scriptPath = $MyInvocation.MyCommand.Path
Start-Process pwsh -ArgumentList @(
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-WindowStyle', 'Hidden',
    '-File', $scriptPath,
    '-GlowDuration', "$GlowDuration",
    '-GlowThickness', "$GlowThickness",
    '-Glow'
) -WindowStyle Hidden -ErrorAction SilentlyContinue

# 2. Windows 系统通知弹窗
Add-Type -AssemblyName System.Windows.Forms
$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = [System.Drawing.SystemIcons]::Information
$notify.Visible = $true
$notify.BalloonTipTitle = 'Claude Code'
$notify.BalloonTipText = '任务执行完成！'
$notify.BalloonTipIcon = 'Info'
$notify.ShowBalloonTip(5000)
# 3 秒后释放资源（不阻塞过久）
Start-Sleep -Seconds 3
$notify.Dispose()

# 3. 系统提示音
try { [System.Media.SystemSounds]::Asterisk.Play() } catch {}
