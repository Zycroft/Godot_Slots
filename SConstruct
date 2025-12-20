#!/usr/bin/env python
import os
import sys

env = SConscript("godot-cpp/SConstruct")

# Add source files
env.Append(CPPPATH=["src/"])
sources = Glob("src/*.cpp")

# Build the shared library
if env["platform"] == "macos":
    library = env.SharedLibrary(
        "bin/libroguelike_slots.{}.{}.framework/libroguelike_slots.{}.{}".format(
            env["platform"], env["target"], env["platform"], env["target"]
        ),
        source=sources,
    )
else:
    library = env.SharedLibrary(
        "bin/libroguelike_slots{}{}".format(env["suffix"], env["SHLIBSUFFIX"]),
        source=sources,
    )

Default(library)
