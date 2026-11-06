# AGS 自定义沙箱镜像：在官方 code 沙箱基础上预装 R 的 meta / metafor。
# 基础镜像自带 envd（49983）和 run_code 服务（49999），保留其 ENTRYPOINT，
# 这样 commands.run / files.* / run_code 仍然可用。
FROM ccr.ccs.tencentyun.com/ags-image/sandbox-code:latest

USER root

# 编译依赖始终安装：Debian 源缺少某个 R 包时，CRAN 源码安装需要它们（lme4 → nloptr 需要 cmake / libnlopt）。
# R 包优先装 Debian 二进制包，与基础镜像的 r-base-core 同源，避免编译和版本冲突；逐个安装，缺哪个跳过哪个。
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      r-base-dev gfortran cmake libnlopt-dev libcurl4-openssl-dev libssl-dev libxml2-dev \
 && for p in r-cran-metafor r-cran-meta r-cran-lme4 r-cran-metadat r-cran-mathjaxr r-cran-pbapply r-cran-numderiv; do \
      apt-get install -y --no-install-recommends "$p" || echo "Debian 源没有 $p，稍后从 CRAN 安装"; \
    done \
 && rm -rf /var/lib/apt/lists/*

ARG CRAN_MIRROR=https://cloud.r-project.org

# install.packages 失败只给 warning，这里显式检查并以非 0 退出，日志里能看到具体是哪个包失败。
RUN Rscript -e 'options(warn = 1); cat(R.version.string, "\n"); \
      need <- c("metafor", "meta"); \
      miss <- need[!vapply(need, requireNamespace, logical(1), quietly = TRUE)]; \
      cat("需要从 CRAN 安装:", if (length(miss)) miss else "无", "\n"); \
      if (length(miss)) install.packages(miss, repos = Sys.getenv("CRAN_MIRROR"), Ncpus = 4); \
      for (p in need) if (!requireNamespace(p, quietly = TRUE)) stop("R 包加载失败: ", p)' \
 && Rscript -e 'library(metafor); library(meta); cat("metafor", as.character(packageVersion("metafor")), "| meta", as.character(packageVersion("meta")), "\n")'
