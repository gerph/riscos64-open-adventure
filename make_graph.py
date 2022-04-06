#!/usr/bin/env python3

# Make a DOT graph of the dungeon
#
# Copyright (c) 2017 by Eric S. Raymond
# SPDX-License-Identifier: BSD-2-clause

import sys, yaml

def allalike(loc):
    "Select out loci related to the Maze All Alike"
    return (loc == "LOC_MISTWEST") or ("ALIKE" in loc) or ("DEADEND" in loc) or ("STALACTITE" in loc)

if __name__ == "__main__":
    with open("adventure.yaml", "r") as f:
        db = yaml.safe_load(f)

    print("digraph G {")
    for (loc, attrs) in db["locations"]:
        if not allalike(loc):
            continue
        travel = attrs["travel"]
        if len(travel) > 0:
            for dest in travel:
                verbs = dest["verbs"]
                if len(verbs) == 0:
                    continue
                action = dest["action"]
                if action[0] == "goto":
                    arc = "%s -> %s" % (loc[4:], action[1][4:])
                    label=",".join(verbs).lower()
                    if len(label) > 0:
                        arc += ' [label="%s"]' % label
                    print("    " + arc)
    print("}")


