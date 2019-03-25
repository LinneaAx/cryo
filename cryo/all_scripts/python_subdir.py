#!/usr/bin/env python3

import os
import sys
from Collections import defaultdict


def re_group_subdir(filename):
    d = {}
    d = defaultdict(list)
    with open(filename, "r") as r:
        for line in r:
            value, key = line.strip().split(" ")
            d[key].append(value)
        print(d)
    os.makedir(key)    
    


if __name__ == '__main__':
    filename = sys.argv[1]
    re_group_subdir(filename)

