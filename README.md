# AGS 自定义沙箱镜像：R + meta / metafor

基于腾讯云 AGS 官方 code 沙箱镜像（`ccr.ccs.tencentyun.com/ags-image/sandbox-code`），预装 R 的 `meta` 和 `metafor`。
GitHub Actions 自动构建 linux/amd64 镜像，并推送到腾讯云个人版镜像仓库：

`ccr.ccs.tencentyun.com/r_meta/r-meta-sandbox:v1`

## 仓库 Secrets

| 名称 | 值 |
|------|----|
| `CCR_USERNAME` | 腾讯云主账号 ID（控制台右上角头像里能看到） |
| `CCR_PASSWORD` | 容器镜像服务个人版的登录密码 |

## 触发方式

- 推送到 `main` 分支、并且改动了 `Dockerfile` 或工作流文件时，自动构建；
- 也可以在 Actions 页面手动运行 workflow_dispatch，并指定镜像标签。
