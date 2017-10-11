#!/bin/bash

#
# Example data staging job script that copies a directory from DataStore to Eddie with lftp
# 
#   Job will restart from where it left off if it runs out of time 
#   (so setting an accurate hard runtime limit is less important)

#$ -cwd
#$ -N stagein
#  Runtime limit - set a sensible value here
#$ -l h_rt=01:00:00 

# Make job resubmit if it runs out of time
#$ -r yes
#$ -notify
trap 'exit 99' sigusr1 sigusr2 sigterm

# Source and destination directories only! No files!
#
# Source path on DataStore. It should start with one of /csce/datastore, /chss/datastore, /cmvm/datastore or /igmm/datastore
SOURCE=/igmm/datastore/EyeMalform/X00013WK/X00013WK/2016-04-19
#
# Destination path on Eddie. It should be on Eddie fast HPC disk, starting with one of:
# /exports/csce/eddie, /exports/chss/eddie, /exports/cmvm/eddie, /exports/igmm/eddie or /exports/eddie/scratch, 
DESTINATION=/exports/igmm/eddie/EyeMalform/X00013WK/2016-04-19

# Do the copy with lftp without password assuming ssh keys have been setup on DataStore
lftp -u $USER,NONE -p 22222 sftp://sg.datastore.ed.ac.uk -e "mirror -c -v -P2 --no-perms ${SOURCE} ${DESTINATION}; exit" 
