c
c $Id: noselab.f,v 1.8 2008-11-20 10:51:34 georg Exp $
c
c revision log :
c
c 18.11.1998    ggu     check dimensions with dimnos
c 06.04.1999    ggu     some cosmetic changes
c 03.12.2001    ggu     some extra output -> place of min/max
c 09.12.2003    ggu     check for NaN introduced
c 07.03.2007    ggu     easier call
c 08.11.2008    ggu     do not compute min/max in non-existing layers
c 07.12.2010    ggu     write statistics on depth distribution (depth_stats)
c 06.05.2015    ggu     noselab started
c 05.06.2015    ggu     many more features added
c 10.09.2015    ggu     std and rms for averaging implemented
c 11.09.2015    ggu     write in gis format
c 23.09.2015    ggu     handle more than one file (look for itstart)
c
c**************************************************************

	subroutine noselab

	use clo
	use elabutil

        use basin
        use mod_depth
        use evgeom
        use levels

c elaborates nos file

	implicit none

	include 'param.h'

	integer, parameter :: ndim = 1000
	integer iusplit(ndim)

	real, allocatable :: cv2(:)
	real, allocatable :: cv3(:,:)
	real, allocatable :: cv3all(:,:,:)
	real, allocatable :: vol3(:,:)

	integer, allocatable :: ivars(:)
	integer, allocatable :: nodes(:)

	integer, allocatable :: naccu(:)
	double precision, allocatable :: accum(:,:,:)
	double precision, allocatable :: std(:,:,:,:)

	real, allocatable :: hl(:)

	integer nwrite,nread,nelab,nrec,nin,nold
	integer nvers
	integer nknnos,nelnos,nvar
	integer ierr
	integer it,ivar,itvar,itnew,itold,iaux,itstart
	integer i,j,l,k,lmax,nnodes,node
	integer ip,nb,naccum
	integer ifile
	character*80 title,name,file
	character*20 dline
	character*80 basnam,simnam
	real rnull
	real cmin,cmax,cmed,vtot

	integer iapini
	integer ifem_open_file

c--------------------------------------------------------------

	nread=0
	nwrite=0
	nelab=0
	nrec=0
	rnull=0.
	rnull=-1.
	bopen = .false.

c--------------------------------------------------------------
c set command line parameters
c--------------------------------------------------------------

	call elabutil_init('NOS')

	!--------------------------------------------------------------
	! open input files
	!--------------------------------------------------------------

	call ap_init(bask,modeb,0,0)

	!call open_nos_type('.nos','old',nin)
	ifile = 1
	call clo_get_file(ifile,file)
	call open_shy_file(file,'old',nin)
	write(6,*) '================================'
	write(6,*) 'reading file: ',trim(file)
	write(6,*) '================================'
	call clo_get_file(ifile+1,file)
	itstart = -1
	if( file /= ' ' ) call nos_get_it_start(file,itstart)

	call nos_is_nos_file(nin,nvers)
	if( nvers .le. 0 ) then
	  write(6,*) 'nvers: ',nvers
	  stop 'error stop noselab: not a valid nos file'
	end if

	call peek_nos_header(nin,nknnos,nelnos,nlv,nvar)

	if( bneedbasin ) then
	  if( nkn /= nknnos .or. nel /= nelnos ) goto 92
	else
	  nkn = nknnos
	  nel = nelnos
	end if

        call mod_depth_init(nkn,nel)
        call levels_init(nkn,nel,nlv)

	allocate(cv2(nkn))
	allocate(cv3(nlv,nkn))
	allocate(vol3(nlv,nkn))
	allocate(cv3all(nlv,nkn,nvar))
        allocate(hl(nlv))
	allocate(ivars(nvar))

	nlvdi = nlv
	call read_nos_header(nin,nkn,nel,nlvdi,ilhkv,hlv,hev)
	call nos_get_params(nin,nkn,nel,nlv,nvar)

	call init_sigma_info(nlv,hlv)

	if( bneedbasin ) then
	  call outfile_make_hkv(nkn,nel,nen3v,hev,hkv)
	  call init_volume(nlvdi,nkn,nel,nlv,nen3v,ilhkv
     +                          ,hlv,hev,hl,vol3)
	end if

	if( bverb ) call depth_stats(nkn,nlvdi,ilhkv)

	if( bnodes .or. bnode ) then
	  if( bnodes ) then
	    nnodes = 0
	    call get_node_list(nodefile,nnodes,nodes)
	    allocate(nodes(nnodes))
	    call get_node_list(nodefile,nnodes,nodes)
	  else
	    nnodes = 1
	    allocate(nodes(nnodes))
	    nodes(1) = nodesp
	  end if
	  write(6,*) 'nodes: ',nnodes,(nodes(i),i=1,nnodes)
	  call convert_internal_nodes(nnodes,nodes)
	  bnodes = .true.
	end if

	!--------------------------------------------------------------
	! time management
	!--------------------------------------------------------------

	call nos_get_date(nin,date,time)
	call elabutil_date_and_time

	!--------------------------------------------------------------
	! averaging
	!--------------------------------------------------------------

	call elabutil_set_averaging(nvar)

	if( btrans ) then
	  allocate(naccu(istep))
	  allocate(accum(nlvdi,nkn,istep))
	  allocate(std(nlvdi,nkn,16,istep))	!also used for directions
	  naccum = 0
	  naccu = 0
	  accum = 0.
	  std = 0.
	end if

	!write(6,*) 'mode: ',mode,ifreq,istep

	!--------------------------------------------------------------
	! open output file
	!--------------------------------------------------------------

	iusplit = 0

	boutput = boutput .or. btrans
	bopen = boutput .and. .not. bsplit

	if( bopen ) then
          call open_nos_file('out','new',nb)
          call nos_init(nb,0)
          call nos_clone_params(nin,nb)
	  if( b2d ) then
	    call nos_set_params(nb,0,0,1,0)
	  end if
          call write_nos_header(nb,ilhkv,hlv,hev)
	end if

	if( outformat == 'gis' ) call gis_write_connect

c--------------------------------------------------------------
c loop on data
c--------------------------------------------------------------

	it = 0
	!if( .not. bquiet ) write(6,*)

	cv3 = 0.

	do

	 itold = it

	 do i=1,nvar
	  call nos_read_record(nin,it,ivar,nlvdi,ilhkv,cv3,ierr)
          if(ierr.gt.0) write(6,*) 'error in reading file : ',ierr
          if(ierr.ne.0) exit
	  if( i == 1 ) itvar = it
	  if( itvar /= it ) goto 85
	  ivars(i) = ivar
	  cv3all(:,:,i) = cv3(:,:) * fact
	  nread=nread+1
	 end do

         if(ierr.ne.0) then	!EOF - see if we have to read another file
	   it = itold
	   if( itstart == -1 ) exit
	   nold = nin
	   ifile = ifile + 1
	   call clo_get_file(ifile,file)
	   call open_shy_file(file,'old',nin)
	   write(6,*) '================================'
	   write(6,*) 'reading file: ',trim(file)
	   write(6,*) '================================'
	   call read_nos_header(nin,nkn,nel,nlvdi,ilhkv,hlv,hev)
	   call nos_check_compatibility(nin,nold)
	   call nos_peek_record(nin,itnew,iaux,ierr)
	   call nos_get_date(nin,date,time)
	   call elabutil_date_and_time
	   it = itold		!reset time of last successfully read record
	   call nos_close(nold)
	   close(nold)
	   call clo_get_file(ifile+1,file)
	   itstart = -1
	   if( file /= ' ' ) call nos_get_it_start(file,itstart)
	   cycle
	 end if

	 nrec = nrec + 1

	 if( nrec == 1 ) itold = it
	 call nos_peek_record(nin,itnew,iaux,ierr)
	 !write(6,*) 'peek: ',it,itnew,ierr
	 if( ierr .ne. 0 ) itnew = it

	 if( .not. elabutil_check_time(it,itnew,itold) ) cycle

	 do i=1,nvar

	  ivar = ivars(i)
	  cv3(:,:) = cv3all(:,:,i)

	  nelab=nelab+1

	  if( .not. bquiet ) then
	    dline = ' '
	    if( bdate ) call dtsgf(it,dline)
	    write(6,*) 'time : ',it,'  ',dline,'   ivar : ',ivar
	  end if

	  if( bwrite ) then
	    do l=1,nlv
	      do k=1,nkn
	        cv2(k)=cv3(l,k)
	        if( l .gt. ilhkv(k) ) cv2(k) = rnull
	      end do
	      call mimar(cv2,nkn,cmin,cmax,rnull)
              call aver(cv2,nkn,cmed,rnull)
              call check1Dr(nkn,cv2,0.,-1.,"NaN check","cv2")
	      write(6,*) 'l,min,max,aver : ',l,cmin,cmax,cmed
	    end do
	  end if

	  if( btrans ) then
	    call nos_time_aver(mode,i,ifreq,istep,nkn,nlvdi
     +				,naccu,accum,std,threshold,cv3,boutput)
	  end if

	  if( baverbas ) then
	    call make_aver(nlvdi,nkn,ilhkv,cv3,vol3
     +                          ,cmin,cmax,cmed,vtot)
	    call write_aver(it,ivar,cmin,cmax,cmed,vtot)
	  end if

	  if( b2d ) then
	    call make_vert_aver(nlvdi,nkn,ilhkv,cv3,vol3,cv2)
	  end if

	  if( bsplit ) then
            call get_split_iu(ndim,iusplit,ivar,nin,ilhkv,hlv,hev,nb)
	  end if

	  if( boutput ) then
	    nwrite = nwrite + 1
	    if( bverb ) write(6,*) 'writing to output: ',ivar
	    if( bsumvar ) ivar = 30
	    if( b2d ) then
              call noselab_write_record(nb,it,ivar,1,ilhkv,cv2,ierr)
	    else
              call noselab_write_record(nb,it,ivar,nlvdi,ilhkv,cv3,ierr)
	    end if
            if( ierr .ne. 0 ) goto 99
	  end if

	  if( bnodes ) then
	    do j=1,nnodes
	      node = nodes(j)
	      call write_node(j,node,cv3,it,ivar)
	    end do
	  end if

	 end do		!loop on ivar
	end do		!time do loop

c--------------------------------------------------------------
c end of loop on data
c--------------------------------------------------------------

c--------------------------------------------------------------
c final write of variables
c--------------------------------------------------------------

	if( btrans ) then
	  !write(6,*) 'istep,naccu: ',istep,naccu
	  do ip=1,istep
	    naccum = naccu(ip)
	    !write(6,*) 'naccum: ',naccum
	    if( naccum > 0 ) then
	      nwrite = nwrite + 1
	      write(6,*) 'final aver: ',ip,naccum
	      call nos_time_aver(-mode,ip,ifreq,istep,nkn,nlvdi
     +				,naccu,accum,std,threshold,cv3,boutput)
	      if( bsumvar ) ivar = 30
              call nos_write_record(nb,it,ivar,nlvdi,ilhkv,cv3,ierr)
              if( ierr .ne. 0 ) goto 99
	    end if
	  end do
	end if

c--------------------------------------------------------------
c write final message
c--------------------------------------------------------------

	write(6,*)
	write(6,*) nread, ' records read'
	write(6,*) nrec , ' unique time records read'
	write(6,*) nelab, ' records elaborated'
	write(6,*) ifile, ' files read'
	write(6,*) nwrite,' records written'
	write(6,*)

	if( bsplit ) then
	  write(6,*) 'output written to following files: '
	  do ivar=1,ndim
	    nb = iusplit(ivar)
	    if( nb .gt. 0 ) then
              write(name,'(i4)') ivar
	      write(6,*) trim(adjustl(name))//'.nos'
	      close(nb)
	    end if
	  end do
	else if( boutput ) then
	  write(6,*) 'output written to file out.nos'
	  close(nb)
	end if

	call ap_get_names(basnam,simnam)
	write(6,*) 'names used: '
	write(6,*) 'basin: ',trim(basnam)
	write(6,*) 'simul: ',trim(simnam)

c--------------------------------------------------------------
c end of routine
c--------------------------------------------------------------

	stop
   85	continue
	write(6,*) 'it,itvar,i,ivar,nvar: ',it,itvar,i,ivar,nvar
	stop 'error stop noselab: time mismatch'
   92	continue
	write(6,*) 'incompatible basin: '
	write(6,*) 'nkn,nknnos: ',nkn,nknnos
	write(6,*) 'nel,nelnos: ',nel,nelnos
	stop 'error stop noselab: parameter mismatch'
   99	continue
	write(6,*) 'error writing to file unit: ',nb
	stop 'error stop noselab: write error'
	end

c***************************************************************
c***************************************************************
c***************************************************************

	subroutine nos_time_aver(mode,nread,ifreq,istep,nkn,nlvddi
     +				,naccu,accum,std,threshold,cv3,bout)

c mode:  1:aver  2:sum  3:min  4:max  5:std  6:rms  7:thres  8:averdir
c
c mode negative: only transform, do not accumulate

	implicit none

	integer mode
	integer nread,ifreq,istep
	integer nkn,nlvddi
	integer naccu(istep)
	double precision accum(nlvddi,nkn,istep)
	double precision std(nlvddi,nkn,16,istep)
	double precision threshold
	real cv3(nlvddi,nkn)
	logical bout

	integer ip,naccum,mmode
	integer k,l,id,idmax
	double precision dmax

	if( mode .eq. 0 ) return

	bout = .false.
	ip = mod(nread,istep)
	if( ip .eq. 0 ) ip = istep

	!write(6,*) 'ip: ',ip,istep,nread,mode

	if( mode == 1 .or. mode == 2 ) then
	  accum(:,:,ip) = accum(:,:,ip) + cv3(:,:)
	else if( mode == 3 ) then
	  do k=1,nkn
	    do l=1,nlvddi
	      accum(l,k,ip) = min(accum(l,k,ip),cv3(l,k))
	    end do
	  end do
	else if( mode == 4 ) then
	  do k=1,nkn
	    do l=1,nlvddi
	      accum(l,k,ip) = max(accum(l,k,ip),cv3(l,k))
	    end do
	  end do
	else if( mode == 5 ) then
	  accum(:,:,ip) = accum(:,:,ip) + cv3(:,:)
	  std(:,:,1,ip) = std(:,:,1,ip) + cv3(:,:)**2
	else if( mode == 6 ) then
	  accum(:,:,ip) = accum(:,:,ip) + cv3(:,:)**2
	else if( mode == 7 ) then
	  where( cv3(:,:) >= threshold )
	    accum(:,:,ip) = accum(:,:,ip) + 1.
	  end where
	else if( mode == 8 ) then
	  do k=1,nkn
	    do l=1,nlvddi
	      id = nint( cv3(l,k)/22.5 )
	      if( id == 0 ) id = 16
	      if( id < 0 .or. id > 16 ) stop 'error stop: direction'
	      std(l,k,id,ip) = std(l,k,id,ip) + 1.
	    end do
	  end do
	end if

	if( mode > 0 ) naccu(ip) = naccu(ip) + 1
	!write(6,*) '... ',ifreq,mode,ip,istep,naccu(ip)

	if( naccu(ip) == ifreq .or. mode < 0 ) then	!here ip == 1
	  naccum = max(1,naccu(ip))
	  mmode = abs(mode)
	  if( mmode == 3 ) naccum = 1			!min
	  if( mmode == 4 ) naccum = 1			!max
	  if( mmode == 7 ) naccum = 1			!threshold
	  if( naccum > 0 ) cv3(:,:) = accum(:,:,ip)/naccum
	  if( mmode == 5 ) then
	    cv3(:,:) = sqrt( std(:,:,1,ip)/naccum - cv3(:,:)**2 )
	  else if( mmode == 6 ) then
	    cv3(:,:) = sqrt( cv3(:,:) )
	  else if( mmode == 8 ) then
	    do k=1,nkn
	      do l=1,nlvddi
		dmax = 0.
		idmax = 0
	        do id=1,16
		  if( std(l,k,id,ip) > dmax ) then
		    idmax = id
		    dmax = std(l,k,id,ip)
		  end if
		end do
		if( idmax == 16 ) idmax = 0
		cv3(l,k) = idmax * 22.5
	      end do
	    end do
	  end if
	  write(6,*) 'averaging: ',ip,naccum,naccu(ip)
	  bout = .true.
	  naccu(ip) = 0
	  accum(:,:,ip) = 0.
	  std(:,:,:,ip) = 0.
	end if

	end

c***************************************************************

        subroutine get_split_iu(ndim,iu,ivar,nin,ilhkv,hlv,hev,nb)

        implicit none

        integer ndim
        integer iu(ndim)
        integer ivar
        integer nin
        integer ilhkv(1)
        real hlv(1)
        real hev(1)
	integer nb		!unit to use for writing (return)

        integer nkn,nel,nlv,nvar
        integer ierr
        character*80 name

        if( ivar > ndim ) then
          write(6,*) 'ndim,ivar: ',ndim,ivar
          stop 'error stop: ndim'
        end if

        if( iu(ivar) .le. 0 ) then      !open file
          write(name,'(i4)') ivar
          call open_nos_file(name,'new',nb)
          call nos_init(nb,0)
          call nos_clone_params(nin,nb)
          call nos_get_params(nb,nkn,nel,nlv,nvar)
          call nos_set_params(nb,nkn,nel,nlv,1)
          call write_nos_header(nb,ilhkv,hlv,hev)
          iu(ivar) = nb
        end if

        nb = iu(ivar)

        end

c***************************************************************

	subroutine noselab_write_record(nb,it,ivar,nlvdi,ilhkv,cv,ierr)

        use elabutil

	implicit none

	integer nb,it,ivar,nlvdi
	integer ilhkv(nlvdi)
	real cv(nlvdi,*)
	integer ierr

	ierr = 0

	if( outformat == 'nos' .or. outformat == 'native') then
          call nos_write_record(nb,it,ivar,nlvdi,ilhkv,cv,ierr)
	else if( outformat == 'gis' ) then
          call gis_write_record(nb,it,ivar,nlvdi,ilhkv,cv)
	else
	  write(6,*) 'output format unknown: ',outformat
	  stop 'error stop noselab_write_record: output format'
	end if

        end

c***************************************************************

        subroutine gis_write_record(nb,it,ivar,nlvdi,ilhkv,cv)

c writes one record to file nb (3D)

        use basin

        implicit none

        integer nb,it,ivar,nlvdi
        integer ilhkv(nlvdi)
        real cv(nlvdi,*)

        integer k,l,lmax
	integer nout
        real x,y
	character*80 format,name
	character*20 line
	character*3 var

	integer ifileo

	call dtsgf(it,line)
	call i2s0(ivar,var)

	name = 'extract_'//var//'_'//line//'.gis'
        nout = ifileo(60,name,'form','new')
	!write(6,*) 'writing: ',trim(name)

        write(nout,*) it,nkn,ivar,line

        do k=1,nkn
          lmax = ilhkv(k)
          x = xgv(k)
          y = ygv(k)

	  write(format,'(a,i5,a)') '(i10,2g14.6,i5,',lmax,'g14.6)'
          write(nout,format) k,x,y,lmax,(cv(l,k),l=1,lmax)
        end do

	close(nout)

        end

c***************************************************************

        subroutine gis_write_connect

c writes connectivity

        use basin

        implicit none

	integer ie,ii

	open(1,file='connectivity.gis',form='formatted',status='unknown')

	write(1,*) nel
	do ie=1,nel
	  write(1,*) ie,(nen3v(ii,ie),ii=1,3)
	end do

	close(1)

	end

c***************************************************************