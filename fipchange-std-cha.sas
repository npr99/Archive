/* Program from Yu Xiao
	Texas A&M University
	Department of Landscape Architecture and Urban Planning
*/
*libname dt 'H:\Research\Data\GeoSpat';


%macro fipcleaner (dir, datset, fips);
data datset; set  &dir..&datset;
* Exclude duplicate observations;
proc sort data=datset; by decending &fips;
proc sort data=datset out=datset noduplicates; by &fips;
data datset; set datset;

* Ignore Yellowstone National Park by eliminating it;
	if &fips in ("30113", "56047", "16089") then delete;

*The FIPS code for Ste. Genevieve County, Missouri, changed from 29193 to 29186;  
if &fips= '29193' then &fips='29186';

/** Drop Broomfield County, Colorado (FIPS code 08014), formed on 11-15-2001;*/
/*if &fips='08014' then delete;*/
/**La Paz county, Arizona (FIPS code 04012) was formed from the northern portion of Yuma county (FIPS code 04027) in January, 1983.;*/
/*if &fips=04012 then delete;*/
/** Cibola county, New Mexico (FIPS code 35006) was formed when Valencia county, New Mexico (FIPS code 35061) was divided into two parts in 1981. ;*/
/*if &fips=35006 then delete;*/
* Ormsby, NV (32025) replaced by Carson City, NV (32510)  effective 1970;
 if &fips='32025' then &fips='32510'; 
* Drop BEA combination of Shewano and Menominee Counties, WI (REIS through 1988);
 if &fips='55901' then delete;
* Dade county, Florida (FIPS code 12025) was renamed  Miami-Dade County (FIPS code 12086) effective November 13, 1997;
 if &fips='12025' then &fips='12086';
* Asignment of Columbus City, GA (13510) to Muscogee County (13215) 
  Columbus is not an independent city as the number suggests. It is a consolidated city-county with Muscogee County, incorporating everything outside of Fort Benning.; 
 if &fips='13510' then &fips='13215'  ;
* Armstrong County, SD (46001) annexed to Dewey County, SD (46041) in 1979;
 if &fips='46001' then &fips='46041'  ;
* Washabaugh County, SD (46131) annexed to Jackson County (46071) in 1979;
 if &fips='46131' then &fips='46071'  ;

 *VIRGINIA;
 *Assign Charlottesville City to Combined Charlottesville City + Albemarle County, VA;
  if &fips='51540' then &fips='51901'  ;
  if &fips='51003' then &fips='51901'  ;
 *Assign Clifton Forge City & Covington City to Alleghany County, VA;
  if &fips='51560' or &fips='51580' then &fips='51903'  ;
  if &fips='51005' then &fips='51903'  ;
 *Assign Staunton City & Waynesboro City to Augusta County, VA;
  if &fips='51790' or &fips='51820' then &fips='51907'  ;
  if &fips='51015' then &fips='51907'  ;
 *Assign Bedford City to Bedford County, VA;
  if &fips='51515' then &fips='51909'  ;
  if &fips='51019' then &fips='51909'  ;
 *Assign Lynchburg City to Campbell County, VA;
  if &fips='51680' then &fips='51911'  ;
  if &fips='51031' then &fips='51911'  ;
 *Assign Galax City to Carroll County, VA;
  if &fips='51640' then &fips='51913'  ;
  if &fips='51035' then &fips='51913'  ;
 *Assign Colonial Heights & Petersburg City to Dinwiddie County, VA;
  if &fips='51570' or &fips='51730' then &fips='51918'  ;
  if &fips='51053' then &fips='51918'  ;
 *Assign Fairfax City, Falls Church City to Fairfax County, VA;
  if &fips='51600' or &fips='51610' then &fips='51919'  ;
  if &fips='51059' then &fips='51919'  ;
 *Assign Winchester City to Frederick County, VA;
	if &fips='51840' then &fips='51921'  ;
  if &fips='51069' then &fips='51921'  ;
 *Assign Emporia City to Greensville County, VA;
  if &fips='51595' then &fips='51923'  ;
  if &fips='51081' then &fips='51923'  ;
 *Assign Martinsville City to Henry County, VA;
  if &fips='51690' then &fips='51929'  ;
  if &fips='51089' then &fips='51929'  ;
 *Assign Williamsburg City to James City County, VA;
  if &fips='51830' then &fips='51931'  ;
  if &fips='51095' then &fips='51931'  ; 
 *Assign Radford City to Montgomery County, VA;
  if &fips='51750' then &fips='51933'  ;
  if &fips='51121' then &fips='51933'  ;
 *Assign Danville City to Pittsylvania County, VA;
  if &fips='51590' then &fips='51939'  ;
  if &fips='51149' then &fips='51939'  ;
 *Assign Hopewell City to Prince George County, VA;
  if &fips='51670' then &fips='51941'  ;
  if &fips='51153' then &fips='51941'  ; 
 *Assign Manassas City & Manassas Park City to Prince William County, VA;
  if &fips='51683' or &fips='51685' then &fips='51942'  ;
  if &fips='51153' then &fips='51942'  ;
 *Assign Salem City to Roanoke County, VA;
  if &fips='51775' then &fips='51944'  ;
  if &fips='51161' then &fips='51944'  ;
 *Assign Lexington City & Buena Vista City to Roanoke County, VA;
  if &fips='51678' or &fips='51530' then &fips='51945'  ;
  if &fips='51163' then &fips='51945'  ;
 *Assign Harrisonburg City to Rockingham County, VA;
  if &fips='51660' then &fips='51947'  ;
  if &fips='51165' then &fips='51947'  ;
 *Assign Franklin City to Southhampton County, VA;
  if &fips='51620' then &fips='51949'  ;
  if &fips='51175' then &fips='51949'  ;
 *Assign Fredericksburg City to Spottsylvania County, VA;
  if &fips='51630' then &fips='51951'  ;
  if &fips='51177' then &fips='51951'  ;
 *Assign Bristol City to Washington County, VA;
  if &fips='51520' then &fips='51953'  ;
  if &fips='51191' then &fips='51953'  ;
 *Assign Norton City to Wise County, VA;
  if &fips='51720' then &fips='51955'  ;
  if &fips='51195' then &fips='51955'  ;
 *Assign Poquoson City to York County, VA;
  if &fips='51735' then &fips='51958'  ;
  if &fips='51199' then &fips='51958'  ; 
  run;
  proc sort data=datset; by &fips; run;

  data &dir..&datset._s; set datset; run;

%mend fipcleaner;


%fipcleaner(dt,geodispp,fips);

