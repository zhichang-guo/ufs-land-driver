# ufs-land-driver

ufs-land-driver: a simple land driver for the UFS land models

This is a primary tree starting at the program 'ufsLandDriver'<br>

ufsLandDriver<br>
+-ufsLandNoahMPDriverInit-+-static%ReadStatic (read in dimension length for location and soil_levels, read in latitude,<br>
|&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp|&nbsp&nbsp&nbsp&nbsp&nbsp                    longitude,vegetation_category,soil_category,slope_category,<br>
|                         |                    deep_soil_temperature,elevation,land_mask,soil_level_thickness,<br>
|                         |                    soil_level_nodes,max_snow_albedo,emissivity,gvf_monthly,albedo_monthly,<br>
|                         |                    lai_monthly,z0_monthly,iswater,isice,isurban,land_cover_source,<br>
|                         |                    soil_class_source)<br>
|                         +-noahmp%Init (memory allocation and assignment of default values)<br>
|                         +-initial%ReadInitial (read in dimension length for location and soil_levels, read in time,date,<br>
|                         |                      latitude,longitude,snow_water_equivalent,snow_depth,canopy_water,<br>
|                         |                      skin_temperature,soil_level_thickness,soil_level_nodes,soil_temperature,<br>
|                         |                      soil_moisture,soil_liquid,iswater,isice,isurban,land_cover_source)<br>
|                         +-initial%TransferInitialNoahMP<br>
|                         +-static%TransferStaticNoahMP<br>
|                         +-noahmp%TransferNamelist<br>
|                         +-forcing%ReadForcingInit (read in dimension length of location and time, read in time,<br> 
|                                                    memory allocation for temperature,specific_humidity,surface_pressure,<br>
|                                                    wind_speed,downward_longwave,downward_shortwave,precipitation)<br>
+-ufsLandNoahMPDriverRun-+-set_soilveg<br>
|                        +-gpvs<br>
|                        +-date_from_since<br>
|                        +-noahmp%InitStates (called for the first timestep)<br>
|                        +-forcing%ReadForcing (read in time,temperature,specific_humidity,surface_pressure,<br>
|                        |                      wind_speed,downward_longwave,downward_shortwave,precipitation<br>
|                        +-interpolate_monthly-+-date_from_since<br>
|                        |                     +-calc_sec_since<br>
|                        +-calc_cosine_zenith-+-date_from_since<br>
|                        |                    +-calc_sec_since<br>
|                        +-noahmpdrv_run-+-NOAHMP_SFLX-+-ATM(re-process atmospheric forcing)<br>
|                        |                             +-PHENOLOGY(vegetation phenology considering vegeation canopy<br>
|                        |                             |           being buries by snow and evolution in time)<br>
|                        |                             +-PRECIP_HEAT<br>
|                        |                             +-ENERGY-+-THERMOPROP-+-CSNOW(Snow bulk density,volumetric capacity,<br> 
|                        |                             |        |            |       and thermal conductivity)<br>
|                        |                             |        |            +-TDFCND(Calculate thermal diffusivity and<br> 
|                        |                             |        |                     conductivity of the soil)<br>
|                        |                             |        +-RADIATION-+-ALBEDO-+-SNOW_AGE<br>
|                        |                             |        |           |        +-SNOWALB_BATS<br>
|                        |                             |        |           |        +-SNOWALB_CLASS<br>
|                        |                             |        |           |        +-GROUNDALB<br>
|                        |                             |        |           |        +-TWOSTREAM<br>
|                        |                             |        |           +-SURRAD<br>
|                        |                             |        +-VEGE_FLUX-+-SFCDIF1<br>
|                        |                             |        |           +-SFCDIF2<br>
|                        |                             |        |           +-STOMATA<br>
|                        |                             |        |           +-CANRES<br>
|                        |                             |        |           +-ESAT<br>
|                        |                             |        |           +-RAGRB<br>
|                        |                             |        +-BARE_FLUX<br>
|                        |                             |        +-TSNOSOI-+-HRT<br>
|                        |                             |        |         +-HSTEP-+-ROSR12<br>
|                        |                             |        +-PHASECHANGE-+-FRH2O<br>
|                        |                             +-WATER-+-CANWATER<br>
|                        |                             |       +-SNOWWATER-+-SNOWFALL<br>
|                        |                             |       |           +-COMBINE<br>
|                        |                             |       |           +-DIVIDE-+-COMBO<br>
|                        |                             |       |           +-COMPACT<br>
|                        |                             |       |           +-SNOWH2O<br>
|                        |                             |       +-SOILWATER-+-ZWTEQ<br>
|                        |                             |       |           +-INFIL<br>
|                        |                             |       |           +-SRT-+-WDFCND1<br>
|                        |                             |       |           |     +-WDFCND2<br>
|                        |                             |       |           +-SSTEP<br>
|                        |                             |       +-GROUNDWATER<br>
|                        |                             |       +-SHALLOWWATERTABLE<br>
|                        |                             +-CARBON-+-CO2FLUX<br>
|                        +-WriteOutputNoahMP<br>
+-ufsLandNoahMPDriverFinalize<br>
