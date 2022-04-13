#!/usr/bin/env python3
"""\
usage: make-graph.py [-a] [-m] [-s]

Make a DOT graph of Colossal Cave

-a = emit graph of entire dungeon
-m = emit graph of maze all alike
-s = emit graph of surface locations
"""
# Copyright (c) 2017 by Eric S. Raymond
# SPDX-License-Identifier: BSD-2-clause

import sys, yaml, getopt

def allalike(loc):
    "Select out loci related to the Maze All Alike"
    return ("ALIKE" in loc) or (loc == "LOC_PITBRINK") or ("MAZEEND" in loc) or ("STALACTITE" in loc)

def surface(attrs):
    "Select out surface locations"
    if ("ABOVE" in attrs["conditions"]) and attrs["conditions"]["ABOVE"]:
        return True
    if ("FOREST" in attrs["conditions"]) and attrs["conditions"]["FOREST"]:
        return True
    return False

def abbreviate(d):
    m = {"NORTH":"N", "EAST":"E", "SOUTH":"S", "WEST":"W", "UPWAR":"U", "DOWN":"D"}
    return m.get(d, d)

def roomlabel(loc):
    "Generate a room label from the description, if possible"
    loc_descriptions = dict(db["locations"])[loc]['description']
    description = loc[4:]
    short = loc_descriptions["short"]
    maptag = loc_descriptions["maptag"]
    if short is not None:
        if short.startswith("You're "):
            short = short[7:]
        if short.startswith("You are "):
            short = short[8 :]
        if short.startswith("in ") or short.startswith("at ") or short.startswith("on "):
            short = short[3:]
        if short[:3] in {"n/s", "e/w"}:
            short = short[:3].upper() + short[3:]
        elif short[:2] in {"ne", "sw", "se", "nw"}:
            short = short[:2].upper() + short[2:]
        else:
            short = short[0].upper() + short[1:]
    elif loc_descriptions["maptag"] is not None:
        short = loc_descriptions["maptag"]
    elif loc_descriptions["long"] is not None and len(loc_descriptions["long"]) < 20:
        short = loc_descriptions["long"]
    if short is not None:
        description += "\\n" + short
    return description

if __name__ == "__main__":
    with open("adventure.yaml", "r") as f:
        db = yaml.safe_load(f)

    try:
        (options, arguments) = getopt.getopt(sys.argv[1:], "ams")
    except getopt.GetoptError as e:
        print(e)
        sys.exit(1)

    subset = "maze"
    for (switch, val) in options:
        if switch == '-a':
            subset = "all"
        elif switch == '-m':
            subset = "maze"
        elif switch == '-s':
            subset = "surface"
        else:
            sys.stderr.write(__doc__)
            raise SystemExit(1)        

    startlocs = {}
    for obj in db["objects"]:
        objname = obj[0]
        location = obj[1].get("locations")
        if "OBJ" not in objname and location != "LOC_NOWHERE" and ("immovable" not in obj[1] or not obj[1]["immovable"]):
            if location in startlocs:
                startlocs[location].append(objname)
            else:
                startlocs[location] = [objname]

    startlocs = {}
    for obj in db["objects"]:
        objname = obj[0]
        location = obj[1].get("locations")
        if "OBJ" not in objname and location != "LOC_NOWHERE" and ("immovable" not in obj[1] or not obj[1]["immovable"]):
            if location in startlocs:
                startlocs[location].append(objname)
            else:
                startlocs[location] = [objname]

    print("digraph G {")
    
    for (loc, attrs) in db["locations"]:        
        if subset == "surface" and not surface(attrs):
            continue
        if subset == "maze" and not allalike(loc):
            continue;
        node_label = roomlabel(loc)
        if loc in startlocs:
            node_label += "\\n" + ",".join(startlocs[loc]).lower()
        print('    %s [shape=box,label="%s"]' % (loc[4:], node_label))
        
    for (loc, attrs) in db["locations"]:        
        if subset == "surface" and not surface(attrs):
            continue
        travel = attrs["travel"]
        if len(travel) > 0:
            for dest in travel:
                verbs = [abbreviate(x) for x in dest["verbs"]]
                if len(verbs) == 0:
                    continue
                action = dest["action"]
                if action[0] == "goto":
                    dest = action[1]
                    if subset == "maze" and not (allalike(loc) or allalike(dest)):
                        continue;
                    arc = "%s -> %s" % (loc[4:], dest[4:])
                    label=",".join(verbs).lower()
                    if len(label) > 0:
                        arc += ' [label="%s"]' % label
                    print("    " + arc)
    print("}")
