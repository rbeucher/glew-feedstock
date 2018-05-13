#!/usr/bin/env bash

# PLEASE NOTE: This script has been automatically generated by conda-smithy. Any changes here
# will be lost next time ``conda smithy rerender`` is run. If you would like to make permanent
# changes to this script, consider a proposal to conda-smithy so that other feedstocks can also
# benefit from the improvement.

FEEDSTOCK_ROOT=$(cd "$(dirname "$0")/.."; pwd;)
RECIPE_ROOT=$FEEDSTOCK_ROOT/recipe

docker info

config=$(cat <<CONDARC

channels:
 - conda-forge
 - defaults

conda-build:
 root-dir: /home/conda/feedstock_root/build_artifacts

show_channel_urls: true

CONDARC
)

# In order for the conda-build process in the container to write to the mounted
# volumes, we need to run with the same id as the host machine, which is
# normally the owner of the mounted volumes, or at least has write permission
HOST_USER_ID=$(id -u)
# Check if docker-machine is being used (normally on OSX) and get the uid from
# the VM
if hash docker-machine 2> /dev/null && docker-machine active > /dev/null; then
    HOST_USER_ID=$(docker-machine ssh $(docker-machine active) id -u)
fi

rm -f "$FEEDSTOCK_ROOT/build_artifacts/conda-forge-build-done"

cat << EOF | docker run -i \
                        -v "${RECIPE_ROOT}":/home/conda/recipe_root \
                        -v "${FEEDSTOCK_ROOT}":/home/conda/feedstock_root \
                        -e CONFIG="$CONFIG" \
                        -e HOST_USER_ID="${HOST_USER_ID}" \
                        -a stdin -a stdout -a stderr \
                        condaforge/linux-anvil \
                        bash || exit 1

set -e
set +x
export BINSTAR_TOKEN=${BINSTAR_TOKEN}
set -x
export PYTHONUNBUFFERED=1

echo "$config" > ~/.condarc
# A lock sometimes occurs with incomplete builds. The lock file is stored in build_artifacts.
conda clean --lock

# Make sure we pull in the latest conda-build version too
conda install --yes --quiet conda-forge-ci-setup=1 conda-build
source run_conda_forge_build_setup


# Install the yum requirements defined canonically in the
# "recipe/yum_requirements.txt" file. After updating that file,
# run "conda smithy rerender" and this line be updated
# automatically.
/usr/bin/sudo -n yum install -y mesa-libGLU-devel


conda build /home/conda/recipe_root -m /home/conda/feedstock_root/.ci_support/${CONFIG}.yaml --quiet || exit 1
upload_or_check_non_existence /home/conda/recipe_root conda-forge --channel=main -m /home/conda/feedstock_root/.ci_support/${CONFIG}.yaml || exit 1

touch /home/conda/feedstock_root/build_artifacts/conda-forge-build-done
EOF

# double-check that the build got to the end
# see https://github.com/conda-forge/conda-smithy/pull/337
# for a possible fix
set -x
test -f "$FEEDSTOCK_ROOT/build_artifacts/conda-forge-build-done" || exit 1
