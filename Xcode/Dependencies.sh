#!/bin/bash

cd "$SRCROOT/.."

if [[ $ACTION == "clean" ]]; then
    echo "Cleaning built products"
    rm .build/debug/.dependencies-ready &>/dev/null
    swift build --clean build
    exit $?
fi

if [ Package.swift -nt Packages ]; then
    echo "Dependencies will be fetched again because Package.swift is newer than the Packages folder."
    swift build --clean dist
fi

if [ -a ".build/debug/.dependencies-ready" ]; then
    # Nothing to do
    echo "Dependencies already present. Not rebuilding."
    exit $0
fi

# Run swift build
swift build 2>&1 | sed -l -e "s/: warning:/info: a dependency is complaining:/"
if [[ $? != 0 ]]; then
    exit $?
fi

# Generate the config file

linkerflags="\$(inherited)"

for f in .build/debug/*.a; do
  fname=$("basename" $f ".a")
  # linkerflags+=" -l$fname"
  linkerflags+=" \$(SRCROOT)/../$f"
done

echo "Linker flags: $linkerflags"

cat > "$SRCROOT/SPM.xcconfig" <<EOF
LIBRARY_SEARCH_PATHS = \$(inherited) \$(SRCROOT)/../.build/debug
SWIFT_INCLUDE_PATHS = \$(inherited) \$(SRCROOT)/../.build/debug \$(SRCROOT)/../Packages/**
OTHER_LDFLAGS = \$(inherited) -L\$(SRCROOT)/../.build/debug $linkerflags
EOF

touch .build/debug/.dependencies-ready
