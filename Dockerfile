# AGS 自定义沙箱镜像：在官方 code 沙箱基础上预装 R 的 meta / metafor。
# 基础镜像自带 envd（49983）和 run_code 服务（49999），保留其 ENTRYPOINT，
# 这样 commands.run / files.* / run_code 仍然可用。
FROM ccr.ccs.tencentyun.com/ags-image/sandbox-code:latest

USER root

# 系统库：P3M 二进制包运行时需要；编译工具留作兜底（个别包没有二进制时从源码编译）。
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      r-base-dev gfortran cmake libnlopt-dev libcurl4-openssl-dev libssl-dev libxml2-dev \
 && rm -rf /var/lib/apt/lists/*

# Posit Package Manager 为 Debian 13 + R 4.5 提供预编译二进制包，免去 lme4/RcppEigen 等的漫长编译。
# P3M 依据 HTTPUserAgent 中的 R 版本判断是否返回二进制，必须按其要求设置。
ARG CRAN_MIRROR=https://packagemanager.posit.co/cran/__linux__/trixie/latest

# install.packages 失败只给 warning，这里显式检查并以非 0 退出，日志里能看到具体是哪个包失败。
RUN Rscript -e 'options(warn = 1, HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), \
        paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"]))); \
      cat(R.version.string, "| repo:", Sys.getenv("CRAN_MIRROR"), "\n"); \
      need <- c("metafor", "meta"); \
      install.packages(need, repos = Sys.getenv("CRAN_MIRROR"), Ncpus = 4); \
      for (p in need) if (!requireNamespace(p, quietly = TRUE)) stop("R 包加载失败: ", p)' \
 && Rscript -e 'library(metafor); library(meta); cat("metafor", as.character(packageVersion("metafor")), "| meta", as.character(packageVersion("meta")), "\n")'
