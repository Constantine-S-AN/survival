# DayWorld Visual Pass 2 Asset Note

日期: 2026-03-08

## 新增外部素材

本轮只引入了同一作者 `zedpxl` 的小规模 top-down 像素资源，用来统一 DayWorld / Shop 的“温暖村镇”方向。

使用到的资源:
- `Pixel 16 Village V2 Top-Down Asset Pack`
  - 页面: [https://zedpxl.itch.io/pixel-16-village-v2-top-down-asset-pack](https://zedpxl.itch.io/pixel-16-village-v2-top-down-asset-pack)
  - 仓库内使用文件: `assets/external/dayworld_visual_pass_2/unpacked/village/Pixel 16 v2 village free/Pixel 16 v2 village free.png`
  - 用途: 农舍 / 餐馆 / 商店摊位 / 路灯 / 长椅 / 花箱 / 木箱
- `Pixel 16 Woods V2 Top-Down Asset Pack`
  - 页面: [https://zedpxl.itch.io/pixel-16-woods-v2-top-down-asset-pack](https://zedpxl.itch.io/pixel-16-woods-v2-top-down-asset-pack)
  - 仓库内使用文件: `assets/external/dayworld_visual_pass_2/unpacked/forest/pixel_16_woods v2 free/free_pixel_16_woods.png`
  - 用途: 树 / 灌木 patch / 水边 patch / 小岩石 / 水草
- `Pixel 16 Interiors V2 Top-Down Asset Pack`
  - 页面: [https://zedpxl.itch.io/pixel-16-interiors-v2-top-down-asset-pack](https://zedpxl.itch.io/pixel-16-interiors-v2-top-down-asset-pack)
  - 仓库内使用文件: `assets/external/dayworld_visual_pass_2/unpacked/interior/Pixel_16_interiors_v2_free/tiles and items.png`
  - 用途: 商店 interior 墙饰 / 窗 / 沙发 / 桌椅 / 盆栽 / 等候角

## 使用策略

这些资源本轮只用于:
- exterior building silhouettes
- outdoor props / foliage / landmark dressing
- shop interior furniture and wall dressing

这些资源不再用于:
- DayWorld 底层 grass / path / water atlas
- Shop 底层 floor atlas

原因:
- 这几张 free PNG 本质上是 object / prop sheet，不是完整 tileset。
- 把它们当作地砖切片会导致地表出现大块失真像素，破坏 authored 感。

## 许可备注

下载页面展示的许可摘要包含:
- 可用于 non-commercial 和 commercial 项目
- 可修改
- 不可转售 / 再分发素材本身
- 不可用于 AI / NFT 相关项目

本轮仓库只保留运行所需的最小 PNG 文件，没有把原始下载 zip 作为交付内容纳入版本控制。

注意:
- 上述许可说明来自资源页面摘要，而不是单独的仓库 LICENSE 文件。
- 如果后续要把本仓库公开或以素材源码形式再分发，建议再次人工复核 `zedpxl` 的最新许可页面，并评估是否需要改成首次构建时手动下载的接入方式。

## 未引入内容

本轮没有新增插件。
