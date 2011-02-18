c
c revision log :
c
c 24.01.2011    ggu     written from scratch
c
c*******************************************************************

        subroutine triab(x,y,area,x0,y0)

c computes area and center point of triangle

        implicit none

        real x(3)
        real y(3)
        real area,x0,y0

        area = 0.5 * ( (x(2)-x(1))*(y(3)-y(1))
     +                  - (x(3)-x(1))*(y(2)-y(1)) )

        x0 = (x(1)+x(2)+x(3))/3.
        y0 = (y(1)+y(2)+y(3))/3.

        end

c*******************************************************************

        function areatr(ie)

c determination of area of element
c
c ie            number of element (internal)
c areatr        element area (return value)

	implicit none

        real areatr
        integer ie

        include 'param.h'

        real xgv(nkndim), ygv(nkndim)
        common /xgv/xgv, /ygv/ygv

        integer nen3v(3,neldim)
        common /nen3v/nen3v

        integer ii,k
        real x(3),y(3)

        do ii=1,3
	  k = nen3v(ii,ie)
	  x(ii) = xgv(k)
	  y(ii) = ygv(k)
        end do

        areatr = 0.5 * ( (x(2)-x(1))*(y(3)-y(1))
     +                  - (x(3)-x(1))*(y(2)-y(1)) )

        end

c*******************************************************************

        subroutine wrgrd(iunit,hkv,hev,ike)

c writes grd file from bas
c
c hev or hkv must be set

        implicit none

        integer iunit
        integer ike		!ike==1 -> depth on elements
        real hkv(1)
        real hev(1)

        include 'param.h'
        include 'basin.h'

        integer k,ie,ii

        do k=1,nkn
          if( ike .eq. 1 ) then
            write(iunit,1000) 1,ipv(k),0,xgv(k),ygv(k)
          else
            write(iunit,1000) 1,ipv(k),0,xgv(k),ygv(k),hkv(k)
          end if
        end do

        write(iunit,*)

        do ie=1,nel
          if( ike .eq. 1 ) then
            write(iunit,1100) 2,ipev(ie),iarv(ie)
     +          ,3,(ipv(nen3v(ii,ie)),ii=1,3),hev(ie)
          else
            write(iunit,1100) 2,ipev(ie),iarv(ie)
     +          ,3,(ipv(nen3v(ii,ie)),ii=1,3)
          end if
        end do

        return
 1000   format(i1,2i10,3e16.8)
 1100   format(i1,2i10,i4,3i10,e16.8)
        end

c*******************************************************************

	subroutine read_grd(gfile,hkv,hev,ike)

c reads grd file into basin structure

	implicit none

	character*(*) gfile
	real hkv(1)
	real hev(1)
	integer ike

	include 'param.h'
	include 'basin.h'

	logical bstop
	integer ner,nco,nli
	integer nlidim,nlndim
	integer nknh,nelh

	integer iaux(neldim)
	integer ipaux(neldim)
	real raux(neldim)

c-----------------------------------------------------------------
c initialize parameters
c-----------------------------------------------------------------

        ner = 6
        bstop = .false.

        nlidim = 0
        nlndim = 0

c-----------------------------------------------------------------
c read grd file
c-----------------------------------------------------------------

        call rdgrd(
     +                   gfile
     +                  ,bstop
     +                  ,nco,nkn,nel,nli
     +                  ,nkndim,neldim,nlidim,nlndim
     +                  ,ipv,ipev,iaux
     +                  ,iaux,iarv,iaux
     +                  ,hkv,hev,raux
     +                  ,xgv,ygv
     +                  ,nen3v
     +                  ,iaux,iaux
     +                  )

        if( bstop ) stop 'error stop after rdgrd'

        call ex2in(nkn,3*nel,nlidim,ipv,ipaux,nen3v,iaux,bstop)
        if( bstop ) stop 'error stop after ex2in'

c-----------------------------------------------------------------
c handling depth and coordinates
c-----------------------------------------------------------------

        call set_depth_flag(nkn,nel,hkv,hev,nknh,nelh)

        ike = 1
        if( nknh .gt. 0 ) ike = 2
        if( nknh .gt. 0 .and. nknh .ne. nkn ) goto 99
        if( nelh .gt. 0 .and. nelh .ne. nel ) goto 99
        if( nknh .eq. 0 .and. nelh .eq. 0 ) goto 99
        if( nknh .gt. 0 .and. nelh .gt. 0 ) goto 99

        call set_depth(hkv,hev,ike)

c-----------------------------------------------------------------
c general info
c-----------------------------------------------------------------

        write(6,*)
        write(6,*) ' nkn  = ',nkn, '  nel  = ',nel
        write(6,*) ' nknh = ',nknh,'  nelh = ',nelh
        write(6,*)

c-----------------------------------------------------------------
c end of routine
c-----------------------------------------------------------------

	return
   99   continue
        write(6,*) 'nelh,nknh: ',nelh,nknh
        stop 'error stop read_grd: error in depth values'
	end

c*******************************************************************

        subroutine node_test

	implicit none

        include 'param.h'
        include 'basin.h'

	logical bstop
        integer k,k1,ie,ii,iii

	bstop = .false.

        write(6,*) 'node_testing ... ',nel,nkn
        do ie=1,nel
          do ii=1,3
            k = nen3v(ii,ie)
            if( k .le. 0 ) then
		write(6,*) ie,ii,k
		bstop = .true.
	    end if
            iii = mod(ii,3) + 1
            k1 = nen3v(iii,ie)
            if( k .eq. k1 ) then
		write(6,*) ie,(nen3v(iii,ie),iii=1,3)
		bstop = .true.
	    end if
          end do
        end do
        write(6,*) 'end of node_testing ... '
	if( bstop ) stop 'error stop node_test: errors'

        end

c*******************************************************************

        subroutine set_depth_flag(nkn,nel,hkv,hev,nknh,nelh)

c handles depth values

        implicit none

        integer nkn,nel
        integer nknh,nelh
        real hev(1)
        real hkv(1)

        integer k,ie

        nknh = 0
        nelh = 0

        do k=1,nkn
          if( hkv(k) .gt. -990 ) nknh = nknh + 1
        end do

        do ie=1,nel
          if( hev(ie) .gt. -990 ) nelh = nelh + 1
        end do

        end

c*******************************************************************

        subroutine set_depth(hkv,hev,ike)

c sets hm3v values

        implicit none

	real hkv(1)
	real hev(1)
        integer ike

        include 'param.h'
        include 'basin.h'

        integer k,ie,ii

	if( ike .eq. 1 ) then		!elementwise
	  do ie=1,nel
	    do ii=1,3
	      hm3v(ii,ie) = hev(ie)
	    end do
	  end do
	else
	  do ie=1,nel
	    do ii=1,3
	      k = nen3v(ii,ie)
	      hm3v(ii,ie) = hkv(k)
	    end do
	  end do
	end if

        end

c*******************************************************************