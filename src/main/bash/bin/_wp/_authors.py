#!/bin/env python3

import glob
import yaml, json, sys
from collections import OrderedDict

authors = {}

files = glob.glob('**/*.yaml', recursive=True)
for file in files:
#    print(file)
    with open(file, 'r') as stream:
        try:
            data = yaml.load(stream)
            entries = data[list(data.keys())[0]]
            key = list(data.keys())[0]

            if 'presenters' in entries:
                for person in entries['presenters']:
                    if person not in authors:
                        authors[person] = []
                    authors[person].append(key)
            if 'editors' in entries:
                for person in entries['editors']:
                    if person not in authors:
                        authors[person] = []
                    authors[person].append(key)
            if 'authors' in entries:
                for person in entries['authors']:
                    if person not in authors:
                        authors[person] = []
                    authors[person].append(key)
            if 'panelists' in entries:
                for person in entries['panelists']:
                    if person not in authors:
                        authors[person] = []
                    authors[person].append(key)

        except yaml.YAMLError as exc:
            print(exc)

sorted = list(authors.keys())
sorted.sort()
for entry in sorted:
    print(entry, ': ', str(len(authors[entry])))

# mine = list(authors['van der Meer, Sven'])
m = list(OrderedDict.fromkeys(authors['van der Meer, Sven']))
print(m)
