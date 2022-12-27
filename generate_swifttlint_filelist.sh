#!/usr/bin/env bash
#
# This script generates the input and output files for SwiftLint build phases for the targets we have in the project
# to improve the speed of incrementail builds: https://developer.apple.com/documentation/xcode/improving-the-speed-of-incremental-builds

# Get the git root path
SRC_ROOT=$(git rev-parse --show-toplevel)

mkdir -p "$SRC_ROOT/build/build_phases"

# Generate the input & output files in the build folder which is ignored by git
BUILD_FOLDER="$SRC_ROOT/build/build_phases"

# The path of the result file where we save the current git diff
RESULT_FILE=$BUILD_FOLDER/git_diff_result

# Create the result file if it doesn't exist yet
if [ ! -f $RESULT_FILE ]
then
	echo "creating result file"
	# Add a dummy text to the file, so we generate the input files when the file didn't exist before and git has no changes
	echo -n "dummy" > "$RESULT_FILE"
fi

# Check if there is any .swift file added / deleted / renamed in the current git changes
NEW_FILES=`git diff HEAD --name-only --diff-filter=ADR -- '***.swift'`

# Load the git diff result from the last compilation
PREV_GIT_RESULT=$(<"$RESULT_FILE")

# If there were no new .swift or .m files added since the last compilation, we don't need to regenerate the input files
if [[ "$PREV_GIT_RESULT" == "$NEW_FILES" ]]; then
	echo "No changes since last git diff, do nothing"
	exit 0
fi

# Store the current git diff for the next run
echo -n "$NEW_FILES" > "$RESULT_FILE"
echo "Generating new source file list"

# List of folders in which we generate filelist only for Swiftlint (e.g. only .swift)
swiftlint_dirs=(
    'SwiftlintBuildPhase'
    'SwiftlintBuildPhaseTests'
    'SwiftlintBuildPhaseUITests'
)

for dir in "${swiftlint_dirs[@]}"
do
    find "${dir}" -type f -name "*.swift" | sed -e 's/^/$(SRCROOT)\//;' > "$BUILD_FOLDER/${dir}_swiftlint.xcfilelist"
    touch "${BUILD_FOLDER}/${dir}_swiftlint_static_output"
done