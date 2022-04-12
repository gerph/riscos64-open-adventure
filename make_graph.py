#!/usr/bin/env python3

# Make a DOT graph of the dungeon
#
# Copyright (c) 2017 by Eric S. Raymond
# SPDX-License-Identifier: BSD-2-clause

import sys, yaml

def allalike(loc, dest):
    "Select out loci related to the Maze All Alike"
    return ("ALIKE" in loc) or ("MAZEEND" in loc) or ("STALACTITE" in loc) or (loc == "LOC_MISTWEST" and "ALIKE" in dest) 

def abbreviate(d):
    m = {"NORTH":"N", "EAST":"E", "SOUTH":"S", "WEST":"W", "UPWAR":"U", "DOWN":"D"}
    return m.get(d, d)

if __name__ == "__main__":
    with open("adventure.yaml", "r") as f:
        db = yaml.safe_load(f)

    print("digraph G {")
    for (loc, attrs) in db["locations"]:
        travel = attrs["travel"]
        if len(travel) > 0:
            for dest in travel:
                verbs = [abbreviate(x) for x in dest["verbs"]]
                if len(verbs) == 0:
                    continue
                action = dest["action"]
                if action[0] == "goto":
                    dest = action[1]
                    if not allalike(loc, dest):
                        continue;
                    arc = "%s -> %s" % (loc[4:], dest[4:])
                    label=",".join(verbs).lower()
                    if len(label) > 0:
                        arc += ' [label="%s"]' % label
                    print("    " + arc)
    print("}")

