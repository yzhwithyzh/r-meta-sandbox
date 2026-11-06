# AGS 自定义沙箱镜像：在官方 code 沙箱基础上预装 R 的 meta / metafor。
# 基础镜像自带 envd（49983）和 run_code 服务（49999），保留其 ENTRYPOINT，
# 这样 commands.run / files.* / run_code 仍然可用。
FROM ccr.ccs.tencentyun.com/ags-image/sandbox-code:latest

USER root

# 现有沙箱的 R 来自 Debian 13 官方包（r-base-core 4.5.0），优先装同源的 Debian 二进制包，避免编译和版本冲突。
RUN apt-get update \
 && (apt-get install -y --no-install-recommends r-cran-metafor r-cran-meta \
     || apt-get install -y --no-install-recommends r-base-dev gfortran libcurl4-openssl-dev libssl-dev libxml2-dev) \
 && rm -rf /var/lib/apt/lists/*

ARG CRAN_MIRROR=https://cloud.r-project.org

# Debian 源缺包时从 CRAN 补装；最后一行确保两个包都能加载，否则构建失败。
RUN Rscript -e 'need <- c("metafor", "meta"); \
      miss <- need[!vapply(need, requireNamespace, logical(1), quietly = TRUE)]; \
      if (length(miss)) install.packages(miss, repos = Sys.getenv("CRAN_MIRROR"), Ncpus = 4)' \
 && Rscript -e 'library(metafor); library(meta); cat("metafor", as.character(packageVersion("metafor")), "| meta", as.character(packageVersion("meta")), "\n")'
