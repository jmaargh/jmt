#!/bin/bash

set -eu

INSTALL_SUBDIR=".bash/themes/jmt"
INSTALL_DIR="${HOME}/${INSTALL_SUBDIR}"
REPO="https://github.com/jmaargh/jmt.git"
BASHRC="${HOME}/.bashrc"

if [[ -e ${INSTALL_DIR} ]]; then
  echo "ERROR: install directory ${INSTALL_DIR} already exists. Delete it and try again."
  exit 1
fi

if grep -Fq "${INSTALL_SUBDIR}" ${BASHRC}; then
  echo "ERROR: theme already appears to be in your ${BASHRC} file. Remove it and try again."
  exit 1
fi

mkdir -p ${INSTALL_DIR}
cd ${INSTALL_DIR}

git clone ${REPO} .

echo -e "\nexport THEME=\"${INSTALL_DIR}/jmt.bash\"; source \$THEME" >> ${BASHRC}

echo "INSTALL DONE :)"
