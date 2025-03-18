module ufsLandNetcdf

use mpi
use netcdf

implicit none

  integer, parameter, private :: output = 1, restart = 2, daily_mean = 3, monthly_mean = 4,  &
                                 solar_noon = 5, diurnal = 6

contains

  subroutine Define1dReal(indata,ncid,vartype,dim_id1,dim_id2,dim_id3)
  
  use ufsLandGenericType, only : real1d
  use error_handling, only : handle_err

  type(real1d) :: indata

  integer :: ncid, varid, status, vartype, dim_id1, dim_id2
  integer, optional :: dim_id3
  
  if(present(dim_id3)) then 
    status = nf90_def_var(ncid, indata%name, vartype, (/dim_id1,dim_id3,dim_id2/), varid)
  else
    status = nf90_def_var(ncid, indata%name, vartype, (/dim_id1,dim_id2/), varid)
  end if
   if (status /= nf90_noerr) call handle_err(status,indata%name)
    status = nf90_put_att(ncid, varid, "long_name", trim(indata%long_name))
     if (status /= nf90_noerr) call handle_err(status,indata%name)
    status = nf90_put_att(ncid, varid, "units", trim(indata%units))
     if (status /= nf90_noerr) call handle_err(status,indata%name)

  end subroutine Define1dReal
  
  subroutine Define2dReal(indata,ncid,vartype,dim_id1,dim_id2,dim_id3,dim_id4)
  
  use ufsLandGenericType, only : real2d
  use error_handling, only : handle_err

  type(real2d) :: indata

  integer :: ncid, varid, status, vartype, dim_id1, dim_id2, dim_id3
  integer, optional :: dim_id4
  
  if(present(dim_id4)) stop "diurnal output not supported for 2D variables"

  status = nf90_def_var(ncid, indata%name, vartype, (/dim_id1,dim_id2,dim_id3/), varid)
   if (status /= nf90_noerr) call handle_err(status,indata%name)
    status = nf90_put_att(ncid, varid, "long_name", trim(indata%long_name))
     if (status /= nf90_noerr) call handle_err(status,indata%name)
    status = nf90_put_att(ncid, varid, "units", trim(indata%units))
     if (status /= nf90_noerr) call handle_err(status,indata%name)

  end subroutine Define2dReal
  
  subroutine Define1dInt(indata,ncid,vartype,dim_id1,dim_id2,dim_id3)
  
  use ufsLandGenericType, only : int1d
  use error_handling, only : handle_err

  type(int1d) :: indata

  integer :: ncid, varid, status, vartype, dim_id1, dim_id2
  integer, optional :: dim_id3

  if(present(dim_id3)) stop "diurnal output not supported for integer variables"

  status = nf90_def_var(ncid, indata%name, vartype, (/dim_id1,dim_id2/), varid)
   if (status /= nf90_noerr) call handle_err(status,indata%name)
    status = nf90_put_att(ncid, varid, "long_name", trim(indata%long_name))
     if (status /= nf90_noerr) call handle_err(status,indata%name)
    status = nf90_put_att(ncid, varid, "units", trim(indata%units))
     if (status /= nf90_noerr) call handle_err(status,indata%name)

  end subroutine Define1dInt
  
  subroutine Read1dReal(indata,ncid,start,count)
  
  use ufsLandGenericType, only : real1d
  use error_handling, only : handle_err

  type(real1d) :: indata

  integer :: ncid, varid, status, start(2), count(2)

  status = nf90_inq_varid(ncid, trim(indata%name), varid)
   if (status /= nf90_noerr) call handle_err(status,indata%name)

  status = nf90_get_var(ncid, varid, indata%data,start = start, count = count)
   if (status /= nf90_noerr) call handle_err(status,indata%name)

  end subroutine Read1dReal
  
  subroutine Write1dReal(io_type,indata,ncid,num_diurnal,start_in,count_in)
  
  use ufsLandGenericType, only : real1d
  use error_handling, only : handle_err

  integer :: io_type
  type(real1d) :: indata

  integer :: ncid, varid, status, start_in(2), count_in(2), num_diurnal
  integer, allocatable :: start(:), count(:)

  build_start : select case(io_type)
  
    case( output, restart, daily_mean, monthly_mean, solar_noon )

      allocate(start(2))
      allocate(count(2))
      start = start_in
      count = count_in

    case( diurnal ) 

      allocate(start(3))
      allocate(count(3))
      start(1) = start_in(1)
      count(1) = count_in(1)
      start(2) = 1
      count(2) = num_diurnal
      start(3) = start_in(2)
      count(3) = count_in(2)

  end select build_start

  status = nf90_inq_varid(ncid, trim(indata%name), varid)
   if (status /= nf90_noerr) call handle_err(status,indata%name)

! GZCM
! status = nf90_var_par_access(ncid, varid, NF90_COLLECTIVE)
   if (status /= nf90_noerr) call handle_err(status,indata%name)

  write_cases : select case(io_type)
  
    case( output, restart )  ! write %data

      status = nf90_put_var(ncid, varid, indata%data,start = start, count = count)
        if (status /= nf90_noerr) call handle_err(status,"output/restart write:"//indata%name)

    case( daily_mean )  ! write %daily_mean

      status = nf90_put_var(ncid, varid, indata%daily_mean,start = start, count = count)
        if (status /= nf90_noerr) call handle_err(status,"daily_mean write:"//indata%name)

    case( monthly_mean )  ! write %monthly_mean

      status = nf90_put_var(ncid, varid, indata%monthly_mean,start = start, count = count)
        if (status /= nf90_noerr) call handle_err(status,"monthly_mean write:"//indata%name)

    case( diurnal )  ! write %diurnal

      status = nf90_put_var(ncid, varid, indata%diurnal,start = start, count = count)
        if (status /= nf90_noerr) call handle_err(status,"diurnal write:"//indata%name)

    case( solar_noon )  ! write %solar_noon

      status = nf90_put_var(ncid, varid, indata%solar_noon,start = start, count = count)
        if (status /= nf90_noerr) call handle_err(status,"solar_noon write:"//indata%name)

  end select write_cases

  end subroutine Write1dReal
  
  subroutine Read2dReal(indata,ncid,start,count)
  
  use ufsLandGenericType, only : real2d
  use error_handling, only : handle_err

  type(real2d) :: indata

  integer :: ncid, varid, status, start(3), count(3)

  status = nf90_inq_varid(ncid, trim(indata%name), varid)
   if (status /= nf90_noerr) call handle_err(status,indata%name)

  status = nf90_get_var(ncid, varid, indata%data,start = start, count = count)
   if (status /= nf90_noerr) call handle_err(status,indata%name)

  end subroutine Read2dReal
  
  subroutine Write2dReal(io_type,indata,ncid,num_diurnal,start_in,count_in)
  
  use ufsLandGenericType, only : real2d
  use error_handling, only : handle_err

  integer :: io_type
  type(real2d) :: indata

  integer :: ncid, varid, status, start_in(3), count_in(3), num_diurnal
  integer, allocatable :: start(:), count(:)

  build_start : select case(io_type)
  
    case( output, restart, daily_mean, monthly_mean, solar_noon )

      allocate(start(3))
      allocate(count(3))
      start = start_in
      count = count_in

    case( diurnal ) 

      allocate(start(4))
      allocate(count(4))
      start(1) = start_in(1)
      count(1) = count_in(1)
      start(2) = 1
      count(2) = num_diurnal
      start(3) = start_in(2)
      count(3) = count_in(2)
      start(4) = start_in(3)
      count(4) = count_in(3)

  end select build_start


  status = nf90_inq_varid(ncid, trim(indata%name), varid)
   if (status /= nf90_noerr) call handle_err(status,indata%name)

! GZCM
! status = nf90_var_par_access(ncid, varid, NF90_COLLECTIVE)
   if (status /= nf90_noerr) call handle_err(status,indata%name)

  write_cases : select case(io_type)
  
    case( output, restart )  ! write %data

      status = nf90_put_var(ncid, varid, indata%data,start = start, count = count)
        if (status /= nf90_noerr) call handle_err(status,"output/restart write:"//indata%name)

    case( daily_mean )  ! write %daily_mean

      status = nf90_put_var(ncid, varid, indata%daily_mean,start = start, count = count)
        if (status /= nf90_noerr) call handle_err(status,"daily_mean write:"//indata%name)

    case( monthly_mean )  ! write %monthly_mean

      status = nf90_put_var(ncid, varid, indata%monthly_mean,start = start, count = count)
        if (status /= nf90_noerr) call handle_err(status,"monthly_mean write:"//indata%name)

    case( solar_noon )  ! write %solar_noon

      status = nf90_put_var(ncid, varid, indata%solar_noon,start = start, count = count)
        if (status /= nf90_noerr) call handle_err(status,"solar_noon write:"//indata%name)

  end select write_cases

  end subroutine Write2dReal
  
  subroutine Read1dInt(indata,ncid,start,count)
  
  use ufsLandGenericType, only : int1d
  use error_handling, only : handle_err

  type(int1d) :: indata

  integer :: ncid, varid, status, start(2), count(2)

  status = nf90_inq_varid(ncid, trim(indata%name), varid)
   if (status /= nf90_noerr) call handle_err(status,indata%name)

  status = nf90_get_var(ncid, varid, indata%data,start = start, count = count)
   if (status /= nf90_noerr) call handle_err(status,indata%name)

  end subroutine Read1dInt
  
  subroutine Write1dInt(io_type,indata,ncid,num_diurnal,start_in,count_in)
  
  use ufsLandGenericType, only : int1d
  use error_handling, only : handle_err

  integer :: io_type
  type(int1d) :: indata

  integer :: ncid, varid, status, start_in(2), count_in(2), num_diurnal
  integer, allocatable :: start(:), count(:)

  build_start : select case(io_type)
  
    case( output, restart, daily_mean, monthly_mean, solar_noon )

      allocate(start(2))
      allocate(count(2))
      start = start_in
      count = count_in

    case( diurnal ) 

      allocate(start(3))
      allocate(count(3))
      start(1) = start_in(1)
      count(1) = count_in(1)
      start(2) = 1
      count(2) = num_diurnal
      start(3) = start_in(2)
      count(3) = count_in(2)

  end select build_start

  status = nf90_inq_varid(ncid, trim(indata%name), varid)
   if (status /= nf90_noerr) call handle_err(status,indata%name)

! GZCM
! status = nf90_var_par_access(ncid, varid, NF90_COLLECTIVE)
   if (status /= nf90_noerr) call handle_err(status,indata%name)

  write_cases : select case(io_type)
  
    case( output, restart )  ! write %data

      status = nf90_put_var(ncid, varid, indata%data,start = start, count = count)
        if (status /= nf90_noerr) call handle_err(status,"output/restart write:"//indata%name)

    case( daily_mean )  ! write %daily_mean

      status = nf90_put_var(ncid, varid, indata%daily_mean,start = start, count = count)
        if (status /= nf90_noerr) call handle_err(status,"daily_mean write:"//indata%name)

    case( monthly_mean )  ! write %monthly_mean

      status = nf90_put_var(ncid, varid, indata%monthly_mean,start = start, count = count)
        if (status /= nf90_noerr) call handle_err(status,"monthly_mean write:"//indata%name)

    case( solar_noon )  ! write %solar_noon

      status = nf90_put_var(ncid, varid, indata%solar_noon,start = start, count = count)
        if (status /= nf90_noerr) call handle_err(status,"solar_noon write:"//indata%name)

  end select write_cases

  end subroutine Write1dInt
  
end module ufsLandNetcdf
