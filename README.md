# AutoDock-er
The script eliminates the ligand from the experimental PDB structure that has been crystallized. Subsequently, a docking process is executed to acquire the binding affinity as a reference. Following that, automated docking of your ligands is carried out at the identical binding site as the reference ligand. Ultimately, the outcomes are collected in a CSV format.

In the same folder
1. AutoDock (mgltools_x86_64Linux2_1.5.6.tar)
2. ID of ligands to dock with in folder LigandID
3. Target protein (in folder Protein)
4. Target ligand(s) (in folder Ligand)

Misc tools for QOL
1. result.bash - Sorts complete and incomplete results
2. dlg.bash - Summarize output based on the lowest mean binding energy

