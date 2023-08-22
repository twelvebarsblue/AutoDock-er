#!/bin/bash

### Export our paths
echo "What iteration is this?"
read ITERNUM

READ=/home/user/AutoDock/Dock$ITERNUM
PROTEIN=$READ/Protein/*.pdb

# Get Results

shopt -s globstar
for i in $READ/**/*.dlg; do
  for p in $PROTEIN; do
    for r in $i*; do
      VAR1=`echo "$r" | sed -r "s/.+\/(.+)\..+/\1/"`
      VAR2=`echo "$p" | sed -r "s/.+\/(.+)\..+/\1/"`
      if [[ "${VAR1,,}" =~ "${VAR2,,}" ]]; then
        prefix="pdb"
        PDB=${VAR2#"$prefix"}
        mkdir -p $READ/Results/$PDB
        cp $r $READ/Results/$PDB
      fi
    done
  done
done

## Sort them into complete/incomplete protein folders

for p in $READ/Results/*; do
  for r in $p/*; do
    if [[ "$r" == *"glycerol"* || "$r" == *"hes"* || "$r" == *"pva"* || "$r" == "trehalose" || "$r" == *"sucrose"* ]]; then
      PROTEIN_NAME=`basename $p`
      echo ${PROTEIN_NAME^^} >> $READ/Results/Complete.tmp
    else
      PROTEIN_NAME=`basename $p`
      echo ${PROTEIN_NAME^^} >> $READ/Results/Incomplete.tmp
    fi
  done
done


uniq <$READ/Results/Complete.tmp > $READ/Results/Complete.txt
rm $READ/Results/Complete.tmp
uniq <$READ/Results/Incomplete.tmp > $READ/Results/Incomplete.txt
rm $READ/Results/Incomplete.tmp

for p in $READ/Results/*; do
  if [ -d "${p}" ]; then
    PROTEIN_NAME=`basename $p`
    for r in `cat $READ/Results/Complete.txt`; do
      if [[ ${r^^} == ${PROTEIN_NAME^^} ]]; then
        mkdir -p $READ/Results/Complete
        mv $p $READ/Results/Complete
      fi
    done
  fi
done

for p in $READ/Results/*; do
  if [ -d "${p}" ]; then
    PROTEIN_NAME=`basename $p`
    for r in `cat $READ/Results/Incomplete.txt`; do
      if [[ ${r^^} == ${PROTEIN_NAME^^} ]]; then
        mkdir -p $READ/Results/Incomplete
        mv $p $READ/Results/Incomplete
      fi
    done
  fi
done