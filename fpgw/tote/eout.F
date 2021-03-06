      program eout
c-------------------------------------------------------------
c Gather datas from files and write final output.
c------------------------------------------------------------
      implicit none
      integer(4) :: ifx,ierr
      real(8) :: rydberg,eks, rhoexc, rhoexc2, exc_lda,exc_lda2,
     &    alat,etot,ex, exxcc, exxcv, exxvv, ecorr, ex_lda, ec_lda
      call getexx('TEEXXcc',exxcc,ierr)
      call getexx('TEEXXcv',exxcv,ierr)
      call getexx('TEEXXvv',exxvv,ierr)
      call getexx('TEECORR',ecorr,ierr)
      ifx = 101
      open(ifx,file='LATTC')
      read(ifx,*)alat
      close(ifx)
      open(ifx,file='ETOTLDA')
      read(ifx,*) eks
      read(ifx,*) exc_lda
      close(ifx)
      open(ifx,file='RoVxcLDA')
      read(ifx,*) exc_lda2
      read(ifx,*) ex_lda
      read(ifx,*) ec_lda
      if(exc_lda /= exc_lda2) then
        write(6,*) exc_lda, exc_lda2
Cstop2rx 2013.08.09 kino        stop ' eout:rhoexc in ETOTLDA and RoVxcLDA are not consistent'
        call rx( ' eout:rhoexc in ETOTLDA and RoVxcLDA are not consistent')
      endif
c
      Ex = exxcc + 2d0*exxcv + exxvv
      Etot= eks*rydberg() - exc_lda*rydberg() + ex + ecorr

      open(ifx,file='ETOTeV.dat',access='append')
      write(ifx,"(f12.6, 2(f18.6,f16.6,f15.6),
     &  ' ! alat   Etot Ex Ec  EtotLDA ExLDA EcLDA ')") 
     &  alat, Etot, ex, ecorr, 
     &  Eks*rydberg(), ex_lda*rydberg(), ec_lda*rydberg()
      close(ifx)
Cstop2rx 2013.08.09 kino      stop ' OK!: eout. Add data to ETOTeV.dat'
      call rx0( ' OK!: eout. Add data to ETOTeV.dat')
      end



c------------------------------------
      subroutine getexx(tefil,exx,ierr)
      character*(*) tefil
      real(8)::exx
      ifx = 101
      open(ifx,file=tefil)
      call readxx3(ifx,ierr)
      read (ifx,*) exx
      close(ifx)
      end

c This is taken from Ferdi's rw.f
c----------------------------------------
      subroutine readxx3(ifil,ierr)
      character*72 rchar
      integer(4):: n=1000
      ierr=0
      do 10 i = 1,n
        read(ifil,'(a)',end=1011,err=1011) rchar
c      print *, rchar
        j       = 0
        call rmvbl (rchar,72,j)
        rchar      = rchar(j+1:72)
        if(rchar(1:3) .eq. '***') return
   10 continue
 1011 continue
      ierr=1
c     stop 'readx: cannot find the string'
      end
      subroutine rmvbl(t,nt,i)
C- Parses string T(I) for blanks
      integer nt,i
      character*1 t(0:nt)
   99 if (t(i) .ne. ' ') return
      i = i + 1
      if (i .ge. nt) return
      goto 99
      end
c-------------------------------------------------------------------
