# Trailer Capture (30–45s)

目标：快速产出一段可放在仓库首页或发布页的 30–45 秒原始演示视频。

## 建议录制结构（总计 35–40s）
1. `0–8s`：主菜单 -> 角色/地图/契约选择（展示“有选择的开局”）
2. `8–25s`：中期战斗（Fog + Sonar + Noise 条同时可见）
3. `25–35s`：追猎者或 Boss telegraph 与阶段变化
4. `35–40s`：结算/解锁弹窗（可选）

## 录制前设置
- 分辨率：`1920x1080`
- 帧率：`60fps`
- 关闭多余调试覆盖（保留必要 HUD）
- 固定 seed（便于重录一致镜头）

## macOS（ffmpeg + avfoundation）示例
先列设备：
```bash
ffmpeg -f avfoundation -list_devices true -i ""
```

录制（将 `1` 替换为你的屏幕设备索引）：
```bash
ffmpeg -f avfoundation -framerate 60 -video_size 1920x1080 -i "1:none" \
  -t 45 -pix_fmt yuv420p -vcodec libx264 -preset veryfast -crf 18 \
  media/trailer_raw_1080p60.mp4
```

## 裁剪到 30–45s 成片
```bash
ffmpeg -ss 00:00:02 -i media/trailer_raw_1080p60.mp4 -t 38 \
  -c copy media/trailer_cut.mp4
```

## 导出轻量预览（仓库可直接播放）
```bash
ffmpeg -i media/trailer_cut.mp4 -vf "scale=1280:-2" -r 30 \
  -vcodec libx264 -crf 23 -preset fast -pix_fmt yuv420p \
  media/trailer_preview_720p30.mp4
```

## 录制检查点
- 能看到 Fog 受限视野与声呐揭示对比
- 能看到噪声档位变化（静默/警戒/暴露）
- 至少一次追猎者或 Boss 预警提示
