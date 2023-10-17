#!/bin/bash

# This script is a wrapper over the main test script in
# https://github.com/rishucoding/reproduce_isca23_cpu_DLRM_inference.

# All results will be located in this directory, relative to the directory that
# this script is located in.
RESULTS_DIR="results"
mkdir -p $RESULTS_DIR

# Restore environment variables indicating paths to different directories.
EXPORTS_FILE="dlrm/paths.export"
while read -r LINE
do
    export $LINE
done < "$EXPORTS_FILE"

# Change line 441 of dlrm_s_pytorch.py from:
#
#   dlrm = ipex.optimize(dlrm, dtype=torch.float, inplace=True, auto_kernel_selection=True)
#
# to:
#
#   dlrm = ipex.optimize(dlrm, dtype=torch.float, inplace=True) # auto_kernel_selection=True)
#
# This change is needed to prevent the following error:
#
#   $BASE_PATH/miniconda3/envs/dlrm_cpu/lib/python3.9/site-packages/intel_extension_for_pytorch/frontend.py:262
#       UserWarning: Conv BatchNorm folding failed during the optimize process.
#       warnings.warn("Conv BatchNorm folding failed during the optimize process.")
#
# Based on the IPEX documentation at
# https://intel.github.io/intel-extension-for-pytorch/cpu/latest/tutorials/features.html,
# auto kernel selection is a feature that enables users to tune for better
# performance. So turning it off should not affect any functionality.
sed -i '441s/, auto/) # auto/1' \
        $MODELS_PATH/models/recommendation/pytorch/dlrm/product/dlrm_s_pytorch.py

# Modify the parameters in $DLRM_SYSTEM/scripts/collect_1s.sh as desired.
#
# The default number of iterations in collect_1s.sh is 64. Runtime seems to be
# approximately $NUM_ITERATIONS/64 * 3.7 sec. Max RSS seems to be approximately
# $NUM_ITERATIONS/64 * 0.3 GB + 8.2 GB.
OLD_ITERATIONS=64       # <-- change this if you previously modified the number
                        #     of iterations from the default of 64
NUM_ITERATIONS=128      # <-- change this to set the new number of iterations
sed -i "15s/--num-batches=$OLD_ITERATIONS/--num-batches=$NUM_ITERATIONS/1" \
        $DLRM_SYSTEM/scripts/collect_1s.sh

# Run the actual test.
export TEST_RESULTS_NAME=dlrm-$(date +%m%d)-$(date +%H%M%S)
/usr/bin/time -vo $RESULTS_DIR/$TEST_RESULTS_NAME.time $DLRM_SYSTEM/scripts/collect_1s.sh \
        1> $RESULTS_DIR/$TEST_RESULTS_NAME.stdout 2> $RESULTS_DIR/$TEST_RESULTS_NAME.stderr

# This log file is a duplicate of the log files created above.
rm -rf log_1s.txt
