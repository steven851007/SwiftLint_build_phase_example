#!/usr/bin/env bash
#
# This script generates the input and output files for SwiftLint build phases for the targets we have in the project
# to improve the speed of incrementail builds: https://developer.apple.com/documentation/xcode/improving-the-speed-of-incremental-builds

# Get the git root path
SRC_ROOT=$(git rev-parse --show-toplevel)

# Create a directory where we store the input/output files. This should be a folder that is ignored by git.
mkdir -p "$SRC_ROOT/build/build_phases"

# Path to this new folder where we generate the input & output files
BUILD_FOLDER="$SRC_ROOT/build/build_phases"

# The path of the result file where we save the current git diff
RESULT_FILE=$BUILD_FOLDER/git_diff_result

# Create the result file if it doesn't exist yet
if [ ! -f $RESULT_FILE ]
then
	echo "creating result file"
	# Add a dummy text to the file, so we generate the input files when the file didn't exist before and git has no changes.
	echo -n "dummy" > "$RESULT_FILE"
fi

# Check if there is any .swift file added / deleted / renamed in the current git changes
NEW_FILES=`git diff HEAD --name-only --diff-filter=ADR -- '***.swift'`

# Load the git diff result from the last compilation
PREV_GIT_RESULT=$(<"$RESULT_FILE")

# If there were no new .swift files added since the last compilation, we don't need to regenerate the input files
if [[ "$PREV_GIT_RESULT" == "$NEW_FILES" ]]; then
	echo "No changes since last git diff, do nothing"
	exit 0
fi

# Store the current git diff for the next run
echo -n "$NEW_FILES" > "$RESULT_FILE"
echo "Generating new source file list"

# List of folders in which we generate filelist for Swiftlint (e.g. only .swift)
swiftlint_dirs=(
    'SwiftlintBuildPhase'
    'SwiftlintBuildPhaseTests'
    'SwiftlintBuildPhaseUITests'
)

for dir in "${swiftlint_dirs[@]}"
do
	# Find all .swift files in the folder to create the xcfilelist file for the SwiftLint build script
    find "${dir}" -type f -name "*.swift" | sed -e 's/^/$(SRCROOT)\//;' > "$BUILD_FOLDER/${dir}_swiftlint.xcfilelist"
    # Create a static empty output file. We need to create these empty output files as stated in the documentation linked above:
    # "You must still specify an input and output file to prevent Xcode from running the script every time, even if your script doesn’t actually require those files. 
    # For a script that requires no input, provide a file that never changes as the input file. For a script with no outputs, create a static output file from your script so Xcode has something to check."
    touch "${BUILD_FOLDER}/${dir}_swiftlint_static_output"
done