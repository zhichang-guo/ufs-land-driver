module ufsLandForcingModule

use NamelistRead

implicit none
save
private

type, public :: forcing_type

  integer                          :: forcing_counter
  integer                          :: nlocations
  double precision                 :: time
  real, allocatable, dimension(:)  :: temperature
  real, allocatable, dimension(:)  :: specific_humidity
  real, allocatable, dimension(:)  :: surface_pressure
  real, allocatable, dimension(:)  :: wind_speed
  real, allocatable, dimension(:)  :: downward_longwave
  real, allocatable, dimension(:)  :: downward_shortwave
  real, allocatable, dimension(:)  :: precipitation
  real                             :: forcing_height

  contains

    procedure, public  :: ReadForcingInit
    procedure, public  :: ReadForcing

end type forcing_type

  double precision                 :: last_time
  character*19                     :: last_date  ! format: yyyy-mm-dd hh:nn:ss
  logical                          :: last_forcing_read
  real, allocatable, dimension(:)  :: last_temperature
  real, allocatable, dimension(:)  :: last_specific_humidity
  real, allocatable, dimension(:)  :: last_surface_pressure
  real, allocatable, dimension(:)  :: last_wind_speed
  real, allocatable, dimension(:)  :: last_downward_longwave
  real, allocatable, dimension(:)  :: last_downward_shortwave
  real, allocatable, dimension(:)  :: last_precipitation
     
  double precision                 :: next_time
  character*19                     :: next_date  ! format: yyyy-mm-dd hh:nn:ss
  logical                          :: next_forcing_read
  real, allocatable, dimension(:)  :: next_temperature
  real, allocatable, dimension(:)  :: next_specific_humidity
  real, allocatable, dimension(:)  :: next_surface_pressure
  real, allocatable, dimension(:)  :: next_wind_speed
  real, allocatable, dimension(:)  :: next_downward_longwave
  real, allocatable, dimension(:)  :: next_downward_shortwave
  real, allocatable, dimension(:)  :: next_precipitation
     
contains   

  subroutine ReadForcingInit(this, namelist)
  
  use netcdf
  use error_handling, only : handle_err
  
  class(forcing_type)  :: this
  type(namelist_type)  :: namelist
  
  character*128        :: forcing_filename
  
  double precision     :: read_time
  
  integer :: ncid, dimid, varid, status, ntimes, itime
  
  this%forcing_counter = 0
  
  forcing_type : select case (trim(namelist%forcing_type))
    case ("single_point")
      forcing_filename = trim(namelist%forcing_dir)//"/"//trim(namelist%forcing_filename)
    case ("gswp3")
      forcing_filename = trim(namelist%forcing_dir)//"/"//trim(namelist%forcing_filename)
      forcing_filename = trim(forcing_filename)//namelist%simulation_start(1:7)//".nc"
    case default
      stop "namelist forcing_type not recognized"
  end select forcing_type
  
  write(*,*) "Starting first read: "//trim(forcing_filename)
  
  status = nf90_open(forcing_filename, NF90_NOWRITE, ncid)
   if (status /= nf90_noerr) call handle_err(status)
  
  status = nf90_inq_dimid(ncid, "location", dimid)
   if (status /= nf90_noerr) call handle_err(status)

  status = nf90_inquire_dimension(ncid, dimid, len = this%nlocations)
   if (status /= nf90_noerr) call handle_err(status)
   
  allocate(this%temperature       (this%nlocations))
  allocate(this%specific_humidity (this%nlocations))
  allocate(this%surface_pressure  (this%nlocations))
  allocate(this%wind_speed        (this%nlocations))
  allocate(this%downward_longwave (this%nlocations))
  allocate(this%downward_shortwave(this%nlocations))
  allocate(this%precipitation     (this%nlocations))

  allocate(last_temperature       (this%nlocations))
  allocate(last_specific_humidity (this%nlocations))
  allocate(last_surface_pressure  (this%nlocations))
  allocate(last_wind_speed        (this%nlocations))
  allocate(last_downward_longwave (this%nlocations))
  allocate(last_downward_shortwave(this%nlocations))
  allocate(last_precipitation     (this%nlocations))

  allocate(next_temperature       (this%nlocations))
  allocate(next_specific_humidity (this%nlocations))
  allocate(next_surface_pressure  (this%nlocations))
  allocate(next_wind_speed        (this%nlocations))
  allocate(next_downward_longwave (this%nlocations))
  allocate(next_downward_shortwave(this%nlocations))
  allocate(next_precipitation     (this%nlocations))

  status = nf90_inq_dimid(ncid, "time", dimid)
   if (status /= nf90_noerr) call handle_err(status)

  status = nf90_inquire_dimension(ncid, dimid, len = ntimes)
   if (status /= nf90_noerr) call handle_err(status)
   
  status = nf90_inq_varid(ncid, "time", varid)
   if(status /= nf90_noerr) call handle_err(status)

  timeloop : do itime = 1, ntimes
  
    status = nf90_get_var(ncid, varid, read_time, start = (/itime/))
     if(status /= nf90_noerr) call handle_err(status)
     
    if (read_time == namelist%initial_time + namelist%timestep_seconds) then
       this%forcing_counter = itime
       next_time = read_time
       last_time = huge(1.d0)
       next_forcing_read = .false.
       last_forcing_read = .false.
       exit timeloop
    end if
    
  end do timeloop
  
  status = nf90_close(ncid)
   if (status /= nf90_noerr) call handle_err(status)

  if(this%forcing_counter == 0) stop "did not find initial forcing time in file"
   
  end subroutine ReadForcingInit

  subroutine ReadForcing(this, namelist, now_time)
  
  use netcdf
  use error_handling, only : handle_err
  use time_utilities
  use interpolation_utilities, only : interpolate_linear
  
  class(forcing_type)  :: this
  type(namelist_type)  :: namelist
  double precision     :: now_time
  
  character*128        :: forcing_filename
  character*19         :: now_date  ! format: yyyy-mm-dd hh:nn:ss
  
  integer :: ncid, dimid, varid, status
  integer :: times_in_file
  double precision  :: file_next_time
  
  call date_from_since("1970-01-01 00:00:00", now_time, now_date)
  call date_from_since("1970-01-01 00:00:00", next_time, next_date)
  
  write(*,*) "Searching for forcing at time: ",now_date
  
  if(.not. next_forcing_read) then
  
    forcing_type1 : select case (trim(namelist%forcing_type))
      case ("single_point")
        forcing_filename = trim(namelist%forcing_dir)//"/"//trim(namelist%forcing_filename)
      case ("gswp3")
        forcing_filename = trim(namelist%forcing_dir)//"/"//trim(namelist%forcing_filename)
        forcing_filename = trim(forcing_filename)//next_date(1:7)//".nc"
        if(next_date(9:19) == "01 00:00:00") then
          this%forcing_counter = 1
          write(*,*) "Resetting forcing counter to beginning of file"
        end if
      case default
        stop "namelist forcing_type not recognized"
    end select forcing_type1
  
    status = nf90_open(forcing_filename, NF90_NOWRITE, ncid)
     if (status /= nf90_noerr) call handle_err(status)
  
    status = nf90_inq_varid(ncid, "time", varid)
     if(status /= nf90_noerr) call handle_err(status)
    status = nf90_get_var(ncid, varid, file_next_time, start = (/this%forcing_counter/))
     if(status /= nf90_noerr) call handle_err(status)
     
    if(file_next_time /= next_time) then
      write(*,*) "file_next_time not equal to next_time in now_time == next_time forcing"
      stop
    end if
   
    status = nf90_inq_varid(ncid, trim(namelist%forcing_name_temperature), varid)
     if(status /= nf90_noerr) call handle_err(status)
    status = nf90_get_var(ncid, varid, next_temperature, start = (/1,this%forcing_counter/), count = (/this%nlocations, 1/))
     if(status /= nf90_noerr) call handle_err(status)
  
    status = nf90_inq_varid(ncid, trim(namelist%forcing_name_specific_humidity), varid)
     if(status /= nf90_noerr) call handle_err(status)
    status = nf90_get_var(ncid, varid, next_specific_humidity, start = (/1,this%forcing_counter/), count = (/this%nlocations, 1/))
     if(status /= nf90_noerr) call handle_err(status)
  
    status = nf90_inq_varid(ncid, trim(namelist%forcing_name_pressure), varid)
     if(status /= nf90_noerr) call handle_err(status)
    status = nf90_get_var(ncid, varid, next_surface_pressure, start = (/1,this%forcing_counter/), count = (/this%nlocations, 1/))
     if(status /= nf90_noerr) call handle_err(status)
  
    status = nf90_inq_varid(ncid, trim(namelist%forcing_name_wind_speed), varid)
     if(status /= nf90_noerr) call handle_err(status)
    status = nf90_get_var(ncid, varid, next_wind_speed, start = (/1,this%forcing_counter/), count = (/this%nlocations, 1/))
     if(status /= nf90_noerr) call handle_err(status)
  
    status = nf90_inq_varid(ncid, trim(namelist%forcing_name_lw_radiation), varid)
     if(status /= nf90_noerr) call handle_err(status)
    status = nf90_get_var(ncid, varid, next_downward_longwave, start = (/1,this%forcing_counter/), count = (/this%nlocations, 1/))
     if(status /= nf90_noerr) call handle_err(status)

    status = nf90_inq_varid(ncid, trim(namelist%forcing_name_sw_radiation), varid)
     if(status /= nf90_noerr) call handle_err(status)
    status = nf90_get_var(ncid, varid, next_downward_shortwave, start = (/1,this%forcing_counter/), count = (/this%nlocations, 1/))
     if(status /= nf90_noerr) call handle_err(status)
  
    status = nf90_inq_varid(ncid, trim(namelist%forcing_name_precipitation), varid)
     if(status /= nf90_noerr) call handle_err(status)
    status = nf90_get_var(ncid, varid, next_precipitation, start = (/1,this%forcing_counter/), count = (/this%nlocations, 1/))
     if(status /= nf90_noerr) call handle_err(status)

    status = nf90_close(ncid)

    next_forcing_read = .true.
    
  end if ! not read_next_forcing
  
  if(now_time == next_time) then

    this%temperature        = next_temperature
    this%specific_humidity  = next_specific_humidity
    this%surface_pressure   = next_surface_pressure
    this%wind_speed         = next_wind_speed
    this%downward_longwave  = next_downward_longwave
    this%downward_shortwave = next_downward_shortwave
    this%precipitation      = next_precipitation
    
    last_time               = next_time
    last_temperature        = next_temperature
    last_specific_humidity  = next_specific_humidity
    last_surface_pressure   = next_surface_pressure
    last_wind_speed         = next_wind_speed
    last_downward_longwave  = next_downward_longwave
    last_downward_shortwave = next_downward_shortwave
    last_precipitation      = next_precipitation
    
    next_time = last_time + namelist%forcing_timestep_seconds
    last_forcing_read = .true.
    next_forcing_read = .false.
  
    this%forcing_counter = this%forcing_counter + 1   ! increment forcing counter by 1

  elseif(now_time < next_time) then
  
    call interpolate_linear(now_time, last_time, next_time, this%nlocations, &
                            last_temperature, next_temperature, this%temperature)
  
    call interpolate_linear(now_time, last_time, next_time, this%nlocations, &
                            last_specific_humidity, next_specific_humidity, this%specific_humidity)

    call interpolate_linear(now_time, last_time, next_time, this%nlocations, &
                            last_surface_pressure, next_surface_pressure, this%surface_pressure)

    call interpolate_linear(now_time, last_time, next_time, this%nlocations, &
                            last_wind_speed, next_wind_speed, this%wind_speed)

    call interpolate_linear(now_time, last_time, next_time, this%nlocations, &
                            last_downward_longwave, next_downward_longwave, this%downward_longwave)

    call interpolate_linear(now_time, last_time, next_time, this%nlocations, &
                            last_downward_shortwave, next_downward_shortwave, this%downward_shortwave)

    this%precipitation = next_precipitation
  
    next_forcing_read = .true.

  else

   write(*,*) "Read of forcing time is not consistent with model time"
   stop

  end if

  this%wind_speed     = max(this%wind_speed, 0.1)
  this%precipitation  = this%precipitation * namelist%timestep_seconds / 1000.0 ! convert mm/s to m
  
  end subroutine ReadForcing

end module ufsLandForcingModule
