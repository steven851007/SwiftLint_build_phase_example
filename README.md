# SwiftLint Build Phases with Xcode Input Output Files

This repository contains an example project demonstrating how to set up SwiftLint build phases using Xcode's input-output files feature by defining a pre-build action to generate the input file list for SwiftLint. This setup solves the new warning introduced in Xcode 14:

`warning build: Run script build phase 'SwiftLint' will be run during every build because it does not specify any outputs. To address this warning, either add output dependencies to the script phase, or configure it to run in every build by unchecking "Based on dependency analysis" in the script phase.`

Other than solving the warning, this will also improve the speed of incremental builds in Xcode.

Table of contents
-----------------

* [What is SwiftLint?](#what-is-swiftlint)
* [Why use Xcode input-output files?](#why-use-xcode-input-output-files)
* [Project setup](#project-setup)
* [How it works](#how-it-works)
* [How to set this up in your project](#how-to-set-this-up-in-your-project)
* [Known issues](#known-issues)

## What is SwiftLint?

SwiftLint is a static analysis tool for Swift code that helps developers enforce style and conventions in their projects. It can be run as a build phase in Xcode to automatically check for linting issues as part of the build process.

## Why use Xcode input-output files?

Xcode's input-output files feature allows you to specify which files should be used as input to a build phase and which files should be generated as output. This can be useful when running tools like SwiftLint, as it allows you to only run the build phase when certain input files have changed, rather than running it every time the project is built. This can significantly improve build times, especially for build phases that take a long time to complete.

## Project setup
I set up SwiftLint build phases with Xcode input-output files by following these steps:

- Have SwiftLint set up as a "Build Phase" as explained in the [SwiftLint documentation.](https://github.com/realm/SwiftLint#usage)
- Add a new pre-action build script under Edit Scheme -> Build -> Pre-actions called "Generate build phase file lists."
- Select your Scheme for the "Provide build settings from" drop-down menu
<img width="936" alt="Screenshot 2022-12-27 at 16 30 17" src="https://user-images.githubusercontent.com/1866462/209645202-0ff8d7e9-2595-47cc-9d05-9fe6c8b76eaf.png">
- Add the following code for the pre-build script:

```bash
cd $SOURCE_ROOT
${SOURCE_ROOT}/generate_swifttlint_filelist.sh
```

- Add the `generate_swifttlint_filelist.sh` [script file](generate_swifttlint_filelist.sh) to the project
- For all three targets (SwiftlintBuildPhase, SwiftlintBuildPhaseTests, SwiftlintBuildPhaseUITests), enable the "Based on dependency analysis" checkbox under the SwiftLint build phase
- Set up the input file lists and output for every target under the build phases using the matching generated file:
<img width="683" alt="Screenshot 2022-12-27 at 16 43 23" src="https://user-images.githubusercontent.com/1866462/209647075-5c74c6b0-bc3b-4204-9858-f8acaec58a86.png">

- Hit Cmd+U in the project twice and check the build time under the Report Navigator. Hit Control+Option+Cmd+Enter to show the Recent build timeline and check Xcode didn't run SwiftLint when no file has changed:
<img width="878" alt="Screenshot 2022-12-27 at 16 51 59" src="https://user-images.githubusercontent.com/1866462/209649731-b6fa573e-2bc3-42eb-80d3-792b9c6c5c5e.png">

- Add a new .swift file / change a swift file. Hit Cmd+U again, and check Xcode run SwiftLint only for the target a change occurred:
<img width="1407" alt="Screenshot 2022-12-27 at 17 01 50" src="https://user-images.githubusercontent.com/1866462/209649629-c5404e56-0a97-4880-bc8a-9a454b18fa9d.png">

## How it works

Xcode needs the input file list for the SwiftLint build phase to determine when to run SwiftLint. We want to run SwiftLint whenever we change a swift file in the current target or add a new file to the project. Unfortunately, we can't define a folder as an input file list therefore, we have to define a file list with the paths to all swift source files. Since the list of source files changes when we add, delete or rename files, we need to generate the input file list dynamically before every build. This is precisely what the [generate_swifttlint_filelist.sh](generate_swifttlint_filelist.sh) is doing that runs as a pre-action build script.

I've added comments to the script file, but here is an overview of what it is doing:
- The script compares the current git diff to the git diff from the previous build and determines if there was any change to the swift files list e.g.: added, deleted, or renamed
- If there was a change since the last build, it generates the new input file list for all targets
- If there is no change, it does nothing.
- The script generates an input file list (.xcfilelist) and output file list for every target defined in the `swiftlint_dirs` variable
- The script generates these files into the `/build/build_phases` folder, which git ignores.

## How to set this up in your project

Follow the setup defined in the [Project setup](#project-setup). All you need to change is the `swiftlint_dirs` variable to match your source folders and set up the correct input-output file list in your target's SwiftLint build phase. You can also change the location of the generated files.

## Known issues

Xcode has a bug handling the shared xcschemes where the pre-action script is defined. When we switch branches between two branches where one has the pre-action script defined and the other doesn't, it doesn't update the changes from the new branch but keeps the old one. This can cause an error in the build logs or a build failure. Restarting Xcode and discarding the changes in the .xcodeproj file solves this issue.

This issue will go away as soon as all branch has the newly defined pre-action build definition.
