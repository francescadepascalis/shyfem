!
! shyelab_nodes.f: utility for extracting nodes
!
! revision log :
!
! 07.10.2017    ggu     restructured
!
!***************************************************************

	subroutine initialize_nodes

	use elabutil

	implicit none

	integer i
	integer nodes_dummy(1)

          if( bnodes ) then
            nnodes = 0
            call get_node_file(nodefile,nnodes,nodes_dummy)
            allocate(nodes(nnodes))
            allocate(nodese(nnodes))
            call get_node_file(nodefile,nnodes,nodes)
          else if( bnode ) then
            nnodes = 0
            call get_node_list(nodelist,nnodes,nodes_dummy)
            allocate(nodes(nnodes))
            allocate(nodese(nnodes))
            call get_node_list(nodelist,nnodes,nodes)
          end if

	  if( nnodes <= 0 ) return

          if( bnode ) bnodes = .true.
 
	  nodese = nodes
	  if( .not. bquiet ) then
	    write(6,*) 'Nodes to be extracted: ',nnodes
            write(6,*) (nodes(i),i=1,nnodes)
	  end if
          call convert_internal_nodes(nnodes,nodes)

	end subroutine initialize_nodes

!***************************************************************
!***************************************************************
!***************************************************************

	subroutine write_nodes(atime,ftype,nndim,nvar,ivars,cv3all)

! manages writing of nodes

	use basin
	use levels

	implicit none

	double precision atime
	integer ftype
	integer nndim
	integer nvar
	integer ivars(nvar)
	real cv3all(nlvdi,nndim,0:nvar)

	logical bhydro,bscalar
	real znv(nkn)
	real uprv(nlvdi,nkn)
	real vprv(nlvdi,nkn)

	bhydro = ( ftype == 1 )
	bscalar = ( ftype == 2 )

        if( bhydro ) then    !hydro output
          call prepare_hydro(.true.,nndim,cv3all,znv,uprv,vprv)
          call write_nodes_hydro_ts(atime,znv,uprv,vprv)
          !write(6,*) 'ggguuu no hang with this write statement'
          call write_nodes_hydro_fem(atime,znv,uprv,vprv)
        else if( bscalar ) then
          call write_nodes_scalar_ts(atime,nndim,nvar,ivars,cv3all)
          call write_nodes_scalar_fem(atime,nndim,nvar,ivars,cv3all)
        end if

	end subroutine write_nodes

!***************************************************************

	subroutine write_nodes_final(ftype,nvar,ivars)

! final write to show what files have been written

	use elabutil
	use shyfem_strings

	implicit none

	integer ftype
	integer nvar
	integer ivars(nvar)

	logical bhydro,bscalar
	integer i,iv,ivar
	character*40 format,range
	character*20 filename
	character*15 short
	character*40 full

	integer, parameter :: niu = 6
        character*5, save :: what(niu) = (/'velx ','vely ','zeta '
     +                          ,'speed','dir  ','all  '/)
        character*26, save :: descrp(niu) = (/
     +           'velocity in x-direction   '
     +          ,'velocity in y-direction   '
     +          ,'water level               '
     +          ,'current speed             '
     +          ,'current direction         '
     +          ,'all hydrodynamic variables'
     +					/)

	bhydro = ( ftype == 1 )
	bscalar = ( ftype == 2 )

        write(6,*) 'output has been written to the following files: '
	filename = 'out.fem'
        write(6,*) '  ',filename,'all variables in fem format'

	if( bhydro ) then
          write(6,*) '  what.dim.node'
          write(6,*) 'what is one of the following:'
	  call write_special_vars(niu,what,descrp)      !write hydro variables
	  call write_special_vars(1,'vel_profile'
     +				,'profile for velocities')
          write(6,*) 'dim is 2d or 3d'
          write(6,*) '  2d for depth averaged variables'
          write(6,*) '  3d for output at each layer'
	  call compute_range(nnodes,range)
	  write(6,'(a)') ' node is consecutive node numbering: '
     +				,trim(range)
	  write(6,*) 'the 4 columns in vel_profile.3d.* are:'
	  write(6,*) '  depth,velx,vely,speed'
	end if

	if( bscalar ) then
          write(6,*) '  what.dim.node'
          write(6,*) 'what is one of the following:'
	  call write_vars(nvar,ivars)
	  call write_vars(iv,ivars)
	  call write_extra_vars(iv,ivars,'_p',' (profile)')
          write(6,*) 'dim is 2d or 3d'
          write(6,*) '  2d for depth averaged variables'
          write(6,*) '  3d for output at each layer'
	  call compute_range(nnodes,range)
	  write(6,'(a,a)') ' node is consecutive node numbering: '
     +				,trim(range)
	  write(6,*) 'the 2 columns in *_p.3d.* are:'
	  write(6,*) '  depth,value'
	end if

	end subroutine write_nodes_final

!***************************************************************
!***************************************************************
!***************************************************************

        subroutine convert_internal_nodes(n,nodes)

        use basin

        implicit none

        integer n
        integer nodes(n)

        integer ne,ni,i
        integer ipint

        if( n <= 0 ) return

	do i=1,n
	  ne = nodes(i)
          if( ne <= 0 ) goto 99
          ni = ipint(ne)
          if( ni <= 0 ) goto 98
	  nodes(i) = ni
        end do

	return
   98	continue
        write(6,*) 'cannot find node: ',ne
        stop 'error stop convert_internal_nodes: no such node'
   99	continue
        write(6,*) 'cannot convert node: ',ne
        stop 'error stop convert_internal_nodes: no such node'
        end

!***************************************************************

	subroutine get_node_list(list,n,nodes)

! for n == 0 only checks how many nodes to read
! for n > 0 reads nodes into nodes() (error if n is too small)

	implicit none

	character*(*) list
	integer n
	integer nodes(n)

	integer nscan,ndim
	double precision d(n)
	integer iscand

	ndim = n
	nscan = iscand(list,d,0)

	if( nscan < 0 ) then
	  goto 98
	else if( ndim <= 0 ) then		!only count
	  n = nscan
	else if( nscan > ndim ) then
	  goto 96
	else if( nscan == 0 ) then
	  goto 97
	else
	  nscan = iscand(list,d,ndim)
	  n = nscan
	  nodes(1:n) = nint(d(1:n))
	end if
	  
	return
   96	continue
	write(6,*) 'nscan,ndim :',nscan,ndim
	write(6,*) 'list: ',trim(list)
	stop 'error stop get_node_list: dimension error'
   97	continue
	write(6,*) 'no data in list: ',trim(list)
	stop 'error stop get_node_list: no data'
   98	continue
	write(6,*) 'nscan: ',nscan
	write(6,*) 'error in read of list: ',trim(list)
	stop 'error stop get_node_list: read error'
	end

!***************************************************************

	subroutine get_node_file(file,n,nodes)

! for n == 0 only checks how many nodes to read
! for n > 0 reads nodes into nodes() (error if n is too small)

	implicit none

	character*(*) file
	integer n
	integer nodes(n)

	integer nin,ios,node,ndim
	logical btest

	integer ifileo

	nin = ifileo(0,file,'form','old')
	if( nin .le. 0 ) goto 99

	ndim = n
	btest = ndim == 0

	n = 0
	do
	  read(nin,*,iostat=ios) node
	  if( ios > 0 ) goto 98
	  if( ios < 0 ) exit
	  if( node .le. 0 ) exit
	  n = n + 1
	  if( .not. btest ) then
	    if( n > ndim ) goto 96
	    nodes(n) = node
	  end if
	end do

	if( n == 0 ) goto 97

	close(nin)

	return
   96	continue
	write(6,*) 'n,ndim :',n,ndim
	write(6,*) 'file: ',trim(file)
	stop 'error stop get_node_file: dimension error'
   97	continue
	write(6,*) 'no data in file ',trim(file)
	stop 'error stop get_node_file: no data'
   98	continue
	write(6,*) 'read error in record ',n
	write(6,*) 'in file ',trim(file)
	stop 'error stop get_node_file: read error'
   99	continue
	write(6,*) 'file: ',trim(file)
	stop 'error stop get_node_file: cannot open file'
	end

!***************************************************************
!***************************************************************
!***************************************************************

	subroutine write_nodes_scalar_ts(atime,nndim,nvar,ivars,cv3all)

! writes scalar values for single nodes

	use shyfem_strings

	use levels
	use elabutil
	use mod_depth

	implicit none

	double precision atime
	integer nvar,nndim
	integer ivars(nvar)
	real cv3all(nlvdi,nndim,0:nvar)

	logical b3d
	integer j,node,it,i,ivar,iv
	integer iu
	integer ki,ke,lmax,l
	real h,z,s0
	real hl(nlvdi)
	real scal(nlvdi)
	integer isubs(nvar)
	character*80 format,name
	character*10 numb,short
	character*20 fname
	character*20 dline
	character*20 filename(nvar)
	integer, save :: icall = 0
	integer, save :: iuall2d = 0
	integer, save :: iuall3d = 0
	integer, save, allocatable :: ius(:,:,:)

	real cv3(nlvdi,nndim)	!to be deleted

	if( nnodes <= 0 ) return
	if( .not. bcompat ) return

	iu = 0
	b3d = nlv > 1

!-----------------------------------------------------------------
! open files
!-----------------------------------------------------------------

	if( icall == 0 ) then
	  
	  allocate(ius(nvar,nnodes,3))
	  ius = 0

	  do iv=1,nvar
	    call ivar2filename(ivars(iv),filename(iv))
	  end do

	  do j=1,nnodes
            write(numb,'(i5)') j
            numb = adjustl(numb)
	    do iv=1,nvar
	      fname = filename(iv)
	      call make_iunit_name(fname,'','2d',j,iu)
	      ius(iv,j,2) = iu
	      if( .not. b3d ) cycle
	      call make_iunit_name(fname,'','3d',j,iu)
	      ius(iv,j,3) = iu
	      call make_iunit_name(fname,'_p','3d',j,iu)
	      ius(iv,j,1) = iu
	    end do
	  end do
	  name = 'all_scal_nodes.2d.txt'
	  call get_new_unit(iuall2d)
          open(iuall2d,file=name,form='formatted',status='unknown')
	  if( b3d ) then
	    name = 'all_scal_nodes.3d.txt'
	    call get_new_unit(iuall3d)
            open(iuall3d,file=name,form='formatted',status='unknown')
	  end if
	end if
	icall = icall + 1

!-----------------------------------------------------------------
! write files
!-----------------------------------------------------------------

        call dts_format_abs_time(atime,dline)

        do j=1,nnodes
          ki = nodes(j)
          ke = nodese(j)
	  lmax = ilhkv(ki)
          h = hkv(ki)
          z = cv3all(1,ki,0)
	  format = ' '
	  if( b3d ) write(format,'(a,i3,a)') '(a20,',lmax,'f8.3)'

	  do iv=1,nvar
	    ivar = ivars(iv)
	    scal = cv3all(:,ki,iv)
	    call average_vertical_node(lmax,hlv,z,h,scal,s0)
	    iu = ius(iv,j,2)
	    write(iu,*) dline,s0
            write(iuall2d,'(a20,5i10)') dline,j,ke,ki,lmax,ivar
            write(iuall2d,*) s0
	    if( .not. b3d ) cycle
	    iu = ius(iv,j,3)
	    write(iu,format) dline,scal(1:lmax)
	    iu = ius(iv,j,1)
	    call write_profile_c(iu,dline,j,ki,ke,lmax,ivar,h,z,scal,hlv)
            write(iuall3d,'(a20,5i10)') dline,j,ke,ki,lmax,ivar
            write(iuall3d,*) scal(1:lmax)
	  end do
        end do

	end subroutine write_nodes_scalar_ts

!***************************************************************

	subroutine write_nodes_hydro_ts(atime,znv,uprv,vprv)

! writes hydro values for single nodes

	use levels
	use mod_depth
	use elabutil

	implicit none

	double precision atime
	real znv(*)
	real uprv(nlvdi,*)
	real vprv(nlvdi,*)

	logical b3d,debug
	integer i,j,ki,ke,lmax,it,l,k
	integer iu
	real z,h,u0,v0,s0,d0
	real hl(nlvdi)
	real u(nlvdi),v(nlvdi),s(nlvdi),d(nlvdi)
	integer, save :: icall = 0
	integer, save :: iuall = 0
	integer, save, allocatable :: ius(:,:,:)
	integer, parameter :: niu = 6
        character*5 :: what(niu) = (/'velx ','vely ','zeta '
     +                          ,'speed','dir  ','all  '/)
	character*5 :: numb
	character*10 short
	character*20 dline
	character*80 name
	character*80 format

	if( nnodes <= 0 ) return
	if( .not. bcompat ) return

	debug = .false.
	b3d = nlv > 1

!-----------------------------------------------------------------
! open files
!-----------------------------------------------------------------

	if( icall == 0 ) then
	  allocate(ius(niu,nnodes,3))
	  ius = 0
	  do j=1,nnodes
	    do i=1,niu
	      short = what(i)
	      call make_iunit_name(short,'','2d',j,iu)
	      ius(i,j,2) = iu
	      if( .not. b3d ) cycle
	      if( i == niu ) cycle	!do not write all.3d.*
	      call make_iunit_name(short,'','3d',j,iu)
	      ius(i,j,3) = iu
	    end do
	    if( b3d ) then
	      call make_iunit_name('vel','_p','3d',j,iu)
	      ius(1,j,1) = iu
	    end if
	  end do
	  if( debug ) then
	    name = 'all_nodes.3d.txt'
	    call get_new_unit(iuall)
            open(iuall,file=name,form='formatted',status='unknown')
	  end if
	end if
	icall = icall + 1

!-----------------------------------------------------------------
! write files
!-----------------------------------------------------------------

        call dts_format_abs_time(atime,dline)

        do j=1,nnodes
          ki = nodes(j)
          ke = nodese(j)
	  lmax = ilhkv(ki)

	  if( iuall > 0 ) then
            write(iuall,'(a20,5i10)') dline,j,ke,ki,lmax
            write(iuall,*) znv(ki)
            write(iuall,*) (uprv(l,ki),l=1,lmax)
            write(iuall,*) (vprv(l,ki),l=1,lmax)
	  end if

          z = znv(ki)
          h = hkv(ki)
	  u = uprv(:,ki)
	  v = vprv(:,ki)

	  call average_vertical_node(lmax,hlv,z,h,u,u0)
	  call average_vertical_node(lmax,hlv,z,h,v,v0)
	  call c2p_ocean(u0,v0,s0,d0)

	  iu = ius(1,j,2)
	  write(iu,*) dline,u0
	  iu = ius(2,j,2)
	  write(iu,*) dline,v0
	  iu = ius(3,j,2)
	  write(iu,*) dline,z
	  iu = ius(4,j,2)
	  write(iu,*) dline,s0
	  iu = ius(5,j,2)
	  write(iu,*) dline,d0
          iu = ius(6,j,2)
          write(iu,'(a20,5f12.4)') dline,z,u0,v0,s0,d0

	  if( .not. b3d ) cycle

	  write(format,'(a,i3,a)') '(a20,',lmax,'f8.3)'
	  do l=1,lmax
	    call c2p_ocean(u(l),v(l),s(l),d(l))
	  end do

	  iu = ius(1,j,3)
	  write(iu,format) dline,u(1:lmax)
	  iu = ius(2,j,3)
	  write(iu,format) dline,v(1:lmax)
	  iu = ius(3,j,3)
	  write(iu,format) dline,z
	  iu = ius(4,j,3)
	  write(iu,format) dline,s(1:lmax)
	  iu = ius(5,j,3)
	  write(iu,format) dline,d(1:lmax)

	  iu = ius(1,j,1)
          call write_profile_uv(iu,dline,j,ki,ke,lmax,h,z,u,v,hlv)
        end do

!-----------------------------------------------------------------
! end of routine
!-----------------------------------------------------------------

	end subroutine write_nodes_hydro_ts

!***************************************************************
!***************************************************************
!***************************************************************

	subroutine write_nodes_scalar_fem(atime,nndim,nvar,ivars,cv3all)

! writes FEM file out.fem - version for scalars

	use levels
	use mod_depth
	use elabutil
	use elabtime
	use shyfem_strings

	implicit none

	double precision atime
	integer nvar,nndim
	integer ivars(nvar)
	real cv3all(nlvdi,nndim,0:nvar)

	integer j,iv,node
	integer iformat,lmax,np,nvers,ntype
	integer date,time,datetime(2)
	double precision dtime
	real regpar(7)
	real cv3(nlvdi,nnodes,nvar)
	integer il(nnodes)
	real hd(nnodes)
	character*80 file,string
	character*80 strings(nvar)
	integer, save :: iunit = 0
	integer ifileo

	if( nnodes <= 0 ) return

	if( iunit == 0 ) then
          file = 'out.fem'
          iunit = ifileo(60,file,'form','unknown')
          if( iunit <= 0 ) goto 74
	end if

	do iv=1,nvar
          do j=1,nnodes
            node = nodes(j)
	    cv3(:,j,iv) = cv3all(:,node,iv)
	  end do
	  call ivar2femstring(ivars(iv),strings(iv))
        end do
        do j=1,nnodes
          node = nodes(j)
	  il(j) = ilhkv(node)
	  hd(j) = hkv_max(node)
	end do

        nvers = 0
	iformat = 1
	ntype = 1
        np = nnodes
        lmax = nlv

	dtime = 0.
        call dts_from_abs_time(date,time,atime)
	datetime = (/date,time/)

        call fem_file_write_header(iformat,iunit,dtime
     +                          ,nvers,np,lmax
     +                          ,nvar,ntype
     +                          ,nlvdi,hlv,datetime,regpar)

	do iv=1,nvar
	  string = strings(iv)
          call fem_file_write_data(iformat,iunit
     +                          ,nvers,np,lmax
     +                          ,string
     +                          ,il,hd
     +                          ,nlvdi,cv3(:,:,iv))

	end do

	return
   74	continue
        write(6,*) 'error opening file ',trim(file)
        stop 'error stop write_nodes_scal: opening file'
	end

!***************************************************************

	subroutine write_nodes_hydro_fem(atime,znv,uprv,vprv)

! writes FEM file out.fem - version for hydro (velocities)

	use levels
	use mod_depth
	use elabutil
	use elabtime
	!use shyelab_out

	implicit none

	double precision atime
	real znv(*)
	real uprv(nlvdi,*)
	real vprv(nlvdi,*)

	integer j,iv,node,isub
	integer iformat,lmax,np,nvers,ntype
	integer ivar,nvar
	integer date,time,datetime(2)
	double precision dtime
	real regpar(7)
	real z(nnodes)
	real u(nlvdi,nnodes)
	real v(nlvdi,nnodes)
	integer il(nnodes)
	real hd(nnodes)
	character*80 file,string,stringx,stringy
	integer, save :: iunit = 0
	integer ifileo

	if( nnodes <= 0 ) return

	if( iunit == 0 ) then
          file = 'out.fem'
          iunit = ifileo(60,file,'form','unknown')
          if( iunit <= 0 ) goto 74
	end if

        do j=1,nnodes
          node = nodes(j)
	  z(j) = znv(node)
	  u(:,j) = uprv(:,node)
	  v(:,j) = vprv(:,node)
	end do

        do j=1,nnodes
          node = nodes(j)
	  il(j) = ilhkv(node)
	  hd(j) = hkv_max(node)
	end do

        nvers = 0
	iformat = 1
	ntype = 1
        np = nnodes
        lmax = nlv
	nvar = 3

	dtime = 0.
        call dts_from_abs_time(date,time,atime)
	datetime = (/date,time/)

        call fem_file_write_header(iformat,iunit,dtime
     +                          ,nvers,np,lmax
     +                          ,nvar,ntype
     +                          ,nlvdi,hlv,datetime,regpar)

	ivar = 1
	lmax = 1
	call ivar2femstring(ivar,string)

        call fem_file_write_data(iformat,iunit
     +                          ,nvers,np,lmax
     +                          ,string
     +                          ,il,hd
     +                          ,lmax,znv)

	ivar = 2
	lmax = nlv
	call ivar2femstring(ivar,string)
	stringx = trim(string) // ' x'
	stringy = trim(string) // ' y'

        call fem_file_write_data(iformat,iunit
     +                          ,nvers,np,lmax
     +                          ,stringx
     +                          ,il,hd
     +                          ,nlvdi,uprv)

        call fem_file_write_data(iformat,iunit
     +                          ,nvers,np,lmax
     +                          ,stringy
     +                          ,il,hd
     +                          ,nlvdi,vprv)

	return
   74	continue
        write(6,*) 'error opening file ',trim(file)
        stop 'error stop write_nodes_scal: opening file'
	end

!***************************************************************
!***************************************************************
!***************************************************************

        subroutine write_profile_c(iu,dline,j,ki,ke,lmax,ivar,h,z,c,hlv)

	use shyfem_strings

        implicit none

	integer iu
	character*20 dline
        integer j,ki,ke
        integer lmax
        integer ivar
        real z,h
        real c(lmax)
        real hlv(lmax)

        logical bcenter
        integer l
        integer nlvaux,nsigma
        real hsigma
        real uv
        real hd(lmax)
        real hl(lmax)

        bcenter = .true.        !depth at center of layer
        call get_sigma_info(nlvaux,nsigma,hsigma)
        call get_layer_thickness(lmax,nsigma,hsigma,z,h,hlv,hd)
        call get_depth_of_layer(bcenter,lmax,z,hd,hl)

        write(iu,'(a20,5i10)') dline,j,ke,ki,lmax,ivar
        do l=1,lmax
          write(iu,*) hl(l),c(l)
        end do

        end

!***************************************************************

        subroutine write_profile_uv(iu,dline,j,ki,ke,lmax,h,z,u,v,hlv)

        implicit none

	integer iu
	character*20 dline
        integer j,ki,ke
        integer lmax
        real z,h
        real u(lmax)
        real v(lmax)
        real hlv(lmax)

        logical bcenter
        integer l
        integer nlvaux,nsigma
        real hsigma
        real uv
        real hd(lmax)
        real hl(lmax)

        bcenter = .true.        !depth at center of layer
        call get_sigma_info(nlvaux,nsigma,hsigma)
        call get_layer_thickness(lmax,nsigma,hsigma,z,h,hlv,hd)
        call get_depth_of_layer(bcenter,lmax,z,hd,hl)

        write(iu,'(a20,4i10,f12.3)') dline,j,ke,ki,lmax,z
        do l=1,lmax
          uv = sqrt( u(l)**2 + v(l)**2 )
          write(iu,*) hl(l),u(l),v(l),uv
        end do

        end

!***************************************************************

