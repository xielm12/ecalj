      module m_ReadEfermi
      real(8),protected:: bandgap
      real(8)::ef
      contains

      subroutine readefermi()
      implicit none
      integer:: ifief,ifile_handle
      ifief=ifile_handle()
      open(ifief,file='EFERMI')
      read(ifief,*) ef,bandgap
      close(ifief)
      write(6,"(a,f12.6)")' --- READIN ef from EFERMI. ef=',ef
      end subroutine
      end module m_ReadEfermi

!> get basic settings of crystal structure and nlm info
!!  - genallcf_v3(nwin,efin,incwfx) set data
!!  - This is old routine. Confusing. We need to clean up.
      module m_genallcf_v3
!!----------------------------------------------------------------
!! - structure
!!  -  o                   plat,alat,natom,nclass,pos,
!!  -  o                   ngrp, symgg,
!!  -  o                   invg, ef,
!! - l,n and dimensions
!!   - o                   clabl, nspin,nl,nn,nnv,nnc,
!!   - o                   nindx, nindxv, nindxc, iclass,
!!   - d                   nlmto,nlnx,nlnxv,nlnxc,nlnmx,nlnmxv,nlnmxc,
!!   - o                   z,
!! - l,n,m indices for Phi (atomic basis)
!!   -  o                   il, in, im,  ilnm,  nlnm,
!!   -  o                   ilv,inv,imv, ilnmv, nlnmv,
!!   -  o                   ilc,inc,imc, ilnmc, nlnmc,
!! - core
!!   -  o                   ncwf, ecore, konf, icore, ncore,nctot,
!! - frequency
!!   -                   niw,diw,nw,dw,delta,deltaw,esmr, freq)
!!             symgrp
!!             ,nocc, nunocc, occv, unoccv, occc, unoccc
      implicit none
      character(120),protected:: symgrp
      character(6),allocatable,protected :: clabl(:)
      integer,allocatable:: iclass(:),
     &    nindxv(:,:),nindxc(:,:),ncwf(:,:,:) ,
     o    invg(:), il(:,:), in(:,:), im(:,:),   ilnm(:),  nlnm(:),
     o    ilv(:),inv(:),imv(:),  ilnmv(:), nlnmv(:),
     o    ilc(:),inc(:),imc(:),  ilnmc(:), nlnmc(:),
     o    nindx(:,:),konf(:,:),icore(:,:),ncore(:),
     &    occv(:,:,:),unoccv(:,:,:)   
     &   ,occc(:,:,:),unoccc(:,:,:),
     o    nocc(:,:,:),nunocc(:,:,:),   iantiferro(:)
      integer::
     o  nclass,natom,nspin,nl,nn,nnv,nnc, ngrp,
     o  nlmto,nlnx,nlnxv,nlnxc,nlnmx,nlnmxv,nlnmxc, nctot!,nw
      real(8), allocatable,protected:: 
     o  plat(:,:),pos(:,:),z(:),  symgg(:,:,:)   !w(igrp) freq(:),
      real(8),protected :: alat,diw,dw,deltaw !ef
      logical,protected:: done_genallcf_v3=.false.
      character(8),allocatable,protected:: spid(:)
!! unprotected --> need to be protected
      real(8), allocatable :: ecore(:,:)
      real(8):: delta
      integer:: niw
      real(8):: esmr
c-----------------------------------------------------------------------
      contains

      subroutine genallcf_v3(incwfx)
!!> Readin GWIN_V2 and LMTO(crystal) data and allocate all required.
!!r Return iclass=ibas.
!! efin,incwfx, are used as switches.
!! input: efin,incwfx,
!!        GWIN_V2, LMTO
!! output: All the output are given in the declear section above.
!! --------------------------------------------------------
      implicit none
      integer(4)::iflmto,ifinin,incwfx,ifec,i,j,
     & lmx, lmx2,nlmto2,nprodxc,nlnaxc,nlnaxv,nprodx,ifi,ig,is
     & ,iopen,iclose,nprodxv,nlnax
     & ,noflmto,maxnn
      integer(4):: infwfx
      integer(4):: n1,n2,n3,imagw,lcutmx,n,ic
      logical :: nocore
      real(8)::efin
      real(8),allocatable::tolbas(:)
      character(120):: symgrpt
      real(8),   allocatable:: ecoret(:,:,:,:)
      integer(4),allocatable::ncwf2(:,:,:)
      integer:: ia,l,m,ic1,isp,lt,nt,nsp,nr,ncorex,ifix
      real(8)::a,b,zz, efdummy
      integer:: nwdummy
c      allocate(nclass,natom,nspin,nl,nn,nnv,nnc, ngrp,
c     o  nlmto,nlnx,nlnxv,nlnxc,nlnmx,nlnmxv,nlnmxc, nctot, niw,nw)
      if(done_genallcf_v3) call rx('genallcf_v3 is already called')
      done_genallcf_v3=.true.

c      allocate(alat,ef, diw,dw,delta,deltaw,esmr,  symgrp)
      iflmto     = iopen('LMTO',1,0,0)
      if (iflmto < 0) call rx( 'unit file for GWIN_V2 < 0')

c--- readin these by rgwinf_v3
c      character*120 symgrp
c      integer(4)::nclass,natom,nspin,nl,nnv,nnc
c      real(8)::alat
c      integer(4),allocatable::
c     &   iclass(:)
c     &  ,nindxv(:,:),nindxc(:,:)
c     &  ,occv(:,:,:),unoccv(:,:,:)
c     &  ,occc(:,:,:),unoccc(:,:,:)
c     &  ,ncwf(:,:,:)
c      real(8),allocatable:: plat(:,:),pos(:,:),z(:)
c      character*6,allocatable:: clabl(:)
c      write(6,*)' goto rgwin'
c      call rgwinf_v3 (iflmto,ifinin,nwin,efin,incwfx) !these are inputs
c      write(6,*)' end of rgwinf_v3'
c-------------------------------------------------------------------------
c--- rgwinf ---
      ifi = iflmto
c      nw  = nwin
c      ef  = efin
      read(ifi,*);  read(ifi,*)
      read(ifi,*)symgrpt        !SYMMETRY
      j = 0
      symgrp='  '//trim(adjustl(symgrpt))
      write(6,*)' symgrp=', symgrp
      read(ifi,*)
      read(ifi,*)
      read(ifi,*)
      read(ifi,*)alat              !lattice constant
      allocate(plat(3,3))          !primitive lattice vectors
      read(ifi,*)
      read(ifi,*)plat(1:3,1)
      read(ifi,*)plat(1:3,2)
      read(ifi,*)plat(1:3,3)
      read(ifi,*)
      read(ifi,*) natom            !Number of atoms
!!
      nclass = natom  !We set nclass = natom through the GW calculations
      write(6,*)'genalloc: alat natom=',alat,natom
      allocate(pos(3,natom))       !positions of atoms
      read(ifi,*)
      do n = 1,natom
        read(ifi,*) pos(1,n),pos(2,n),pos(3,n)
      end do
      read(ifi,*)
      read(ifi,*)
      read(ifi,*)
      read(ifi,*)nspin           !spin (1=paramagnetic  2=ferromagnetic)
      read(ifi,*)
      read(ifi,*)nl              !max. no. valence and core l
      read(ifi,*)
      read(ifi,*)nnv,nnc   !max. no. valence and core n
      write(6,*)' nspin nl nnv nnc =',nspin,nl,nnv,nnc
c--------------------------
      if(nnv==1) nnv=2 ! for backword compatibility!takao apr 2002
      ! nnv=2 corresponds to phi and phidot
      ! nnv=3 corresponds to
c--------------------------
      read(ifi,*)
      read(ifi,*)  !nrx is not readin
      read(ifi,*)
      allocate(clabl(nclass),z(nclass)) !class-label, z
      do ic = 1,nclass
        read(ifi,*) clabl(ic),z(ic) !,nrofi is not readin
      end do

      allocate(iclass(natom)) !atom and its class.
      do n = 1,natom          !!We set nclass = natom through the GW calculations
        iclass(n)=n
      end do

      allocate(nindxv(nl,nclass), nindxc(nl,nclass),
     &        occv(nl,nnv,nclass),unoccv(nl,nnv,nclass),
     &        occc(nl,nnc,nclass),unoccc(nl,nnc,nclass))
      allocate(ncwf2(nl,nnc,nclass),ncwf(nl,nnc,nclass))
      allocate(tolbas(0:2*(nl-1)))
      ifix=ifi
      call rgwinaf    (ifi,ifinin,nl,nnv,nnc,nclass, !ifi can be changed.
c> BZ
     o                  n1,n2,n3,efdummy,
c> frequencies
     o                  niw,diw,nwdummy,dw,delta,deltaw,esmr,imagw,
c> coulomb
c     o                  tolvc,alp,alptx,h,ng,
c> product basis
     o                  tolbas,lcutmx,nindxv,nindxc,
     o                  occv,unoccv, occc,unoccc,
c> core
     o                  ncwf,ncwf2 )
c----
      allocate(iantiferro(1:natom),spid(1:natom))
      read(ifix,*)
      read(ifix,*)iantiferro(1:natom) !may2015
      read(ifix,*)
      read(ifix,*)spid(1:natom)
      inquire(file='NoCore',exist=nocore)
      if(nocore) then
        occc=0    ! call iclear(nl*nnc*nclass, w(ioccc))
        unoccc=0    ! call iclear(nl*nnc*nclass, w(iunoccc))
        ncwf  =0    ! call iclear(nl*nnc*nclass, w(incwf))
      elseif( incwfx==-1 ) then
        write(6,*)' ### incwf=-1 Use ForSxc for core'
        ncwf = ncwf2  !call icopy(nl*nnc*nclass,w(incwf2),w(incwf))
      elseif( incwfx==-2 ) then
        write(6,*)' ### incwf=-2 Use NOT(ForSxc) for core and Pro-basis '
        call notbit(nl*nnc*nclass, ncwf2)
        ncwf  = ncwf2 ! call icopy (nl*nnc*nclass, w(incwf2),w(incwf))
        occc= ncwf  ! call icopy (nl*nnc*nclass, w(incwf),w(ioccc))
        unoccc= 0     ! call iclear(nl*nnc*nclass, w(iunoccc))
      elseif( incwfx==-3 ) then
        call ibiton(nclass,nl,nnc,nindxc, occc, ncwf)
        unoccc= 0     ! call iclear(nl*nnc*nclass, w(iunoccc))
        write(6,*)' ### incwf=-3  occ=1 unocc=0 incwf=1 for all core '
      elseif( incwfx==-4 ) then
        write(6,*)' ### incwf=-4  occ=0 and unocc=0 for all core '
        occc=0  !call iclear(nl*nnc*nclass, w(ioccc))
        unoccc=0 !call iclear(nl*nnc*nclass, w(iunoccc))
        ncwf=0  !call iclear(nl*nnc*nclass, w(incwf))
      elseif(incwfx==0) then
        write(6,*)' ### Use unocc occ ForX0 for core'
      else
        call rx( ' ### proper incwf is not given for genallcf2:rgwinf ')
      endif
      deallocate(ncwf2)
C... End of rgwinf section ----------------------------


c> dimensions and constants
      lmx        = 2*(nl-1)
      lmx2       = (lmx+1)**2
      nlmto      = noflmto(nindxv,iclass,nl,nclass,natom)
      nlmto2     = nlmto*nlmto
      nn         = maxnn (nindxv,nindxc,nl,nclass)

c>> combine nocc,nunocc,nindx
      allocate(nindx(nl,nclass))
      allocate(nocc(nl,nn,nclass),nunocc(nl,nn,nclass))
      call reindx  (occv,unoccv,nindxv,
     i              occc,unoccc,nindxc,
     d              nl,nn,nnv,nnc,nclass,
     o              nocc,nunocc,nindx)
      call maxdim  (occc,unoccc,nindxc,nl,nnc,nclass,
     o              nprodxc,nlnxc,nlnmxc,nlnaxc)
      call maxdim  (occv,unoccv,nindxv,nl,nnv,nclass,
     o              nprodxv,nlnxv,nlnmxv,nlnaxv)
      call maxdim  (nocc,nunocc,nindx,nl,nn,nclass,
     o              nprodx,nlnx,nlnmx,nlnax)

c      nlnx4      = nlnx**4
c      nphi       = nrx*nl*nn*nclass
c      pi         = 4d0*datan(1d0)
c      tpia       = 2d0*pi/alat

c$$$c> frequency mesh
c$$$c      call defdr   (ifreq,nw)
c$$$      write(6,*)' nw from rgwinaf=',nw
c$$$      if(nw>0) then
c$$$        allocate(freq(nw))
c$$$        call genfreq (nw,dw,0.d0,
c$$$     o              freq )
c$$$      endif

c> index for allowed core states
c      call defi    (iicore,nl*nl*nnc*nclass)
c      call defi    (incore,nclass)
      allocate(icore(nl**2*nnc,nclass),ncore(nclass))
      icore=9999999
      ncore=9999999
      call incor   (ncwf,nindxc,iclass,
     d              nl,nnc,nclass,natom,
     o              icore,ncore,nctot )
ccccccccccccccccccccccccccccccccccccccccccccccccc
c      write(6,*)' nnc=',nnc,nl,nclass,natom
c      write(6,*)' ncwf ',ncwf
c      write(6,*)' nindxc ',nindxc
c      write(6,*)' iclass ',iclass
c      write(6,*)' --- icore=',icore
c      write(6,*)' --- ncore nctot=',ncore,nctot
ccccccccccccccccccccccccccccccccccccccccccccccccc

c> core energies
      ifec       = iopen ('ECORE',1,0,0)
      allocate(konf(nl,nclass),ecore(nctot,2))
      konf=0
      allocate(ecoret(0:nl-1,nnc,2,nclass))
      ecoret=0d0
      do ic = 1,nclass
        write(6,*) ' read ECORE : ic=',ic
        read (ifec,*) 
        read (ifec,*) 
        read (ifec,*) 
        read (ifec,*) !zz,ic1,nr ,a,b,nsp
        read (ifec,*) 
        read (ifec,*) (konf(l+1,ic),l=0,nl-1)
        read (ifec,*) 
        do  l = 0,nl-1
          ncorex = konf(l+1,ic)-l-1
          if (ncorex .gt. nnc) call rx( 'ECORE: wrong nnc')
          do n = 1,ncorex
            read (ifec,*) lt,nt,(ecoret(l,n,isp,ic),isp=1,nspin) !takao
            if(nspin==1) ecoret(l,n,2,ic) = ecoret(l,n,1,ic)        !
c           write(6,"(' read ecore=',3i4,2d13.5)")l,n,ic,ecoret(l,n,1:nspin,ic)
            if (lt .ne. l) call rx( 'rcore: wrong l')
            if (nt .ne. n) call rx( 'rcore: wrong n')
          end do
        end do
      end do
      i = 0
      do ia = 1,nclass
        ic  = iclass(ia)
        do l = 0,nl-1
        do n = 1,nnc
        do m = -l,l
          if (ncwf(l+1,n,ic) .eq. 1) then
            i = i + 1
            if (i > nctot) call rx( 'genalloc_mod: wrong nctot')
            ecore(i,1:nspin) = ecoret(l,n,1:nspin,ic)
            write(6,"(' ecore=',4i4,2d13.5)")i, l,n,ic,ecore(i,1:nspin)
          endif
        enddo
        enddo
        enddo
      enddo
      deallocate(ecoret)
c> index for core and LMTO basis
c      call defi    (iil,nlnmx*nclass)
c      call defi    (iin,nlnmx*nclass)
c      call defi    (iim,nlnmx*nclass)
c      call defi    (iilnm,nn*nl*nl*nclass)
c      call defi    (iilv,nlnmxv*nclass)
c      call defi    (iinv,nlnmxv*nclass)
c      call defi    (iimv,nlnmxv*nclass)
c      call defi    (iilnmv,nnv*nl*nl*nclass)
c      call defi    (iilc,nlnmxc*nclass)
c      call defi    (iinc,nlnmxc*nclass)
c      call defi    (iimc,nlnmxc*nclass)
c      call defi    (iilnmc,nnc*nl*nl*nclass)
      allocate(
     & il(nlnmx,nclass),
     & in(nlnmx,nclass),
     & im(nlnmx,nclass),
     & ilnm(nn*nl*nl*nclass),
     & ilv(nlnmxv*nclass),
     & inv(nlnmxv*nclass),
     & imv(nlnmxv*nclass),
     & ilnmv(nnv*nl*nl*nclass),
     & ilc(nlnmxc*nclass),
     & inc(nlnmxc*nclass),
     & imc(nlnmxc*nclass),
     & ilnmc(nnc*nl*nl*nclass)
     & )
      call idxlnmc ( nindxv,nindxc,
     d              nl,nn,nnv,nnc,nlnmx,nlnmxv,nlnmxc,nclass,
     o              il,in,im,ilnm,
     o              ilv,inv,imv,ilnmv,
     o              ilc,inc,imc,ilnmc)
      allocate(nlnmv(nclass),nlnmc(nclass),nlnm(nclass))
      call nolnma  (nindxv,nl,nclass,
     o              nlnmv )
      call nolnma  (nindxc,nl,nclass,
     o              nlnmc )
      call nolnma  (nindx,nl,nclass,
     o              nlnm )
      i=2 !see previous definition of symgrp
      if(symgrp(i+1:i+13)/= 'UseSYMOPSfile') then
        call rx( " Not: UseSYMOPSfile in LMTO file")
      endif
      write(6,*) ' symgrp==UseSYMOPSfile'
      ifi = 6661
      open (ifi, file='SYMOPS')
      read(ifi,*) ngrp
      allocate(symgg(3,3,ngrp))
      do ig = 1,ngrp
        read(ifi,*)
        do i=1,3
          read(ifi,"(3d24.16)") symgg(i,1:3,ig)
        enddo
      enddo
      close(ifi)
      allocate(invg(ngrp))
      call invgrp  (symgg,ngrp,
     o              invg)
      is = iclose ('LMTO')
      is = iclose ('ECORE')
      call cputid(0)
      write(6,*) 'genallcf_v3'
      end subroutine genallcf_v3
      end module

      subroutine idxlnmc(nindxv,nindxc,
     d                   nl,nn,nnv,nnc,nlnmx,nlnmxv,nlnmxc,nclass,
     o                   il,in,im,ilnm,
     o                   ilv,inv,imv,ilnmv,
     o                   ilc,inc,imc,ilnmc)
c 92.jan.07
c 92.03.17 include core states
c indexing of core states and LMTO basis functions for all classes,
c follows that in TB-LMTO program
c il,in,im = l,n,m
c ilnm(n,lm) = index of n,l,m
c lm = l*l + l + m + 1
c NOTE: the indexing starts with core first and then valence on top
c       of core (not the same as index generated from nindx)
      implicit real*8(a-h,o-z)
      dimension nindxv(0:nl-1,nclass),nindxc(0:nl-1,nclass)
      dimension ilnm(nn,nl*nl,nclass),
     o          ilnmv(nnv,nl*nl,nclass),
     o          ilnmc(nnc,nl*nl,nclass),
     o          in(nlnmx,nclass),il(nlnmx,nclass),im(nlnmx,nclass),
     o         inv(nlnmxv,nclass),ilv(nlnmxv,nclass),imv(nlnmxv,nclass),
     o         inc(nlnmxc,nclass),ilc(nlnmxc,nclass),imc(nlnmxc,nclass)
      do     ic = 1,nclass
        ind       = 0
c core
        do      l = 0,nl-1
          l2        = l*l
          do      n = 1,nindxc(l,ic)
            do      m = 1,2*l+1
              ind       = ind + 1
              if (ind .gt. nlnmx) call rx( 'idxlnmc: ind > nlnmx')
              lm        = l2 + m
              il(ind,ic)= l
              in(ind,ic)= n
              im(ind,ic)= m - l - 1
              ilnm(n,lm,ic) = ind
              ilc(ind,ic)= l
              inc(ind,ic)= n
              imc(ind,ic)= m - l - 1
              ilnmc(n,lm,ic)= ind
            end do
          end do
        end do
c valence
        indv      = 0
        do      l = 0,nl-1
          l2        = l*l
          ncore     = nindxc(l,ic)
          do      n = 1,nindxv(l,ic)
            if (ncore+n .gt. nn) call rx( 'idxlnmc: ncore+n > nn')
            do      m = 1,2*l+1
              ind       = ind + 1
              indv      = indv + 1
              if (ind .gt. nlnmx) call rx( 'idxlnmc: ind > nlnmx')
              lm        = l2 + m
              il(ind,ic)= l
              in(ind,ic)= ncore + n
              im(ind,ic)= m - l - 1
              ilnm(ncore+n,lm,ic) = ind
              ilv(indv,ic)= l
              inv(indv,ic)= n
              imv(indv,ic)= m - l - 1
              ilnmv(n,lm,ic) = indv
            end do
          end do
        end do
      end do
      return
      end

      integer function noflmto(nindx,iclass,nl,nclass,natom)
c total number of LMTO basis functions
      implicit real*8(a-h,o-z)
      dimension nindx(0:nl-1,nclass),iclass(natom)
      noflmto   = 0
      do 1    i = 1,natom
        ic        = iclass(i)
      do 1    l = 0,nl-1
        noflmto   = noflmto + (2*l+1)*nindx(l,ic)
    1 continue
      return
      end

      integer function nalwln (nocc,nunocc,nindx,nl,nn)
c gives the number of allowed product radial phi
c nocc(l,n)   = 0,1 ==> unoccupied, occupied
c nunocc(l,n) = 1,0 ==> unoccupied,occupied
c nalwln    = number of allowed phi(l1,n1) phi(l2,n2)
      implicit real*8(a-h,o-z)
      parameter (lmax=6,nnx=10)
      dimension nocc(0:nl-1,nn),nunocc(0:nl-1,nn),
     i          nindx(0:nl-1)
      dimension icheck(0:lmax,nnx,0:lmax,nnx)
      if (nl-1 .gt. lmax) call rx( 'nalwln: increase lmax')
      if (nn .gt. nnx) call rx( 'nalwln: increase nnx')
      icheck=0
      nalwln     = 0
      do 10   l1 = 0,nl-1
      do 10   n1 = 1,nindx(l1)
        if(nocc(l1,n1) .eq. 0)goto 10
        do 20   l2 = 0,nl-1
        do 20   n2 = 1,nindx(l2)
          if(nunocc(l2,n2) .eq. 0)goto 20
          if((l1.ne.l2 .or. n1.ne.n2) .and. icheck(l2,n2,l1,n1).ne.0)
     . goto 20
          nalwln     = nalwln + 1
          icheck(l1,n1,l2,n2) = nalwln
   20   continue
   10 continue
      return
      end

      integer function nofln(nindx,nl)
c count the number of l,n
      implicit real*8(a-h,o-z)
      dimension nindx(0:nl-1)
      nofln      = 0
      do       l = 0,nl-1
        nofln      = nofln + nindx(l)
      end do
      return
      end
c------------------------------------------------------------------
      integer function noflnm(nindx,nl)
c number of l,n,m
      implicit real*8(a-h,o-z)
      dimension nindx(0:nl-1)
      noflnm    = 0
      do 1    l = 0,nl-1
        noflnm    = noflnm + nindx(l)*(2*l+1)
    1 continue
      return
      end

      integer function nallow (nocc,nunocc,nindx,nl,nn)
c gives the number of allowed product basis
c nocc(n,l) = 0,1 ==> unoccupied, occupied
c nallow    = number of allowed product basis
      implicit real*8(a-h,o-z)
      parameter (lmax=6,nnx=10)
      dimension nocc(0:nl-1,nn),nunocc(0:nl-1,nn),
     i          nindx(0:nl-1)
      dimension icheck(0:lmax,nnx,0:lmax,nnx)
      if(nl-1 .gt. lmax) call rx( 'nallow: increase lmax')
      if(nn .gt. nnx) call rx( 'nallow: increase nnx')
      icheck=0
      do      l1 = 0,nl-1
        do      n1 = 1,nindx(l1)
          do      l2 = 0,nl-1
            do      n2 = 1,nindx(l2)
              icheck(l1,n1,l2,n2) = nocc(l1,n1)*nunocc(l2,n2)
              if (l1 .ne. l2 .or. n1 .ne. n2) then
                if (icheck(l1,n1,l2,n2)*icheck(l2,n2,l1,n1) .ne. 0)
     . icheck(l1,n1,l2,n2) = 0
              endif
            end do
          end do
        end do
      end do
      nallow     = 0
      do 10   l1 = 0,nl-1
      do 10   n1 = 1,nindx(l1)
      do 10   m1 = 1,2*l1+1
      do 10   l2 = 0,nl-1
      do 10   n2 = 1,nindx(l2)
      do 10   m2 = 1,2*l2+1
c     if (nocc(l1,n1) .eq. 0)goto 10
c     if (nunocc(l2,n2) .eq. 0)goto 10
        if (icheck(l1,n1,l2,n2) .eq. 0) goto 10
c temporary
        if (l1 .eq. l2 .and. n1.eq.n2 .and. m1.lt.m2)goto 10
        nallow     = nallow + 1
   10 continue
      return
      end

      subroutine incor  (ncwf,nindxc,iclass,
     d                   nl,nnc,nclass,natom,
     o                   icore,ncore,nctot)
c 92.03.18
c sorts out allowed core states and count the number of core states
c ncwf(l,n,cl) = 1 ==> allowed, 0 ==> not allowed
c nindxc(l,cl)  = no. core states/l,class
c nl,nnc = max. no. l,n
c icore(i,cl) = index for allowed core states
c ncore(cl)   = no. allowed core states
c nctot       = total no. allowed core states
      implicit real*8 (a-h,o-z)
      dimension ncwf(0:nl-1,nnc,nclass),nindxc(0:nl-1,nclass),
     i          iclass(natom)
      dimension icore(nl*nl*nnc,nclass),ncore(nclass)
      ncx        = nl*nl*nnc
      do      ic = 1,nclass
        i          = 0
        j          = 0
        do       l = 0,nl-1
          do       n = 1,nindxc(l,ic)
            do       m = -l,l
              j          = j + 1
              if (ncwf(l,n,ic) .eq. 1) then
                i          = i + 1
                if (i .gt. ncx) call rx( 'incore: wrong ncx')
                icore(i,ic)= j
              endif
            end do
          end do
        end do
        ncore(ic)  = i
      end do
c total no. allowed core states
      nctot      = 0
      do       i = 1,natom
        ic         = iclass(i)
        nctot      = nctot + ncore(ic)
      end do
      return
      end
