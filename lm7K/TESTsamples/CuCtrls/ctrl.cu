### This is generated by ctrlgen2.py from ctrls 
### For tokens, See http://titus.phy.qub.ac.uk/packages/LMTO/tokens.html. 
### However, lm7K is now a little different from Mark's lmf package in a few points.
### Do lmf --input to see all effective category and token ###
### It will be not so difficult to edit ctrlge.py for your purpose ###
VERS    LM=7 FP=7        # version check. Fixed.
IO      SHOW=T VERBOS=35
             # SHOW=T shows readin data (and default setting at the begining of console output)
	     # It is useful to check ctrl is read in correctly or not (equivalent with --show option).
	     # larger VERBOSE gives more detailed console output.
SYMGRP find   # 'find' evaluate space-group symmetry automatically.
              # Usually 'find is OK', but lmf may use lower symmetry
	      # because of numerical problem.
              # Do lmchk to check how it is evaluated.
              # See http://titus.phy.qub.ac.uk/packages/LMTO/tokens.html#SYMGRPcat
%const kmxa=5  # kmxa=5 is good for pwemax=3 or lower.
               # larger kmxa is better but time-consuming. A rule of thumb: kmxa>pwemax in Ry.
% const  da=0 alat=6.798
STRUC   ALAT={alat} DALAT={da}
        PLAT=  0.0 0.5 0.5  0.5 0.0 0.5   0.5 0.5 0.0
  NBAS= 1  NSPEC=1
SITE    ATOM=Cu POS=0 0 0
SPEC
    ATOM=Cu Z=29 R=1.92 PZ=3.9,3.9,3.9  P=0,0,4.2 
      EH=-0.1 -0.1 -0.1 -0.1  RSMH=0.96 0.96 0.96 0.96 
      EH2=-2 -2 -2 -2  RSMH2=0.96 0.96 0.96 0.96 
      KMXA={kmxa}  LMX=3 LMXA=4
      #MMOM=
      #NOTE: lmfa(rhocor) generates spin-averaged rho for any MMOM,jun2012
      #Q= 
      #MMOM and Q are to set electron population. grep conf: in lmfa output

% const pwemax=3 nk=6 nit=30  gmax=12  nspin=1
BZ    NKABC={nk} {nk} {nk}  # division of BZ for q points.
      METAL=3

                # METAL=3 is safe setting. For insulator, METAL=0 is good enough.
		# When you plot dos, set SAVDOS=T and METAL=3, and with DOS=-1 1 (range) NPTS=2001 (division) even for insulator.
		#   (SAVDOS, DOS, NPTS gives no side effect for self-consitency calculaiton).
                # 
                #BUG: For a hydrogen in a large cell, I(takao) found that METAL=0 for
                #(NSPIN=2 MMOM=1 0 0) results in non-magnetic solution. Use METAL=3 for a while in this case.
                # 

      BZJOB=0	# BZJOB=0 (including Gamma point) or =1 (not including Gamma point).
		#  In cases , BZJOB=1 makes calculation efficient.


      #Setting for molecules. No tetrahedron integration. (Smearing))
      # See http://titus.phy.qub.ac.uk/packages/LMTO/tokens.html
%const bzw=0  fsmom=0.0
      #TETRA=0 
      #N=-1    #Negative is Fermi distribution function W= gives temperature.
      #W=0.001 #This corresponds to T=157K as shown in console output
               #W=0.01 is T=1573K. It makes stable nonvergence for molecule. 
               #Now you don't need to use NEVMX in double band-path method,
               #which obtain only eigenvalues in first-path to obtain integration weights
               #, and accumulate eigenfunctions in second path.
      #FSMOM={fsmom} real number (fixed moment method)
      #  Set the global magnetic moment (collinear magnetic case). In the fixed-spin moment method, 
      #  a spin-dependent potential shift is added to constrain the total magnetic moment to value 
      #  assigned by FSMOM=. Default is NULL (no FSMOM). FSMOM=0 works now (takao Dec2010)
      # NOTE: current version is for ferro magnetic case (total mag moment) only.
      #FSMOMMETHOD=0 #only effective when FSMOM exists. #Added by t.kotani on Dec8.2010
      #  =0: original mode suitable for solids.(default)
      #  =1: discrete eigenvalue case. Calculate bias magnetic field from LUMO-HOMO gap for each spins.
      #      Not allowed to use together with HAM_SO=1 (L.S). 
      #      It seems good enough to use W=0.001. Smaller W= may cause instability.
      #For Molecule, you may also need to set FSMOM=n_up-n_dn, and FSMOMMETHOD=1 below.


      #For Total DOS.   DOS:range, NPTS:division. We need to set METAL=3 with default TETRA (no TETRA).
      #SAVDOS=T DOS=-1 1 NPTS=2001

      #EFMAX= (not implemented yet, but maybe not so difficult).            


      #  See http://titus.phy.qub.ac.uk/packages/LMTO/tokens.html#HAMcat for tokens below.

      #NOINV=T (for inversion symmetry)
      #  Suppress the automatic addition of the inversion to the list of point group operations. 
      #  Usually the inversion symmetry can be included in the determination of the irreducible 
      #  part of the BZ because of time reversal symmetry. There may be cases where this symmetry 
      #  is broken: e.g. when spin-orbit coupling is included or when the (beyond LDA) 
      #  self-energy breaks time-reversal symmetry. In most cases, lmf program will automatically 
      #  disable this addition in cases that knows the symmetry is broken
      #

      #INVIT=F
      #  Enables inverse iteration generate eigenvectors (this is the default). 
      #  It is more efficient than the QL method, but occasionally fails to find all the vectors. 
      #   When this happens, the program stops with the message:
      #     DIAGNO: tinvit cannot find all evecs
      #   If you encounter this message set INVIT=F.
      #  T.Kotani think (this does not yet for lm7K).
    
ITER MIX=A2,b=.5,n=3 CONV=1e-6 CONVC=1e-6 NIT={nit}
#ITER MIX=B CONV=1e-6 CONVC=1e-6 NIT={nit}
                # MIX=A: Anderson mixing.
                # MIX=B: Broyden mixing (default). 
                #        Unstable than Anderson mixing. But faseter. It works fine for sp bonded systems.
                #  See http://titus.phy.qub.ac.uk/packages/LMTO/tokens.html#ITERcat

HAM   NSPIN={nspin}   # Set NSPIN=2 for spin-polarize case; then set SPEC_MMOM (initial guess of magnetic polarization).
      FORCES=0  # 0: no force calculation, 1: forces calculaiton 
      GMAX={gmax}   # this is for real space mesh. See GetStarted. (Real spece mesh for charge density).
                # Instead of GMAX, we can use FTMESH.
                # You need to use large enough GMAX to reproduce smooth density well.
                # Look into sugcut: shown at the top of console output. 
                # It shows required gmax for given tolelance HAM_TOL.
      REL=T     # T:Scaler relativistic, F:non rela.
     XCFUN=103
          # =1 for VWN.
                # =2 Birth-Hedin (if this variable is not set).
		#    (subs/evxc.F had a problem when =2 if rho(up)=0 or rho(down)=0).
                # =103 PBE-GGA

      PWMODE=11 # 10: MTO basis only (LMTO) PW basis is not used.
                # 11: APW+MTO        (PMT)
                # 12: APW basis only (LAPW) MTO basis is not used.

      PWEMAX={pwemax} # (in Ry). When you use larger pwemax more than 5, be careful
                      # about overcompleteness. See GetStarted.
      ELIND=0    # this is to accelarate convergence. Not affect to the final results.
                 # For sp-bonded solids, ELIND=-1 may give faster convergence.
                 # For O2 molecule, Fe, and so on, use ELIND=0(this is default).

      FRZWF=F #If T, fix augmentation function. This is worth to test in future.
      #  See http://titus.phy.qub.ac.uk/packages/LMTO/tokens.html#HAMcat

      #For LDA+U calculation, see http://titus.phy.qub.ac.uk/packages/LMTO/fp.html#ldaplusu

      #For QSGW. you have to set them. Better to get some samples.
      #RDSIG=
      #RSRNGE=

      #SO=        default = 0
      #Spin-orbit coupling (for REL=1)
      #0 : no SO coupling
      #1 : Add L.S to hamiltonian (but non-colinear density yet).
      #2 : Add Lz.Sz only to hamiltonian
               
OPTIONS PFLOAT=1 
        # Q=band (this is quit switch if you like to add)

# Relaxiation sample
#DYN     MSTAT[MODE=5 HESS=T XTOL=.001 GTOL=0 STEP=.015]  NIT=20
# See http://titus.phy.qub.ac.uk/packages/LMTO/tokens.html#DYNcat

