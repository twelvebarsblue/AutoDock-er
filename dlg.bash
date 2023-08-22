#!/bin/bash

READ=/home/user/AutoDock/Result

for dock in $READ/*; do
  for complete in $dock/Results/Complete/*; do
    for dlg in $complete/*; do
      if [[ "$dlg" == *"hes"* || "$dlg" == *"pva"* || "$dlg" == *"trehalose"* || "$dlg" == *"sucrose"* || "$dlg" == *"glycerol"* ]]; then
        DOCK=`echo "${dock##*/}" | sed -r "s/.+\/(.+)\..+/\1/"`
        LIGAND=`echo $dlg | sed -r "s/.+\/(.+)\..+/\1/" | cut -d_ -f1`
        SITE=`echo $dlg | sed -r "s/.+\/(.+)\..+/\1/" | cut -d_ -f2`
        PROTEIN=`echo $dlg | sed -r "s/.+\/(.+)\..+/\1/" | cut -d_ -f3`
        # Get the cluster with the highest count, if there is two same cluster count, get the cluster with the lowest mean binding energy
        grep '|#' $dlg | awk '{print $7,$9}' | sort -k2 -n -r | head -n 1 | awk '{print $1}' | { tr -d '\n' ; echo ",$DOCK,$LIGAND,$SITE,$PROTEIN"; } >> /home/yiyang/AutoDock/Ligand.csv
      else
        DOCK=`echo "${dock##*/}" | sed -r "s/.+\/(.+)\..+/\1/"`
        LIGAND=`echo $dlg | sed -r "s/.+\/(.+)\..+/\1/" | cut -d_ -f1`
        PROTEIN=`echo $dlg | sed -r "s/.+\/(.+)\..+/\1/" | cut -d_ -f2`
      grep '|#' $dlg | awk '{print $3,$7}' | sort -k1 -n | head -n 1 | awk '{print $2}' | { tr -d '\n' ; echo ",$DOCK,$LIGAND,$PROTEIN"; } >> /home/yiyang/AutoDock/OriLigand.csv
      fi
    done
  done
done

python3 merge.py

