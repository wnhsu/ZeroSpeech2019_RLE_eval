from __future__ import print_function, division
from collections import defaultdict
import sys
import numpy
import os.path as osp

class ReadZrsc2019Exception(Exception):
    def __init__(self,*args, **kwargs):
        Exception.__init__(self, *args, **kwargs)

def to_float(list_s):
    """List of strings to list of floats"""
    try:
        return [float(s) for s in list_s]
    except ValueError as e:
        raise e

def log_or_raise(message, log):
    if log:
        print(message)
    else:
        raise ReadZrsc2019Exception(msg)

def read(file):
    """ Read file and search for format errors or inconsistencies.
    Yield : "val": vector representing one line
    """
    flow = open(file)
    # How many columns are there in a line
    num_cols = None
    # Boolean is_empty
    is_empty = True
    prev_value_s = None
    prev_len = 0
    try:
        for i, line in enumerate(flow):
            # Blank lines are skipped
            if line != '\n' and line!= '' and line!= ' ':
                # If line is not empty, is_empty is false
                is_empty = False
                # Splitting the line with spaces
                line_elts = line.strip('\n').split(' ')
                # Initalisation of number of columns expected
                if num_cols == None:
                    num_cols = len(line_elts)
                # If we have different sized vectors
                if num_cols != len(line_elts):
                    raise ReadZrsc2019Exception("Line " + str(i) +
                        ": Inconsistent format, vector size changed")
                try:
                    value_s = tuple(to_float(line_elts))
                    # yield value_s
                except ValueError as e:
                    raise ReadZrsc2019Exception("Error coverting to float: " + str(e))

		if prev_value_s is None:
                    prev_value_s = value_s
                elif prev_value_s != value_s:
                    yield (prev_value_s, prev_len)
                    prev_value_s = value_s
                    prev_len = 0
                prev_len += 1
        yield (prev_value_s, prev_len)
    except UnicodeDecodeError:
        raise ReadZrsc2019Exception("Unknown error reading file (corrupted?)")
    # If file is empty
    if is_empty == True:
        raise ReadZrsc2019Exception("File is empty")
    flow.close()

def read_all(list_filename, folder, skip_missing_files, log):
    with open(list_filename, 'r') as flow: # Only IOError that can be raised
        n_cols = None
        n_lines = 0
        d_symbol_counts = defaultdict(int)
        total_duration = 0
        for line in flow.readlines():
            line = line.strip()
            if (line == ""):
                continue
            base_name, duration_s = line.split(' ')
            duration = float(duration_s)
            file_name = osp.join(folder, base_name)
            try:
                n_cols_i = None
                for vector in read(file_name):
                    n_lines += 1
                    if n_cols_i is None:
                        n_cols_i = len(vector[0])
                    d_symbol_counts[vector] += 1
                if n_cols is not None:
                    if n_cols != n_cols_i:
                        log_or_raise("Vector dimension does not match " +
                                        "other files: " + base_name, log)
                else:
                    n_cols = n_cols_i
                total_duration += duration
            except ReadZrsc2019Exception as e:
                log_or_raise(str(e), log)
            except IOError as e:
                if skip_missing_files:
                    continue
                log_or_raise("Error reading file '" + base_name + "': " + str(e), log)
    return d_symbol_counts, n_lines, total_duration


def read_all_factor(list_filename, folder, skip_missing_files, log):
    with open(list_filename, 'r') as flow: # Only IOError that can be raised
        n_cols = None
        n_lines = 0
        d_symbol_counts = defaultdict(int)
        d_length_counts = defaultdict(int)
        total_duration = 0
        for line in flow.readlines():
            line = line.strip()
            if (line == ""):
                continue
            base_name, duration_s = line.split(' ')
            duration = float(duration_s)
            file_name = osp.join(folder, base_name)
            try:
                n_cols_i = None
                for vector in read(file_name):
                    n_lines += 1
                    if n_cols_i is None:
                        n_cols_i = len(vector[0])
                    d_symbol_counts[vector[0]] += 1
                    d_length_counts[vector[1]] += 1
                if n_cols is not None:
                    if n_cols != n_cols_i:
                        log_or_raise("Vector dimension does not match " +
                                        "other files: " + base_name, log)
                else:
                    n_cols = n_cols_i
                total_duration += duration
            except ReadZrsc2019Exception as e:
                log_or_raise(str(e), log)
            except IOError as e:
                if skip_missing_files:
                    continue
                log_or_raise("Error reading file '" + base_name + "': " + str(e), log)
    return d_symbol_counts, d_length_counts, n_lines, total_duration
