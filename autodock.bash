#!/bin/bash

### Export our paths
echo "What iteration is this?"
read ITERNUM

UTILS=/home/user/AutoDock/mgltools_x86_64Linux2_1.5.6/MGLToolsPckgs/AutoDockTools/Utilities24
READ=/home/user/AutoDock/Dock$ITERNUM
LIGANDID=/home/user/AutoDock/LigandID

### Our proteins and ligands

PROTEIN=$READ/Protein/*.pdb
LIGAND=$READ/Ligand/*.pdb

### Removing the water molecules from proteins
echo "1. Removing water molecules from protein"
for p in $PROTEIN; do
  sed -i '/HOH/d' $p
done

### Removing the docked ligand from protein crystal structure (if available)
echo "2. Removing any docked ligands in protein structure"
IFS=' '
for p in $PROTEIN; do
  for l in $LIGANDID/*; do
    VAR1=`echo "$l" | sed -r "s/.+\/(.+)\..+/\1/"`
    VAR2=`echo "$p" | sed -r "s/.+\/(.+)\..+/\1/"`
    if [[ "${VAR2,,}" =~ "${VAR1,,}" ]]; then # IF match protein to their ligand ID
      LIGANDINPUT=`cat $LIGANDID/"$VAR1".txt` # Read ligand id from txt file
      read -ra ADDR <<< "$LIGANDINPUT"
      for i in "${ADDR[@]}"; do # Iterate over each ligands
        if grep -q "$i" $p; then # IF check whether the string is empty
          mkdir -p $READ/"$i"-"$VAR2"/Protein # Make new directories corresponding to each docked ligands
          grep "$i" $p > $READ/"$i"-"$VAR2"/"$i".pdb # Cut and remove the ligand into their respective directories
          sed -i "/$i/d" $p
          mkdir -p $READ/"$i"-"$VAR2"/Ligand
          cp $READ/"$i"-"$VAR2"/"$i".pdb $READ/"$i"-"$VAR2"/Ligand
        fi
      done
    fi
  done
done

for d in $READ/*; do
  if [[ "$d" == *"-"* ]]; then
    for p in $PROTEIN; do
      VAR1=`echo "$p" | sed -r "s/.+\/(.+)\..+/\1/"`
      VAR2=${d##*/}
      if [[ "${VAR2,,}" =~ "${VAR1,,}" ]]; then
        cp $p $d/Protein
      fi
    done
  fi
done

### Match ligand to proteins
echo "3. Match ligand to proteins"
for p in $PROTEIN; do
  for l in $LIGAND; do
    LIG=`echo "$l" | sed -r "s/.+\/(.+)\..+/\1/"`
    PROT=`echo "$p" | sed -r "s/.+\/(.+)\..+/\1/"`
    mkdir -p $READ/"$LIG"_"$PROT"/Protein
    mkdir -p $READ/"$LIG"_"$PROT"/Ligand
    cp $p $READ/"$LIG"_"$PROT"/Protein
    cp $p $READ/"$LIG"_"$PROT"/
    cp $l $READ/"$LIG"_"$PROT"/Ligand
    cp $l $READ/"$LIG"_"$PROT"/
  done
done

### Set charges and add hydrogen bonds to receptor
echo "4. Adding gasteiger charges if necessary, merging non-polar hydrogens and detecting aromatic carbons to proteins"
for d in $READ/*; do
  if [[ "$d" == *"Ligand"* || "$d" == *"Protein"* ]]; then
    :
  else
    PROTEIN=`echo $d/Protein/*.pdb | cut -f 1 -d '.'`
    pythonsh $UTILS/prepare_receptor4.py -r $d/Protein/*.pdb -A hydrogens -o $PROTEIN.pdbqt
  fi
done

### Preparing ligands
echo "5. Adding gasteiger charges to ligand and making backbone rotatable"
for d in $READ/*; do
  if [[ "$d" == *"Ligand"* || "$d" == *"Protein"* ]]; then
    :
  else
    LIGAND=`echo $d/Ligand/*.pdb | sed -r "s/.+\/(.+)\..+/\1/"`
    pythonsh $UTILS/prepare_ligand4.py -l $d/Ligand/$LIGAND.pdb -A hydrogens -o $d/Ligand/$LIGAND.pdbqt
  fi
done

### Run Autogrid for Docked Ligands and Ligands
echo "6. Running Autogrid for docked ligands"
## Preparing gpf files for docked ligands, grid box centering on ligand by default then running autogrid

for d in $READ/*; do
  if [[ "$d" == *"-"* ]]; then
    cp $d/Protein/* $d
    cp $d/Ligand/* $d
    pythonsh $UTILS/prepare_gpf4.py -l $d/`echo $d/Ligand/*.pdb | sed -r "s/.+\/(.+)\..+/\1/"`.pdbqt -r $d/"`echo $d/Protein/*.pdb | sed -r "s/.+\/(.+)\..+/\1/"`".pdbqt -y -v -o $d/autogrid.gpf
    cd $d
    autogrid4 -p autogrid.gpf -l autogrid.glg
  fi
done

### Run Autogrid for ligands
echo "7. Running Autogrid for ligands"

## Pulling Autogrid gpf from docked ligands

for d in $READ/*; do
  if [[ "$d" == *"-"* ]]; then
    PROTEIN=`echo $d/Protein/*.pdb | sed -r "s/.+\/(.+)\..+/\1/"`
    LIGAND=`echo $d/Ligand/*.pdb | sed -r "s/.+\/(.+)\..+/\1/"`
    mkdir -p $READ/Autogrid/$PROTEIN/$LIGAND
    cp $d/autogrid.gpf $READ/Autogrid/$PROTEIN/$LIGAND/$LIGAND.gpf
  fi
done

## Running Autogrid based on docked ligands grid
for d in $READ/*; do
  if [[ "$d" == *"_"* ]]; then
    for protein in $READ/Autogrid/*; do
      if [[ "${protein##*/}" == "`echo $d/Protein/*.pdb | sed -r "s/.+\/(.+)\..+/\1/"`" ]]; then
        for ligand in $protein/*; do
          for grid in $ligand/*; do
            mkdir -p $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"
            cp $d/Protein/* $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"
            cp $d/Ligand/* $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"
            cp $grid $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"
            pythonsh $UTILS/prepare_gpf4.py -l $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"/"`echo $d/Ligand/*.pdb | sed -r "s/.+\/(.+)\..+/\1/"`".pdbqt -r $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"/"`echo $d/Protein/*.pdb | sed -r "s/.+\/(.+)\..+/\1/"`".pdbqt -i $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`".gpf -v -o $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"/autogrid.gpf
            cd $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"
            autogrid4 -p $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"/autogrid.gpf -l $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"/autogrid.glg
          done
        done
      fi
    done
  fi
done

### Autodock for docked ligands
echo "8. Running Autodock for ligands at 20 runs"
GA_RUN="20"
## Preparing dpf files for docked ligands
for d in $READ/*; do
  if [[ "$d" == *"-"* ]]; then
    pythonsh $UTILS/prepare_dpf4.py -l $d/`echo $d/Ligand/*.pdb | sed -r "s/.+\/(.+)\..+/\1/"`.pdbqt -r $d/"`echo $d/Protein/*.pdb | sed -r "s/.+\/(.+)\..+/\1/"`".pdbqt -p ga_run="$GA_RUN" -o $d/autodock.dpf
    sed "s/extended/bound/g" $d/autodock.dpf > $d/autodock_temp.dpf;mv $d/autodock_temp.dpf $d/autodock.dpf
    cd $d
    autodock4 -p $d/autodock.dpf -l $d/"`echo $d/Ligand/*.pdb | sed -r "s/.+\/(.+)\..+/\1/"`"_"`echo $d/Protein/*.pdb | sed -r "s/.+\/(.+)\..+/\1/"`".dlg
  fi
done

for d in $READ/*; do
  if [[ "$d" == *"_"* ]]; then
    for protein in $READ/Autogrid/*; do
      if [[ "${protein##*/}" == "`echo $d/Protein/*.pdb | sed -r "s/.+\/(.+)\..+/\1/"`" ]]; then
        for ligand in $protein/*; do
          for grid in $ligand/*; do
            pythonsh $UTILS/prepare_dpf4.py -l $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"/"`echo $d/Ligand/*.pdb | sed -r "s/.+\/(.+)\..+/\1/"`".pdbqt -r $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"/"`echo $d/Protein/*.pdb | sed -r "s/.+\/(.+)\..+/\1/"`".pdbqt -p ga_run="$GA_RUN" -v -o $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"/autodock.dpf
            cd $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"
            sed "s/extended/bound/g" $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"/autodock.dpf > $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"/autodock_temp.dpf;mv $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"/autodock_temp.dpf $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"/autodock.dpf
            autodock4 -p $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"/autodock.dpf -l $d/Autogrid/"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"/"`echo $d/Ligand/*.pdb | sed -r "s/.+\/(.+)\..+/\1/"`"_"`echo $grid | sed -r "s/.+\/(.+)\..+/\1/"`"_"`echo $d/Protein/*.pdb | sed -r "s/.+\/(.+)\..+/\1/"`".dlg
          done
        done
      fi
    done
  fi
done

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

for p in $READ/Results/*; do
  PROTEIN_NAME=`basename $p`
  echo ${PROTEIN_NAME^^} >> $READ/Results/Proteins.txt;
  done
