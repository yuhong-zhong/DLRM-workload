#!/bin/bash

# Restore environment variables indicating paths to different directories.
source dlrm/paths.export

cd $MODELS_PATH
/bin/bash $DLRM_SYSTEM/scripts/collect_1s.sh
