#!/bin/bash
# Copyright (c) 2023-2024, NVIDIA CORPORATION.

set -euo pipefail

package_name=$1
package_dir=$2
underscore_package_name=$(echo "${package_name}" | tr "-" "_")

# Clear out system ucx files to ensure that we're getting ucx from the wheel.
rm -rf /usr/lib64/ucx
rm -rf /usr/lib64/libuc*

source rapids-configure-sccache
source rapids-date-string

version=$(rapids-generate-version)
git_commit=$(git rev-parse HEAD)

RAPIDS_PY_CUDA_SUFFIX="$(rapids-wheel-ctk-name-gen ${RAPIDS_CUDA_VERSION})"

# This is the version of the suffix with a preceding hyphen. It's used
# everywhere except in the final wheel name.
PACKAGE_CUDA_SUFFIX="-${RAPIDS_PY_CUDA_SUFFIX}"

# Patch project metadata files to include the CUDA version suffix and version override.
pyproject_file="${package_dir}/pyproject.toml"
version_file="${package_dir}/${underscore_package_name}/_version.py"

sed -i "s/name = \"${package_name}\"/name = \"${package_name}${PACKAGE_CUDA_SUFFIX}\"/g" ${pyproject_file}
echo "${version}" > VERSION
sed -i "/^__git_commit__ / s/= .*/= \"${git_commit}\"/g" ${version_file}

# For nightlies we want to ensure that we're pulling in alphas as well. The
# easiest way to do so is to augment the spec with a constraint containing a
# min alpha version that doesn't affect the version bounds but does allow usage
# of alpha versions for that dependency without --pre
alpha_spec=''
if ! rapids-is-release-build; then
    alpha_spec=',>=0.0.0a0'
fi

if [[ ${package_name} == "raft-dask" ]]; then
    sed -r -i "s/pylibraft==(.*)\"/pylibraft${PACKAGE_CUDA_SUFFIX}==\1${alpha_spec}\"/g" ${pyproject_file}
    sed -r -i "s/libucx(.*)\"/libucx${PACKAGE_CUDA_SUFFIX}\1${alpha_spec}\"/g" ${pyproject_file}
    sed -r -i "s/ucx-py==(.*)\"/ucx-py${PACKAGE_CUDA_SUFFIX}==\1${alpha_spec}\"/g" ${pyproject_file}
    sed -r -i "s/rapids-dask-dependency==(.*)\"/rapids-dask-dependency==\1${alpha_spec}\"/g" ${pyproject_file}
    sed -r -i "s/dask-cuda==(.*)\"/dask-cuda==\1${alpha_spec}\"/g" ${pyproject_file}
    sed -r -i "s/distributed-ucxx==(.*)\"/distributed-ucxx${PACKAGE_CUDA_SUFFIX}==\1${alpha_spec}\"/g" ${pyproject_file}
else
    sed -r -i "s/rmm(.*)\"/rmm${PACKAGE_CUDA_SUFFIX}\1${alpha_spec}\"/g" ${pyproject_file}
fi

if [[ $PACKAGE_CUDA_SUFFIX == "-cu12" ]]; then
    sed -i "s/cuda-python[<=>\.,0-9a]*/cuda-python>=12.0,<13.0a0/g" ${pyproject_file}
    sed -i "s/cupy-cuda11x/cupy-cuda12x/g" ${pyproject_file}
fi

cd "${package_dir}"

# Hardcode the output dir
python -m pip wheel . -w dist -vvv --no-deps --disable-pip-version-check

mkdir -p final_dist
python -m auditwheel repair -w final_dist --exclude "libucp.so.0" dist/*

RAPIDS_PY_WHEEL_NAME="${underscore_package_name}_${RAPIDS_PY_CUDA_SUFFIX}" rapids-upload-wheels-to-s3 final_dist
